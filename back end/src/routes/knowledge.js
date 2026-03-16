const express = require('express');
const router = express.Router();
const { supabaseAdmin } = require('../utils/supabase');
const { searchKnowledge } = require('../services/knowledge-pipeline');
const { logger } = require('../utils/logger');

router.post('/search', async (req, res) => {
  try {
    const { query, tradition, count, threshold, content_type } = req.body;
    if (!query) return res.status(400).json({ error: 'Query required' });
    const results = await searchKnowledge(query, {
      tradition, matchCount: count || 10, threshold: threshold || 0.65, contentType: content_type
    });
    res.json({ results, count: results.length });
  } catch (err) { logger.error('Search error:', err); res.status(500).json({ error: 'Search failed' }); }
});

router.get('/graph/nodes', async (req, res) => {
  try {
    const { type, limit: lim } = req.query;
    let q = supabaseAdmin.from('kg_nodes').select('id, node_type, name, sanskrit_name, description, properties');
    if (type) q = q.eq('node_type', type);
    const { data, error } = await q.order('name').limit(parseInt(lim) || 100);
    if (error) return res.status(500).json({ error: error.message });
    res.json({ nodes: data });
  } catch (err) { res.status(500).json({ error: 'Failed' }); }
});

router.get('/graph/node/:id', async (req, res) => {
  try {
    const { data: node } = await supabaseAdmin.from('kg_nodes').select('*').eq('id', req.params.id).single();
    if (!node) return res.status(404).json({ error: 'Node not found' });
    const { data: outEdges } = await supabaseAdmin.from('kg_edges').select('*, target:target_node_id(id, node_type, name)').eq('source_node_id', req.params.id);
    const { data: inEdges } = await supabaseAdmin.from('kg_edges').select('*, source:source_node_id(id, node_type, name)').eq('target_node_id', req.params.id);
    res.json({ node, outgoing_edges: outEdges, incoming_edges: inEdges });
  } catch (err) { res.status(500).json({ error: 'Failed' }); }
});

router.post('/graph/traverse', async (req, res) => {
  try {
    const { start_node_id, max_depth, relationships } = req.body;
    if (!start_node_id) return res.status(400).json({ error: 'start_node_id required' });
    const { data, error } = await supabaseAdmin.rpc('traverse_knowledge_graph', {
      start_node_id, max_depth: max_depth || 3, relationship_filter: relationships || null
    });
    if (error) return res.status(500).json({ error: error.message });
    res.json({ graph: data });
  } catch (err) { res.status(500).json({ error: 'Traversal failed' }); }
});

router.get('/traditions', async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin.from('traditions').select('*').order('name');
    if (error) return res.status(500).json({ error: error.message });
    res.json({ traditions: data });
  } catch (err) { res.status(500).json({ error: 'Failed' }); }
});

router.get('/stats', async (req, res) => {
  try {
    const { count: books } = await supabaseAdmin.from('books').select('id', { count: 'exact', head: true }).eq('processing_status', 'completed');
    const { count: chunks } = await supabaseAdmin.from('book_chunks').select('id', { count: 'exact', head: true });
    const { count: nodes } = await supabaseAdmin.from('kg_nodes').select('id', { count: 'exact', head: true });
    const { count: edges } = await supabaseAdmin.from('kg_edges').select('id', { count: 'exact', head: true });
    res.json({ books_processed: books, total_chunks: chunks, graph_nodes: nodes, graph_edges: edges });
  } catch (err) { res.status(500).json({ error: 'Failed' }); }
});

module.exports = router;
