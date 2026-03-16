/**
 * JYOTISH AI — AI Interpretation Engine
 *
 * RAG from book embeddings → tradition-filtered context →
 * DeepSeek reasoning → source-cited interpretations.
 */

const { OpenAI } = require('openai');
const { searchKnowledge } = require('./knowledge-pipeline');
const { logger } = require('../utils/logger');

const deepseek = new OpenAI({
  apiKey: process.env.DEEPSEEK_API_KEY,
  baseURL: process.env.DEEPSEEK_BASE_URL || 'https://api.deepseek.com'
});

// ── System Prompts ───────────────────────────────────────

const BASE_PROMPT = `You are Jyotish AI, a deeply knowledgeable Vedic astrology intelligence system trained on classical Sanskrit texts. You interpret kundali charts with precision, always citing the tradition and source text for your interpretations.

RULES:
1. Never mix incompatible traditions (e.g., Parashara with KP sub-lords).
2. Always specify which tradition's framework you are using.
3. Cite the source text when referencing specific rules.
4. Explain Sanskrit terminology when used.
5. Be precise about planetary dignities, aspects, and house lordships.
6. Present predictions as tendencies, not certainties.
7. When analyzing yogas, check for cancellation conditions.`;

const KUNDALI_PROMPT = `Structure your interpretation:
1. ASCENDANT & PERSONALITY: Lagna lord placement and dignity.
2. PLANETARY STRENGTHS: Each planet's dignity, house, aspects.
3. KEY YOGAS: Active yogas with strength assessment.
4. DASHA ANALYSIS: Current and upcoming periods.
5. SPECIFIC HOUSE ANALYSIS: Based on the user's question.
6. SYNTHESIS: Combine all factors coherently.`;

const TRADITION_PROMPTS = {
  parashara: 'Use Brihat Parasara Hora Shastra principles. Focus on Vimshottari dasha, natural/temporal benefics-malefics, house lordships.',
  jaimini: 'Use Jaimini system. Focus on Chara Karakas, sign-based dashas, Swamsha, Jaimini aspects.',
  krishnamurti: 'Use Krishnamurti Paddhati. Focus on star-lords, sub-lords, significators, ruling planets.',
  classical_hora: 'Use Phaladipika / Saravali principles. Focus on verse-based significations and classical yoga definitions.',
  prasna: 'Use Prasna Marga principles. Focus on Ashtamangala, Arudha, time-based indicators.'
};

// ── Context Retrieval ────────────────────────────────────

async function retrieveContext(query, kundaliData, tradition) {
  const parts = [];

  // Query-relevant knowledge
  const qRes = await searchKnowledge(query, { tradition, matchCount: 5, threshold: 0.65 });
  if (qRes.length) parts.push({ type: 'query', results: qRes.map(r => ({ content: r.content, source: r.book_title, tradition: r.tradition_name, similarity: r.similarity })) });

  // Planet-specific knowledge
  if (kundaliData?.planets) {
    for (const p of Object.values(kundaliData.planets).slice(0, 3)) {
      const pq = `${p.planet} in ${p.rashi} ${p.nakshatra} house ${p.house_number} ${p.dignity}`;
      const pRes = await searchKnowledge(pq, { tradition, matchCount: 2, threshold: 0.6 });
      if (pRes.length) parts.push({ type: 'planet', planet: p.planet, results: pRes.map(r => ({ content: r.content, source: r.book_title })) });
    }
  }

  // Yoga-specific knowledge
  if (kundaliData?.yogas) {
    for (const y of kundaliData.yogas.slice(0, 3)) {
      const yRes = await searchKnowledge(y.yoga_name, { tradition, matchCount: 2, threshold: 0.6 });
      if (yRes.length) parts.push({ type: 'yoga', yoga: y.yoga_name, results: yRes.map(r => ({ content: r.content, source: r.book_title })) });
    }
  }
  return parts;
}

function formatContext(parts) {
  if (!parts.length) return 'No specific knowledge base references found. Use your general Jyotish knowledge.';
  let out = '=== KNOWLEDGE BASE REFERENCES ===\n\n';
  for (const p of parts) {
    if (p.type === 'query') {
      out += '--- Relevant Textual Knowledge ---\n';
      for (const r of p.results) out += `[${r.source} | ${r.tradition} | ${(r.similarity*100).toFixed(0)}%]\n${r.content}\n\n`;
    } else if (p.type === 'planet') {
      out += `--- ${p.planet} ---\n`;
      for (const r of p.results) out += `[${r.source}]\n${r.content}\n\n`;
    } else if (p.type === 'yoga') {
      out += `--- ${p.yoga} ---\n`;
      for (const r of p.results) out += `[${r.source}]\n${r.content}\n\n`;
    }
  }
  return out;
}

