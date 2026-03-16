-- ============================================================================
-- JYOTISH AI — Supabase PostgreSQL Schema
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ENUMS
CREATE TYPE tradition_type AS ENUM (
  'parashara','jaimini','krishnamurti','classical_hora',
  'tantric','prasna','tajika','nadi','modern_interpretive'
);
CREATE TYPE language_type AS ENUM ('sanskrit','hindi','english','mixed');
CREATE TYPE graha_type AS ENUM (
  'surya','chandra','mangala','budha','guru','shukra','shani','rahu','ketu'
);
CREATE TYPE rashi_type AS ENUM (
  'mesha','vrishabha','mithuna','karka','simha','kanya',
  'tula','vrishchika','dhanu','makara','kumbha','meena'
);
CREATE TYPE bhava_type AS ENUM (
  'bhava_1','bhava_2','bhava_3','bhava_4','bhava_5','bhava_6',
  'bhava_7','bhava_8','bhava_9','bhava_10','bhava_11','bhava_12'
);
CREATE TYPE dasha_system AS ENUM ('vimshottari','yogini','ashtottari','chara','narayana');
CREATE TYPE book_status AS ENUM ('uploaded','processing','extracted','chunked','embedded','indexed','failed');
CREATE TYPE ayanamsa_type AS ENUM ('lahiri','raman','krishnamurti','true_chitrapaksha');

-- USERS
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  role TEXT DEFAULT 'user' CHECK (role IN ('user','admin','astrologer')),
  preferred_ayanamsa ayanamsa_type DEFAULT 'lahiri',
  preferred_tradition tradition_type DEFAULT 'parashara',
  preferred_language TEXT DEFAULT 'en',
  is_active BOOLEAN DEFAULT true,
  email_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- BIRTH DATA
CREATE TABLE birth_data (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL, date_of_birth DATE NOT NULL,
  time_of_birth TIME NOT NULL, time_is_approximate BOOLEAN DEFAULT false,
  place_of_birth TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL, longitude DOUBLE PRECISION NOT NULL,
  timezone_offset DOUBLE PRECISION NOT NULL, timezone_name TEXT,
  dst_applied BOOLEAN DEFAULT false, notes TEXT,
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- KUNDALIS
CREATE TABLE kundalis (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  birth_data_id UUID NOT NULL REFERENCES birth_data(id) ON DELETE CASCADE,
  ayanamsa ayanamsa_type DEFAULT 'lahiri',
  ayanamsa_value DOUBLE PRECISION,
  ascendant_longitude DOUBLE PRECISION, ascendant_rashi rashi_type,
  ascendant_nakshatra TEXT, ascendant_nakshatra_pada INTEGER,
  midheaven_longitude DOUBLE PRECISION,
  house_system TEXT DEFAULT 'equal', sidereal_time DOUBLE PRECISION,
  julian_day DOUBLE PRECISION, chart_data JSONB,
  divisional_charts JSONB, computed_at TIMESTAMPTZ DEFAULT NOW(),
  engine_version TEXT DEFAULT '1.0.0', created_at TIMESTAMPTZ DEFAULT NOW()
);

-- PLANET POSITIONS
CREATE TABLE planet_positions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  kundali_id UUID NOT NULL REFERENCES kundalis(id) ON DELETE CASCADE,
  graha graha_type NOT NULL, longitude DOUBLE PRECISION NOT NULL,
  latitude DOUBLE PRECISION DEFAULT 0, speed DOUBLE PRECISION,
  is_retrograde BOOLEAN DEFAULT false,
  rashi rashi_type NOT NULL, rashi_degree DOUBLE PRECISION,
  nakshatra TEXT NOT NULL, nakshatra_pada INTEGER NOT NULL,
  nakshatra_lord graha_type, sub_lord graha_type,
  bhava bhava_type, is_combust BOOLEAN DEFAULT false,
  is_exalted BOOLEAN DEFAULT false, is_debilitated BOOLEAN DEFAULT false,
  is_own_sign BOOLEAN DEFAULT false, is_moolatrikona BOOLEAN DEFAULT false,
  dignity TEXT, shadbala DOUBLE PRECISION,
  ashtakavarga_score INTEGER, navamsa_rashi rashi_type,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- HOUSE CUSPS
CREATE TABLE house_cusps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  kundali_id UUID NOT NULL REFERENCES kundalis(id) ON DELETE CASCADE,
  bhava bhava_type NOT NULL, cusp_longitude DOUBLE PRECISION NOT NULL,
  rashi rashi_type NOT NULL, lord graha_type NOT NULL,
  significators JSONB, created_at TIMESTAMPTZ DEFAULT NOW()
);

