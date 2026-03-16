const express = require('express');
const router = express.Router();
const { supabaseAdmin } = require('../utils/supabase');
const { authenticate, requireAdmin } = require('../middleware/auth');
const { logger } = require('../utils/logger');

router.use(authenticate, requireAdmin);

// Dashboard analytics
router.get('/dashboard', async (req, res) => {
  try {
    const { count: users } = await supabaseAdmin.from('users').select('id', { count: 'exact', head: true });
    const { count: kundalis } = await supabaseAdmin.from('kundalis').select('id', { count: 'exact', head: true });
    const { count: books } = await supabaseAdmin.from('books').select('id', { count: 'exact', head: true });
    const { count: booksCompleted } = await supabaseAdmin.from('books').select('id', { count: 'exact', head: true }).eq('processing_status', 'completed');
    const { count: conversations } = await supabaseAdmin.from('ai_conversations').select('id', { count: 'exact', head: true });
    const { count: chunks } = await supabaseAdmin.from('book_chunks').select('id', { count: 'exact', head: true });
    const { count: kgNodes } = await supabaseAdmin.from('kg_nodes').select('id', { count: 'exact', head: true });
    const { count: kgEdges } = await supabaseAdmin.from('kg_edges').select('id', { count: 'exact', head: true });

    // Recent metrics
    const { data: recentMetrics } = await supabaseAdmin.from('learning_metrics')
      .select('*').order('created_at', { ascending: false }).limit(20);

    // Books by status
    const { data: booksByStatus } = await supabaseAdmin
      .from('books').select('processing_status');

    const statusCounts = {};
    (booksByStatus || []).forEach(b => { statusCounts[b.processing_status] = (statusCounts[b.processing_status] || 0) + 1; });

    // Average feedback
    const { data: feedback } = await supabaseAdmin.from('user_feedback').select('rating');
    const avgRating = feedback && feedback.length > 0
      ? feedback.reduce((s, f) => s + (f.rating || 0), 0) / feedback.length : 0;

    res.json({
      overview: { users, kundalis, books, books_completed: booksCompleted, conversations, chunks, kg_nodes: kgNodes, kg_edges: kgEdges },
      books_by_status: statusCounts,
      average_feedback_rating: avgRating.toFixed(2),
      recent_metrics: recentMetrics
    });
  } catch (error) {
    logger.error('Admin dashboard error:', error);
    res.status(500).json({ error: 'Failed to load dashboard' });
  }
});

// List all users
router.get('/users', async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin.from('users').select('id, email, display_name, is_admin, created_at').order('created_at', { ascending: false });
    if (error) return res.status(500).json({ error: error.message });
    res.json({ users: data });
  } catch (error) {
    res.status(500).json({ error: 'Failed to list users' });
  }
});

// Toggle admin
router.put('/users/:id/admin', async (req, res) => {
  try {
    const { is_admin } = req.body;
    const { data, error } = await supabaseAdmin.from('users').update({ is_admin }).eq('id', req.params.id).select().single();
    if (error) return res.status(400).json({ error: error.message });
    res.json({ user: data });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update user' });
  }
});

// Learning progress
router.get('/learning', async (req, res) => {
  try {
    const { data: traditions } = await supabaseAdmin.from('traditions').select('name, slug');
    const traditionStats = [];
    for (const t of (traditions || [])) {
      const { count: bookCount } = await supabaseAdmin.from('books')
        .select('id', { count: 'exact', head: true })
        .eq('tradition_id', t.id);
      const { count: chunkCount } = await supabaseAdmin.from('book_chunks')
        .select('id', { count: 'exact', head: true })
        .eq('book_id', t.id);
      traditionStats.push({ ...t, books: bookCount || 0, chunks: chunkCount || 0 });
    }
    res.json({ traditions: traditionStats });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch learning data' });
  }
});

module.exports = router;
