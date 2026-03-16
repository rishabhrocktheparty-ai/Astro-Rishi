const { supabase, supabaseAdmin } = require('../utils/supabase');
const { logger } = require('../utils/logger');

/**
 * Authenticate requests using Supabase JWT
 */
async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing or invalid authorization header' });
    }
    const token = authHeader.split(' ')[1];
    const { data: { user }, error } = await supabase.auth.getUser(token);
    if (error || !user) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    req.token = token;
    next();
  } catch (err) {
    logger.error('Auth middleware error:', err);
    res.status(500).json({ error: 'Authentication failed' });
  }
}

/**
 * Check admin privileges
 */
async function requireAdmin(req, res, next) {
  try {
    const { data: profile } = await supabaseAdmin
      .from('users')
      .select('is_admin')
      .eq('auth_id', req.user.id)
      .single();
    if (!profile || !profile.is_admin) {
      return res.status(403).json({ error: 'Admin access required' });
    }
    next();
  } catch (err) {
    logger.error('Admin check error:', err);
    res.status(500).json({ error: 'Authorization check failed' });
  }
}

module.exports = { authenticate, requireAdmin };