function formatKundali(k) {
  if (!k) return '';
  let t = '=== KUNDALI CHART DATA ===\n\n';
  t += `ASCENDANT: ${k.ascendant.rashi} (${k.ascendant.nakshatra} Pada ${k.ascendant.nakshatra_pada})\n\n`;
  t += 'PLANETARY POSITIONS:\n';
  for (const [p, d] of Object.entries(k.planets)) {
    t += `  ${p.toUpperCase()}: ${d.rashi} ${d.rashi_degree.toFixed(1)}° | H${d.house_number} | ${d.nakshatra} P${d.nakshatra_pada} | ${d.dignity}${d.is_retrograde ? ' [R]' : ''}\n`;
  }
  t += '\nHOUSES:\n';
  for (const h of k.houses) t += `  H${h.house_number}: ${h.rashi} (Lord: ${h.lord})\n`;
  if (k.yogas?.length) {
    t += '\nYOGAS:\n';
    for (const y of k.yogas) t += `  ${y.yoga_name} (${y.yoga_type}) ${(y.strength*100).toFixed(0)}% — ${y.forming_planets.join(',')}\n`;
  }
  const now = new Date();
  const curDashas = (k.dashas || []).filter(d => { const s = new Date(d.start_date), e = new Date(d.end_date); return now >= s && now <= e; });
  const maha = curDashas.find(d => d.level === 'maha');
  const antar = curDashas.find(d => d.level === 'antar');
  if (maha) t += `\nCURRENT MAHA DASHA: ${maha.planet} (${maha.start_date} to ${maha.end_date})\n`;
  if (antar) t += `CURRENT ANTAR DASHA: ${antar.planet} (${antar.start_date} to ${antar.end_date})\n`;
  return t;
}

// ── Main Interpretation ──────────────────────────────────

async function interpretQuery(params) {
  const { query, kundaliData = null, tradition = null, conversationHistory = [], userId } = params;

  try {
    const context = await retrieveContext(query, kundaliData, tradition);
    const fmtCtx = formatContext(context);
    const fmtKundali = formatKundali(kundaliData);

    let sysPrompt = BASE_PROMPT + '\n\n';
    if (kundaliData) sysPrompt += KUNDALI_PROMPT + '\n\n';
    if (tradition && TRADITION_PROMPTS[tradition]) sysPrompt += `TRADITION: ${TRADITION_PROMPTS[tradition]}\n\n`;

    const messages = [{ role: 'system', content: sysPrompt }];
    for (const m of conversationHistory.slice(-6)) messages.push({ role: m.role, content: m.content });

    let userMsg = '';
    if (fmtKundali) userMsg += fmtKundali + '\n\n';
    userMsg += fmtCtx + '\n\nUSER QUESTION: ' + query;
    messages.push({ role: 'user', content: userMsg });

    const res = await deepseek.chat.completions.create({
      model: 'deepseek-chat', messages, temperature: 0.3, max_tokens: 3000, top_p: 0.9
    });

    const aiResp = res.choices[0].message.content;
    const tokens = res.usage?.total_tokens || 0;

    const sources = context.flatMap(p => (p.results || []).map(r => ({
      source: r.source, tradition: r.tradition, content_preview: (r.content || '').substring(0, 200), similarity: r.similarity
    }))).slice(0, 5);

    return {
      response: aiResp, sources,
      reasoning_chain: { query, tradition_used: tradition || 'general', chunks_retrieved: context.reduce((s, p) => s + (p.results?.length || 0), 0), kundali_provided: !!kundaliData },
      tokens_used: tokens, model_used: 'deepseek-chat', tradition_used: tradition || 'general'
    };
  } catch (err) {
    logger.error('AI interpretation failed:', err);
    throw err;
  }
}

async function generateFullReading(kundaliData, tradition = null) {
  const sections = [
    'Provide a comprehensive personality analysis based on the Ascendant, its lord, and Moon sign.',
    'Analyze career and profession based on the 10th house, its lord, and relevant planets.',
    'Analyze wealth and finances based on the 2nd and 11th houses.',
    'Analyze relationships and marriage based on the 7th house and Venus.',
    'Identify the most significant yogas and their life impact.',
    'Analyze the current dasha period and upcoming transitions.'
  ];
  const readings = [];
  for (const q of sections) {
    readings.push(await interpretQuery({ query: q, kundaliData, tradition }));
  }
  return readings;
}

module.exports = { interpretQuery, generateFullReading, retrieveContext };
