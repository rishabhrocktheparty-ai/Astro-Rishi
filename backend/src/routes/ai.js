const express = require('express');
const router = express.Router();
const { supabaseAdmin } = require('../utils/supabase');
const { authenticate } = require('../middleware/auth');
const { interpretQuery, generateFullReading } = require('../services/ai-engine');
const { logger } = require('../utils/logger');

router.post('/conversation', authenticate, async (req, res) => {
  try {
    const { kundali_id, title, tradition } = req.body;
    const { data: profile } = await supabaseAdmin.from('users').select('id').eq('auth_id', req.user.id).single();
    const { data: conv, error } = await supabaseAdmin.from('ai_conversations').insert({
      user_id: profile.id, kundali_id: kundali_id || null,
      title: title || 'New Consultation', tradition_filter: tradition || null
    }).select().single();
    if (error) return res.status(400).json({ error: error.message });
    res.status(201).json({ conversation: conv });
  } catch (err) { logger.error('Conv error:', err); res.status(500).json({ error: 'Failed to create conversation' }); }
});

router.post('/message', authenticate, async (req, res) => {
  try {
    const { conversation_id, message, tradition } = req.body;
    if (!conversation_id || !message) return res.status(400).json({ error: 'conversation_id and message required' });

    const { data: profile } = await supabaseAdmin.from('users').select('id, preferred_tradition').eq('auth_id', req.user.id).single();
    const { data: conv } = await supabaseAdmin.from('ai_conversations')
      .select('*, kundalis(chart_data)').eq('id', conversation_id).eq('user_id', profile.id).single();
    if (!conv) return res.status(404).json({ error: 'Conversation not found' });

    await supabaseAdmin.from('ai_messages').insert({ conversation_id, role: 'user', content: message });

    const { data: history } = await supabaseAdmin.from('ai_messages').select('role, content')
      .eq('conversation_id', conversation_id).order('created_at', { ascending: true }).limit(20);

    const kundaliData = conv.kundalis?.chart_data || null;
    const useTradition = tradition || conv.tradition_filter || profile.preferred_tradition;

    const result = await interpretQuery({
      query: message, kundaliData, tradition: useTradition,
      conversationHistory: history || [], userId: profile.id
    });

    const { data: aiMsg } = await supabaseAdmin.from('ai_messages').insert({
      conversation_id, role: 'assistant', content: result.response,
      sources: result.sources, tradition_used: result.tradition_used,
      reasoning_chain: result.reasoning_chain, tokens_used: result.tokens_used, model_used: result.model_used
    }).select().single();

    res.json({ message: result.response, sources: result.sources,
      tradition_used: result.tradition_used, message_id: aiMsg?.id, reasoning: result.reasoning_chain });
  } catch (err) { logger.error('AI msg error:', err); res.status(500).json({ error: 'AI interpretation failed' }); }
});

router.get('/conversation/:id', authenticate, async (req, res) => {
  try {
    const { data: profile } = await supabaseAdmin.from('users').select('id').eq('auth_id', req.user.id).single();
    const { data: conv } = await supabaseAdmin.from('ai_conversations').select('*')
      .eq('id', req.params.id).eq('user_id', profile.id).single();
    if (!conv) return res.status(404).json({ error: 'Conversation not found' });
    const { data: messages } = await supabaseAdmin.from('ai_messages').select('*')
      .eq('conversation_id', req.params.id).order('created_at', { ascending: true });
    res.json({ conversation: conv, messages });
  } catch (err) { res.status(500).json({ error: 'Failed to fetch conversation' }); }
});

router.get('/conversations', authenticate, async (req, res) => {
  try {
    const { data: profile } = await supabaseAdmin.from('users').select('id').eq('auth_id', req.user.id).single();
    const { data } = await supabaseAdmin.from('ai_conversations').select('id, title, tradition_filter, created_at, updated_at')
      .eq('user_id', profile.id).order('updated_at', { ascending: false }).limit(50);
    res.json({ conversations: data });
  } catch (err) { res.status(500).json({ error: 'Failed to list conversations' }); }
});

router.post('/full-reading', authenticate, async (req, res) => {
  try {
    const { kundali_id, tradition } = req.body;
    if (!kundali_id) return res.status(400).json({ error: 'kundali_id required' });
    const { data: profile } = await supabaseAdmin.from('users').select('id').eq('auth_id', req.user.id).single();
    const { data: kundali } = await supabaseAdmin.from('kundalis').select('chart_data')
      .eq('id', kundali_id).eq('user_id', profile.id).single();
    if (!kundali) return res.status(404).json({ error: 'Kundali not found' });
    const readings = await generateFullReading(kundali.chart_data, tradition);
    res.json({ readings });
  } catch (err) { logger.error('Full reading error:', err); res.status(500).json({ error: 'Failed' }); }
});

router.post('/feedback', authenticate, async (req, res) => {
  try {
    const { message_id, rating, feedback_text } = req.body;
    const { data: profile } = await supabaseAdmin.from('users').select('id').eq('auth_id', req.user.id).single();
    await supabaseAdmin.from('user_feedback').insert({ user_id: profile.id, message_id, rating, feedback_text });
    res.json({ message: 'Feedback recorded' });
  } catch (err) { res.status(500).json({ error: 'Failed' }); }
});

module.exports = router;
