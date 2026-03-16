# Jyotish AI — Deployment Guide

## Step-by-Step Production Deployment

---

### Phase 1: Supabase Setup

1. Create a project at https://supabase.com
2. Go to SQL Editor → paste and run `database/schema.sql`
3. Enable extensions if not auto-enabled:
   ```sql
   CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
   CREATE EXTENSION IF NOT EXISTS "vector";
   ```
4. Create a Storage bucket:
   - Name: `books`
   - Public: No
   - File size limit: 100MB
5. Copy from Settings → API:
   - Project URL → `SUPABASE_URL`
   - `anon` public key → `SUPABASE_ANON_KEY`
   - `service_role` secret key → `SUPABASE_SERVICE_KEY`

---

### Phase 2: API Keys

1. **DeepSeek**: Sign up at https://platform.deepseek.com → API Keys → Create
2. **OpenAI**: Sign up at https://platform.openai.com → API Keys → Create (for embeddings only)

---

### Phase 3: Backend Deployment on Render

1. Push project to GitHub
2. Go to https://dashboard.render.com
3. Click "New" → "Web Service"
4. Connect your repository
5. Configure:
   - Name: `jyotish-ai-backend`
   - Root Directory: `backend`
   - Runtime: Docker
   - Region: Singapore (closest to India)
   - Instance: Starter ($7/month) or Free
6. Add Environment Variables:
   ```
   NODE_ENV=production
   PORT=3000
   SUPABASE_URL=https://xxx.supabase.co
   SUPABASE_ANON_KEY=eyJ...
   SUPABASE_SERVICE_KEY=eyJ...
   DEEPSEEK_API_KEY=sk-...
   OPENAI_API_KEY=sk-...
   JWT_SECRET=(auto-generated)
   RATE_LIMIT_WINDOW_MS=900000
   RATE_LIMIT_MAX=100
   ```
7. Deploy

After deployment, test: `curl https://jyotish-ai-backend.onrender.com/health`

---

### Phase 4: Seed Knowledge Graph

```bash
cd backend
cp .env.example .env   # Fill in your keys
npm install
node scripts/seed-knowledge-graph.js
```

This creates 9 grahas, 12 rashis, 12 bhavas + ownership/exaltation/friendship edges.

---

### Phase 5: Upload Books

Create an admin user, then upload books:

```bash
# First sign up via API
curl -X POST https://YOUR_BACKEND/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"securepass123","display_name":"Admin"}'

# Set as admin (run in Supabase SQL editor)
# UPDATE users SET is_admin = true WHERE email = 'admin@example.com';

# Login to get token
curl -X POST https://YOUR_BACKEND/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"securepass123"}'
# Copy access_token from response

# Upload a book
curl -X POST https://YOUR_BACKEND/api/books/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@phaladipika.pdf" \
  -F "title=Phaladipika" \
  -F "author=Mantreshwara" \
  -F "tradition_slug=classical_hora"
```

---

### Phase 6: Flutter App Configuration

1. Edit `flutter_app/lib/services/api_service.dart`:
   ```dart
   static const String baseUrl = 'https://jyotish-ai-backend.onrender.com/api';
   ```

2. Test locally:
   ```bash
   cd flutter_app
   flutter pub get
   flutter run
   ```

3. Build release APK:
   ```bash
   flutter build appbundle --release
   ```

---

### Phase 7: Play Store Submission

Follow `docs/PLAY_STORE_GUIDE.md` for complete instructions including signing key generation, store listing, and compliance checklist.

---

## Architecture Verification Checklist

| Component | Status | Test Command |
|-----------|--------|-------------|
| Database schema | ✅ | Run schema.sql in Supabase |
| Knowledge graph seed | ✅ | `node scripts/seed-knowledge-graph.js` |
| Backend server | ✅ | `curl /health` |
| Auth endpoints | ✅ | `POST /api/auth/signup` |
| Kundali generation | ✅ | `POST /api/kundali/generate` |
| Book upload | ✅ | `POST /api/books/upload` |
| AI chat | ✅ | `POST /api/ai/message` |
| Knowledge search | ✅ | `POST /api/knowledge/search` |
| Flutter app | ✅ | `flutter run` |
| Docker build | ✅ | `docker build backend/` |
| Render deploy | ✅ | Push to GitHub |
