const express = require('express');
const router = express.Router();
const multer = require('multer');
const { supabaseAdmin } = require('../utils/supabase');
const { authenticate, requireAdmin } = require('../middleware/auth');
const { processBook } = require('../services/knowledge-pipeline');
const { logger } = require('../utils/logger');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: (parseInt(process.env.MAX_FILE_SIZE_MB) || 100) * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    cb(null, file.originalname.match(/\.(pdf|epub|txt|zip)$/i) !== null);
  }
});

router.post('/upload', authenticate, requireAdmin, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
    const { title, original_title, author, tradition_slug } = req.body;
    if (!title) return res.status(400).json({ error: 'Title required' });

    const { data: profile } = await supabaseAdmin.from('users').select('id').eq('auth_id', req.user.id).single();
    const ext = req.file.originalname.split('.').pop().toLowerCase();
    const fileType = ext === 'epub' ? 'epub' : ext === 'txt' ? 'txt' : ext === 'zip' ? 'images' : 'pdf';
    const filePath = `books/${Date.now()}_${req.file.originalname}`;

    const { error: sErr } = await supabaseAdmin.storage.from('books').upload(filePath, req.file.buffer, { contentType: req.file.mimetype });
    if (sErr) return res.status(500).json({ error: `Upload failed: ${sErr.message}` });

    let traditionId = null;
    if (tradition_slug) {
      const { data: trad } = await supabaseAdmin.from('traditions').select('id').eq('slug', tradition_slug).single();
      if (trad) traditionId = trad.id;
    }

    const { data: book, error: bErr } = await supabaseAdmin.from('books').insert({
      title, original_title, author, tradition_id: traditionId,
      file_url: filePath, file_type: fileType, file_size_bytes: req.file.size,
      uploaded_by: profile.id, processing_status: 'pending'
    }).select().single();
    if (bErr) return res.status(500).json({ error: bErr.message });

    processBook(book.id).catch(e => logger.error('Async processing failed:', e));
    res.status(201).json({ book, message: 'Upload successful. Processing started.' });
  } catch (err) { logger.error('Upload error:', err); res.status(500).json({ error: 'Upload failed' }); }
});

router.get('/', async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin.from('books')
      .select('id, title, original_title, author, language, file_type, processing_status, processing_progress, created_at, traditions(name, slug)')
      .order('created_at', { ascending: false });
    if (error) return res.status(500).json({ error: error.message });
    res.json({ books: data });
  } catch (err) { res.status(500).json({ error: 'Failed to list books' }); }
});

router.get('/:id', async (req, res) => {
  try {
    const { data: book } = await supabaseAdmin.from('books').select('*, traditions(name, slug, description)').eq('id', req.params.id).single();
    if (!book) return res.status(404).json({ error: 'Book not found' });
    const { count } = await supabaseAdmin.from('book_chunks').select('id', { count: 'exact', head: true }).eq('book_id', req.params.id);
    res.json({ book, chunk_count: count });
  } catch (err) { res.status(500).json({ error: 'Failed to fetch book' }); }
});

router.post('/:id/reprocess', authenticate, requireAdmin, async (req, res) => {
  try {
    await supabaseAdmin.from('book_chunks').delete().eq('book_id', req.params.id);
    await supabaseAdmin.from('books').update({ processing_status: 'pending', processing_progress: 0, error_message: null }).eq('id', req.params.id);
    processBook(req.params.id).catch(e => logger.error('Reprocess fail:', e));
    res.json({ message: 'Reprocessing started' });
  } catch (err) { res.status(500).json({ error: 'Failed' }); }
});

router.delete('/:id', authenticate, requireAdmin, async (req, res) => {
  try {
    const { data: book } = await supabaseAdmin.from('books').select('file_url').eq('id', req.params.id).single();
    if (book?.file_url) await supabaseAdmin.storage.from('books').remove([book.file_url]);
    await supabaseAdmin.from('books').delete().eq('id', req.params.id);
    res.json({ message: 'Book deleted' });
  } catch (err) { res.status(500).json({ error: 'Failed' }); }
});

module.exports = router;
