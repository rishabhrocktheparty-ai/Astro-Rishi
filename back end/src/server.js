/**
 * JYOTISH AI — Main Server Entry Point
 */
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { logger } = require('./utils/logger');

const app = express();
const PORT = process.env.PORT || 3000;

// ── Middleware ────────────────────────────────────────────
app.use(helmet());
app.use(cors({ origin: '*', methods: ['GET','POST','PUT','DELETE'] }));
app.use(express.json({ limit: '10mb' }));
app.use(morgan('combined', { stream: { write: msg => logger.info(msg.trim()) } }));

app.use('/api/', rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 900000,
  max: parseInt(process.env.RATE_LIMIT_MAX) || 100,
  message: { error: 'Too many requests, please try again later.' }
}));

// ── Routes ───────────────────────────────────────────────
app.use('/api/auth',      require('./routes/auth'));
app.use('/api/kundali',   require('./routes/kundali'));
app.use('/api/ai',        require('./routes/ai'));
app.use('/api/books',     require('./routes/books'));
app.use('/api/knowledge', require('./routes/knowledge'));
app.use('/api/admin',     require('./routes/admin'));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'jyotish-ai', version: '1.0.0', timestamp: new Date().toISOString() });
});

// ── Error Handler ────────────────────────────────────────
app.use((err, req, res, next) => {
  logger.error(`Unhandled: ${err.message}`, { stack: err.stack });
  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'production' ? 'Internal server error' : err.message
  });
});

// ── Start ────────────────────────────────────────────────
app.listen(PORT, () => {
  logger.info(`Jyotish AI server running on port ${PORT}`);
  logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
