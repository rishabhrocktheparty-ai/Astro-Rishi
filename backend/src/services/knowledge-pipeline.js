/**
 * JYOTISH AI — Knowledge Ingestion Pipeline
 *
 * Processes astrology books: extract text → detect language →
 * extract Jyotish entities → classify tradition → chunk →
 * generate embeddings → populate knowledge graph.
 */

const { supabaseAdmin } = require('../utils/supabase');
const { logger } = require('../utils/logger');
const { OpenAI } = require('openai');

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// ── Entity Dictionaries ──────────────────────────────────

const JYOTISH_ENTITIES = {
  graha: [
    'sun','moon','mars','mercury','jupiter','venus','saturn','rahu','ketu',
    'surya','chandra','mangal','kuja','budha','guru','brihaspati','shukra','shani',
    'सूर्य','चन्द्र','मंगल','बुध','गुरु','शुक्र','शनि','राहु','केतु'
  ],
  bhava: [
    'first house','second house','third house','fourth house','fifth house',
    'sixth house','seventh house','eighth house','ninth house','tenth house',
    'eleventh house','twelfth house','ascendant','lagna','tanu','dhana',
    'sahaja','sukha','putra','ari','yuvati','randhra','dharma','karma','labha','vyaya',
    'kendra','trikona','dusthana','upachaya','maraka'
  ],
  rashi: [
    'aries','taurus','gemini','cancer','leo','virgo','libra','scorpio',
    'sagittarius','capricorn','aquarius','pisces',
    'mesha','vrishabha','mithuna','karka','simha','kanya',
    'tula','vrishchika','dhanu','makara','kumbha','meena'
  ],
  nakshatra: [
    'ashwini','bharani','krittika','rohini','mrigashira','ardra',
    'punarvasu','pushya','ashlesha','magha','purva phalguni','uttara phalguni',
    'hasta','chitra','swati','vishakha','anuradha','jyeshtha',
    'mula','purva ashadha','uttara ashadha','shravana','dhanishtha',
    'shatabhisha','purva bhadrapada','uttara bhadrapada','revati'
  ],
  yoga_types: [
    'raja yoga','dhana yoga','gajakesari','pancha mahapurusha','ruchaka',
    'bhadra','hamsa','malavya','shasha','budhaditya','neecha bhanga',
    'vipareet raja','parivartana','chandra mangala','saraswati',
    'lakshmi yoga','amala yoga','kemadruma','shakata yoga'
  ],
  dasha_systems: ['vimshottari','yogini','ashtottari','chara dasha','narayana dasha','kalachakra'],
  karakas: [
    'atmakaraka','amatyakaraka','bhratrukaraka','matrukaraka',
    'putrakaraka','gnatikaraka','darakaraka','significator','karaka'
  ]
};

const TRADITION_PATTERNS = {
  parashara:      { kw: ['parasara','parashara','hora shastra','brihat hora','vimshottari','graha dasha'], w: 1.0 },
  jaimini:        { kw: ['jaimini','chara karaka','atmakaraka','amatyakaraka','chara dasha','swamsha'], w: 1.0 },
  krishnamurti:   { kw: ['krishnamurti','kp system','sub lord','star lord','ruling planets','cuspal sub'], w: 1.0 },
  classical_hora: { kw: ['phaladipika','saravali','jataka parijata','uttara kalamrita','mantreshwara','varahamihira'], w: 0.9 },
  prasna:         { kw: ['prasna','horary','prashna marga','question chart','arudha','krishneeyam'], w: 1.0 },
  tantric:        { kw: ['lal kitab','mantra','yantra','tantra','remedy','upaya'], w: 0.7 },
  nadi:           { kw: ['nadi','bhrigu','dhruva nadi','palm leaf','saptarishi'], w: 1.0 }
};

// ── Text Extraction ──────────────────────────────────────