-- DASHAS
CREATE TABLE dashas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  kundali_id UUID NOT NULL REFERENCES kundalis(id) ON DELETE CASCADE,
  dasha_type dasha_system DEFAULT 'vimshottari',
  mahadasha_lord graha_type NOT NULL,
  mahadasha_start DATE NOT NULL, mahadasha_end DATE NOT NULL,
  antardasha_lord graha_type,
  antardasha_start DATE, antardasha_end DATE,
  pratyantardasha_lord graha_type,
  pratyantardasha_start DATE, pratyantardasha_end DATE,
  level INTEGER DEFAULT 1 CHECK (level BETWEEN 1 AND 5),
  interpretation TEXT, source_tradition tradition_type,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- YOGAS
CREATE TABLE yogas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  kundali_id UUID NOT NULL REFERENCES kundalis(id) ON DELETE CASCADE,
  yoga_name TEXT NOT NULL, yoga_name_sanskrit TEXT,
  yoga_type TEXT NOT NULL,
  participating_grahas graha_type[], participating_bhavas bhava_type[],
  strength DOUBLE PRECISION DEFAULT 0.5, is_active BOOLEAN DEFAULT true,
  description TEXT, effects TEXT, source_text TEXT,
  source_tradition tradition_type, source_book_id UUID,
  conditions_met JSONB, created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TRADITIONS
CREATE TABLE traditions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name tradition_type UNIQUE NOT NULL, display_name TEXT NOT NULL,
  description TEXT, founding_sage TEXT, era TEXT,
  key_texts TEXT[], compatible_with tradition_type[],
  incompatible_with tradition_type[],
  calculation_preferences JSONB, created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO traditions (name, display_name, description, founding_sage, key_texts) VALUES
('parashara','Parashara Jyotish','Foundation of Vedic astrology','Maharishi Parashara',ARRAY['Brihat Parasara Hora Sastra']),
('jaimini','Jaimini Jyotish','Chara karakas, rashi aspects, chara dasha','Maharishi Jaimini',ARRAY['Jaimini Sutram']),
('classical_hora','Classical Hora Shastra','Traditional interpretation texts','Various Acharyas',ARRAY['Phaladipika','Garga Hora']),
('prasna','Prasna Shastra','Horary astrology','Kerala Tradition',ARRAY['Prasna Marga']),
('krishnamurti','Krishnamurti Paddhati','Sub-lord theory system','Prof. K.S. Krishnamurti',ARRAY['KP Reader']);

