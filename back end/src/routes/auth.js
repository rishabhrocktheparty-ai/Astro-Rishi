const express = require('express');
const router = express.Router();
const { supabase, supabaseAdmin } = require('../utils/supabase');
const { authenticate } = require('../middleware/auth');
const { logger } = require('../utils/logger');

router.post('/signup', async (req, res) => {
  try {
    const { email, password, display_name } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Email and password required' });

    const { data: authData, error: authError } = await supabase.auth.signUp({
      email, password, options: { data: { display_name } }
    });
    if (authError) return res.status(400).json({ error: authError.message });

    const { data: profile } = await supabaseAdmin.from('users').insert({
      auth_id: authData.user.id, email, display_name: display_name || email.split('@')[0]
    }).select().single();

    res.status(201).json({ user: authData.user, profile, session: authData.session });
  } catch (err) { logger.error('Signup error:', err); res.status(500).json({ error: 'Signup failed' }); }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) return res.status(401).json({ error: error.message });
    const { data: profile } = await supabaseAdmin.from('users').select('*').eq('auth_id', data.user.id).single();
    res.json({ user: data.user, profile, session: data.session });
  } catch (err) { logger.error('Login error:', err); res.status(500).json({ error: 'Login failed' }); }
});

router.get('/profile', authenticate, async (req, res) => {
  try {
    const { data: profile } = await supabaseAdmin.from('users').select('*').eq('auth_id', req.user.id).single();
    res.json({ profile });
  } catch (err) { res.status(500).json({ error: 'Failed to fetch profile' }); }
});

router.put('/profile', authenticate, async (req, res) => {
  try {
    const { display_name, preferred_language, preferred_tradition, timezone } = req.body;
    const { data: profile, error } = await supabaseAdmin.from('users')
      .update({ display_name, preferred_language, preferred_tradition, timezone })
      .eq('auth_id', req.user.id).select().single();
    if (error) return res.status(400).json({ error: error.message });
    res.json({ profile });
  } catch (err) { res.status(500).json({ error: 'Profile update failed' }); }
});

router.post('/logout', authenticate, async (req, res) => {
  await supabase.auth.signOut();
  res.json({ message: 'Signed out' });
});

module.exports = router;