async function extractTextFromPDF(buffer) {
  const pdfParse = require('pdf-parse');
  const data = await pdfParse(buffer);
  return { text: data.text, pages: data.numpages, metadata: data.info };
}

async function extractTextFromEPUB(buffer) {
  const fs = require('fs');
  const path = require('path');
  const EPub = require('epub2');
  const tmp = path.join('/tmp', `epub_${Date.now()}.epub`);
  fs.writeFileSync(tmp, buffer);
  const epub = await EPub.createAsync(tmp);
  const chapters = [];
  for (const ch of epub.flow) {
    try {
      const html = await epub.getChapterAsync(ch.id);
      chapters.push(html.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim());
    } catch (_) {}
  }
  fs.unlinkSync(tmp);
  return { text: chapters.join('\n\n'), chapters, metadata: epub.metadata };
}

// ── Language Detection ────────────────────────────────────

function detectLanguage(text) {
  const sample = text.substring(0, 2000);
  const devaCount = (sample.match(/[\u0900-\u097F]/g) || []).length;
  const total = sample.replace(/\s/g, '').length || 1;
  if (devaCount > total * 0.3) {
    const saMarkers = ['॥','श्लोक','अध्याय','इति','तत्र','यदा'];
    const hiMarkers = ['है','हैं','था','में','को','से','का','की','के'];
    return saMarkers.filter(m => sample.includes(m)).length >
           hiMarkers.filter(m => sample.includes(m)).length ? 'sa' : 'hi';
  }
  if (/[āīūṛṝḷḹṃḥśṣṇṭḍ]/.test(sample)) return 'sa_transliterated';
  return 'en';
}

// ── Entity Extraction ────────────────────────────────────

function extractJyotishEntities(text) {
  const entities = {};
  const lt = text.toLowerCase();
  for (const [cat, terms] of Object.entries(JYOTISH_ENTITIES)) {
    const found = terms.filter(t => lt.includes(t.toLowerCase()));
    if (found.length) entities[cat] = [...new Set(found)];
  }
  return entities;
}

// ── Tradition Classification ─────────────────────────────

function classifyTradition(text) {
  const lt = text.toLowerCase();
  const scores = {};
  for (const [t, cfg] of Object.entries(TRADITION_PATTERNS)) {
    scores[t] = (cfg.kw.filter(k => lt.includes(k)).length / cfg.kw.length) * cfg.w;
  }
  const sorted = Object.entries(scores).sort((a, b) => b[1] - a[1]);
  return sorted[0][1] > 0
    ? { primary: sorted[0][0], confidence: sorted[0][1], scores }
    : { primary: 'classical_hora', confidence: 0.3, scores };
}

// ── Semantic Chunking ────────────────────────────────────

function semanticChunk(text, maxSize = 1500, overlap = 200) {
  const chunks = [];
  const paragraphs = text.split(/\n\s*\n/);
  let current = '', idx = 0;

  for (const para of paragraphs) {
    const trimmed = para.trim();
    if (!trimmed) continue;
    if ((current + trimmed).length > maxSize && current) {
      let type = 'prose';
      if (/rule|principle|sutra/i.test(current)) type = 'rule';
      if (/example|case|chart/i.test(current)) type = 'example';
      if (/commentary|meaning/i.test(current)) type = 'commentary';
      if (/॥|verse|shloka/i.test(current)) type = 'verse';
      chunks.push({ chunk_index: idx++, content: current.trim(), content_type: type });
      current = current.slice(-overlap) + '\n' + trimmed;
    } else {
      current += '\n' + trimmed;
    }
  }
  if (current.trim()) chunks.push({ chunk_index: idx, content: current.trim(), content_type: 'prose' });
  return chunks;
}

// ── Embedding Generation ─────────────────────────────────

async function generateEmbedding(text) {
  const res = await openai.embeddings.create({
    model: 'text-embedding-3-small', input: text.substring(0, 8000), dimensions: 1536
  });
  return res.data[0].embedding;
}