-- BOOKS
CREATE TABLE books (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL, title_original TEXT, author TEXT, translator TEXT,
  tradition tradition_type NOT NULL,
  language language_type DEFAULT 'english',
  languages_present language_type[] DEFAULT ARRAY['english']::language_type[],
  file_path TEXT, file_type TEXT, file_size_bytes BIGINT, file_hash TEXT,
  page_count INTEGER, status book_status DEFAULT 'uploaded',
  processing_progress DOUBLE PRECISION DEFAULT 0,
  processing_error TEXT, description TEXT, tags TEXT[], metadata JSONB,
  uploaded_by UUID REFERENCES users(id),
  uploaded_at TIMESTAMPTZ DEFAULT NOW(), processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- BOOK CHUNKS
CREATE TABLE book_chunks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  chunk_index INTEGER NOT NULL, content TEXT NOT NULL,
  content_original TEXT, language language_type DEFAULT 'english',
  page_number INTEGER, chapter TEXT, section TEXT, verse_number TEXT,
  embedding vector(1536), entities JSONB, tradition tradition_type,
  concepts TEXT[], related_grahas graha_type[], related_bhavas bhava_type[],
  related_rashis rashi_type[], related_nakshatras TEXT[],
  related_yogas TEXT[], token_count INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_chunks_embedding ON book_chunks
  USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- KNOWLEDGE GRAPH
CREATE TABLE kg_nodes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  node_type TEXT NOT NULL, name TEXT NOT NULL, name_sanskrit TEXT,
  description TEXT, properties JSONB, tradition tradition_type,
  source_book_id UUID REFERENCES books(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(node_type, name, tradition)
);

CREATE TABLE kg_edges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_node_id UUID NOT NULL REFERENCES kg_nodes(id) ON DELETE CASCADE,
  target_node_id UUID NOT NULL REFERENCES kg_nodes(id) ON DELETE CASCADE,
  relationship TEXT NOT NULL, weight DOUBLE PRECISION DEFAULT 1.0,
  properties JSONB, tradition tradition_type,
  source_book_id UUID REFERENCES books(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI QUERIES
CREATE TABLE ai_queries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kundali_id UUID REFERENCES kundalis(id),
  query_text TEXT NOT NULL, query_type TEXT DEFAULT 'general',
  tradition_filter tradition_type,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE ai_responses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  query_id UUID NOT NULL REFERENCES ai_queries(id) ON DELETE CASCADE,
  response_text TEXT NOT NULL, reasoning_chain JSONB,
  source_chunks UUID[], source_traditions tradition_type[],
  confidence DOUBLE PRECISION, model_used TEXT,
  tokens_used INTEGER, latency_ms INTEGER,
  user_rating INTEGER CHECK (user_rating BETWEEN 1 AND 5),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- NAKSHATRA REFERENCE
CREATE TABLE nakshatras (
  id SERIAL PRIMARY KEY, number INTEGER UNIQUE NOT NULL,
  name TEXT UNIQUE NOT NULL, name_sanskrit TEXT,
  start_degree DOUBLE PRECISION NOT NULL, end_degree DOUBLE PRECISION NOT NULL,
  lord graha_type NOT NULL, deity TEXT, symbol TEXT,
  gana TEXT, nature TEXT, qualities JSONB
);

INSERT INTO nakshatras (number,name,name_sanskrit,start_degree,end_degree,lord,deity,symbol) VALUES
(1,'Ashwini','अश्विनी',0,13.3333,'ketu','Ashwini Kumaras','Horse Head'),
(2,'Bharani','भरणी',13.3333,26.6667,'shukra','Yama','Yoni'),
(3,'Krittika','कृत्तिका',26.6667,40,'surya','Agni','Razor'),
(4,'Rohini','रोहिणी',40,53.3333,'chandra','Brahma','Chariot'),
(5,'Mrigashira','मृगशिरा',53.3333,66.6667,'mangala','Soma','Deer Head'),
(6,'Ardra','आर्द्रा',66.6667,80,'rahu','Rudra','Teardrop'),
(7,'Punarvasu','पुनर्वसु',80,93.3333,'guru','Aditi','Bow'),
(8,'Pushya','पुष्य',93.3333,106.6667,'shani','Brihaspati','Flower'),
(9,'Ashlesha','आश्लेषा',106.6667,120,'budha','Sarpa','Serpent'),
(10,'Magha','मघा',120,133.3333,'ketu','Pitris','Throne'),
(11,'Purva Phalguni','पूर्वा फाल्गुनी',133.3333,146.6667,'shukra','Bhaga','Hammock'),
(12,'Uttara Phalguni','उत्तरा फाल्गुनी',146.6667,160,'surya','Aryaman','Bed'),
(13,'Hasta','हस्त',160,173.3333,'chandra','Savitar','Hand'),
(14,'Chitra','चित्रा',173.3333,186.6667,'mangala','Vishwakarma','Pearl'),
(15,'Swati','स्वाति',186.6667,200,'rahu','Vayu','Coral'),
(16,'Vishakha','विशाखा',200,213.3333,'guru','Indra-Agni','Arch'),
(17,'Anuradha','अनुराधा',213.3333,226.6667,'shani','Mitra','Lotus'),
(18,'Jyeshtha','ज्येष्ठा',226.6667,240,'budha','Indra','Earring'),
(19,'Mula','मूल',240,253.3333,'ketu','Nirriti','Root'),
(20,'Purva Ashadha','पूर्वा आषाढ़ा',253.3333,266.6667,'shukra','Apas','Fan'),
(21,'Uttara Ashadha','उत्तरा आषाढ़ा',266.6667,280,'surya','Vishvedevas','Tusk'),
(22,'Shravana','श्रवण',280,293.3333,'chandra','Vishnu','Ear'),
(23,'Dhanishtha','धनिष्ठा',293.3333,306.6667,'mangala','Vasus','Drum'),
(24,'Shatabhisha','शतभिषा',306.6667,320,'rahu','Varuna','Circle'),
(25,'Purva Bhadrapada','पूर्वा भाद्रपदा',320,333.3333,'guru','Aja Ekapada','Sword'),
(26,'Uttara Bhadrapada','उत्तरा भाद्रपदा',333.3333,346.6667,'shani','Ahir Budhnya','Twins'),
(27,'Revati','रेवती',346.6667,360,'budha','Pushan','Fish');

-- VECTOR SEARCH FUNCTION
CREATE OR REPLACE FUNCTION search_knowledge(
  query_embedding vector(1536),
  match_count INTEGER DEFAULT 10,
  tradition_filter tradition_type DEFAULT NULL,
  similarity_threshold DOUBLE PRECISION DEFAULT 0.7
) RETURNS TABLE (
  chunk_id UUID, book_id UUID, content TEXT,
  similarity DOUBLE PRECISION, tradition tradition_type,
  chapter TEXT, verse_number TEXT
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT bc.id, bc.book_id, bc.content,
    1 - (bc.embedding <=> query_embedding) AS similarity,
    bc.tradition, bc.chapter, bc.verse_number
  FROM book_chunks bc
  WHERE bc.embedding IS NOT NULL
    AND (tradition_filter IS NULL OR bc.tradition = tradition_filter)
    AND 1 - (bc.embedding <=> query_embedding) > similarity_threshold
  ORDER BY bc.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

-- TIMESTAMPS TRIGGER
CREATE OR REPLACE FUNCTION update_updated_at() RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_ts BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER birth_data_ts BEFORE UPDATE ON birth_data FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER books_ts BEFORE UPDATE ON books FOR EACH ROW EXECUTE FUNCTION update_updated_at();
