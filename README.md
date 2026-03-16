# Jyotish AI — Self-Learning Vedic Astrology Intelligence System

A production-ready Android application that transforms classical Vedic astrology ebooks into a structured knowledge engine, generates accurate kundali charts, and provides AI-powered interpretations grounded in authenticated tradition.

## Quick Start

```bash
# 1. Set up Supabase - run database/schema.sql
# 2. Deploy backend
cd backend && cp .env.example .env && npm install
node scripts/seed-knowledge-graph.js
npm start

# 3. Run Flutter app
cd flutter_app && flutter pub get && flutter run
```

See docs/ for full deployment guides, privacy policy, terms, and Play Store instructions.

## Architecture

- **Frontend:** Flutter (Android/iOS)  
- **Backend:** Node.js + Express  
- **Database:** Supabase PostgreSQL + pgvector  
- **AI Inference:** DeepSeek API  
- **Embeddings:** OpenAI text-embedding-3-small  
- **Deployment:** Render (Docker)

## Key Components

| Component | File | Description |
|-----------|------|-------------|
| Astronomical Engine | `backend/src/services/astronomical-engine.js` | Planetary positions, nakshatras, dashas, yogas, divisional charts |
| Knowledge Pipeline | `backend/src/services/knowledge-pipeline.js` | PDF extraction → entity detection → chunking → embedding → KG |
| AI Engine | `backend/src/services/ai-engine.js` | RAG from book embeddings + DeepSeek reasoning |
| Database Schema | `database/schema.sql` | 12+ tables with RLS, vector search, KG traversal |
| Flutter App | `flutter_app/lib/` | 8 screens, 4 widgets, cosmic dark theme |