async function generateEmbeddingsBatch(texts, batchSize = 20) {
  const embeddings = [];
  for (let i = 0; i < texts.length; i += batchSize) {
    const batch = texts.slice(i, i + batchSize);
    try {
      const res = await openai.embeddings.create({
        model: 'text-embedding-3-small', input: batch.map(t => t.substring(0, 8000)), dimensions: 1536
      });
      embeddings.push(...res.data.map(d => d.embedding));
    } catch (err) {
      logger.error(`Embedding batch ${i} failed:`, err);
      embeddings.push(...new Array(batch.length).fill(null));
    }
    if (i + batchSize < texts.length) await new Promise(r => setTimeout(r, 500));
  }
  return embeddings;
}

// ── Knowledge Graph Population ───────────────────────────

async function populateKnowledgeGraph(bookId, chunks, traditionId) {
  const nodeMap = new Map();
  const edges = [];

  for (const chunk of chunks) {
    const ents = chunk.entities || {};
    for (const [etype, terms] of Object.entries(ents)) {
      if (etype === 'rules') continue;
      const ntype = { graha:'graha', bhava:'bhava', rashi:'rashi', nakshatra:'nakshatra',
                      yoga_types:'yoga', dasha_systems:'dasha', karakas:'karaka' }[etype] || 'concept';
      for (const term of terms) {
        const key = `${ntype}:${term.toLowerCase()}`;
        if (!nodeMap.has(key)) nodeMap.set(key, { node_type: ntype, name: term, tradition_id: traditionId, source_chunk_ids: [chunk.id] });
        else nodeMap.get(key).source_chunk_ids.push(chunk.id);
      }
    }
    const grahas = ents.graha || [], bhavas = ents.bhava || [], rashis = ents.rashi || [];
    for (const g of grahas) {
      for (const b of bhavas) edges.push({ source:`graha:${g.toLowerCase()}`, target:`bhava:${b.toLowerCase()}`, relationship:'influences', tradition_id:traditionId });
      for (const r of rashis) edges.push({ source:`graha:${g.toLowerCase()}`, target:`rashi:${r.toLowerCase()}`, relationship:'rules', tradition_id:traditionId });
    }
  }

  let edgeCount = 0;
  const idMap = new Map();
  for (const [key, node] of nodeMap) {
    const { data } = await supabaseAdmin.from('kg_nodes')
      .upsert({ node_type: node.node_type, name: node.name, tradition_id: node.tradition_id, source_chunk_ids: node.source_chunk_ids }, { onConflict: 'name,node_type' })
      .select('id').single();
    if (data) idMap.set(key, data.id);
  }
  for (const e of edges) {
    const sid = idMap.get(e.source), tid = idMap.get(e.target);
    if (sid && tid) { await supabaseAdmin.from('kg_edges').insert({ source_node_id:sid, target_node_id:tid, relationship:e.relationship, tradition_id:e.tradition_id }); edgeCount++; }
  }
  logger.info(`KG updated: ${nodeMap.size} nodes, ${edgeCount} edges`);
  return { nodes: nodeMap.size, edges: edgeCount };
}

// ── Main Pipeline ────────────────────────────────────────

async function processBook(bookId) {
  const t0 = Date.now();
  try {
    const { data: book, error: bErr } = await supabaseAdmin.from('books').select('*').eq('id', bookId).single();
    if (bErr || !book) throw new Error('Book not found');
    await updateStatus(bookId, 'processing', 0);
    logger.info(`Processing: ${book.title}`);

    const { data: fileData, error: fErr } = await supabaseAdmin.storage.from('books').download(book.file_url);
    if (fErr) throw new Error(`Download failed: ${fErr.message}`);
    const buffer = Buffer.from(await fileData.arrayBuffer());

    await updateStatus(bookId, 'extracting', 10);
    let extracted;
    switch (book.file_type) {
      case 'pdf':  extracted = await extractTextFromPDF(buffer); break;
      case 'epub': extracted = await extractTextFromEPUB(buffer); break;
      case 'txt':  extracted = { text: buffer.toString('utf-8'), pages: 0 }; break;
      default: throw new Error(`Unsupported: ${book.file_type}`);
    }
    if (!extracted.text || extracted.text.trim().length < 100) throw new Error('Insufficient text');

    const language = detectLanguage(extracted.text);
    const tradition = classifyTradition(extracted.text);
    logger.info(`Language: ${language}, Tradition: ${tradition.primary} (${tradition.confidence})`);

    const { data: trad } = await supabaseAdmin.from('traditions').select('id').eq('slug', tradition.primary).single();
    if (trad) await supabaseAdmin.from('books').update({ tradition_id: trad.id, language }).eq('id', bookId);

    await updateStatus(bookId, 'embedding', 30);
    const chunks = semanticChunk(extracted.text);
    const enriched = chunks.map(c => ({ ...c, entities: extractJyotishEntities(c.content), language, book_id: bookId }));

    await updateStatus(bookId, 'embedding', 50);
    const embeddings = await generateEmbeddingsBatch(enriched.map(c => c.content));

    const records = enriched.map((c, i) => ({
      book_id: bookId, chunk_index: c.chunk_index, content: c.content,
      content_type: c.content_type, language: c.language,
      embedding: embeddings[i], entities: c.entities,
      metadata: { tradition: tradition.primary }
    }));

    const BATCH = 50;
    for (let i = 0; i < records.length; i += BATCH) {
      await supabaseAdmin.from('book_chunks').insert(records.slice(i, i + BATCH));
      await updateStatus(bookId, 'embedding', 50 + (i / records.length) * 40);
    }

    await updateStatus(bookId, 'embedding', 90);
    const kgResult = await populateKnowledgeGraph(bookId, enriched, trad?.id);

    await updateStatus(bookId, 'completed', 100);
    await supabaseAdmin.from('learning_metrics').insert([
      { metric_type: 'book_processed', value: { book_id: bookId, title: book.title, duration_ms: Date.now() - t0 } },
      { metric_type: 'chunks_created', value: { book_id: bookId, count: chunks.length } },
      { metric_type: 'embeddings_generated', value: { book_id: bookId, count: embeddings.filter(e => e).length } },
      { metric_type: 'kg_nodes_added', value: { book_id: bookId, count: kgResult.nodes } },
      { metric_type: 'kg_edges_added', value: { book_id: bookId, count: kgResult.edges } }
    ]);

    logger.info(`Complete: ${book.title} in ${Date.now() - t0}ms`);
    return { success: true, bookId, chunks: chunks.length, tradition: tradition.primary, language, knowledgeGraph: kgResult };
  } catch (err) {
    logger.error(`Failed ${bookId}:`, err);
    await updateStatus(bookId, 'failed', 0, err.message);
    throw err;
  }
}

async function updateStatus(id, status, progress, errorMsg = null) {
  const upd = { processing_status: status, processing_progress: progress };
  if (errorMsg) upd.error_message = errorMsg;
  await supabaseAdmin.from('books').update(upd).eq('id', id);
}

// ── Semantic Search ──────────────────────────────────────

async function searchKnowledge(query, opts = {}) {
  const { tradition = null, matchCount = 10, threshold = 0.7, contentType = null } = opts;
  const qEmb = await generateEmbedding(query);
  const { data, error } = await supabaseAdmin.rpc('search_book_chunks', {
    query_embedding: qEmb, match_threshold: threshold,
    match_count: matchCount, tradition_filter: tradition
  });
  if (error) throw error;
  return contentType ? data.filter(d => d.content_type === contentType) : data;
}

module.exports = {
  processBook, searchKnowledge, extractJyotishEntities, classifyTradition,
  detectLanguage, semanticChunk, generateEmbedding, generateEmbeddingsBatch, populateKnowledgeGraph
};
