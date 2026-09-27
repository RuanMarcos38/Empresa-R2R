-- R2R Marketing Digital • Automation OS
-- Schema opcional para persistência PostgreSQL.
-- Pode ser executado em um banco separado da base interna do n8n.

CREATE SCHEMA IF NOT EXISTS r2r;

CREATE TABLE IF NOT EXISTS r2r.leads (
  id BIGSERIAL PRIMARY KEY,
  lead_key TEXT UNIQUE NOT NULL,
  name TEXT,
  company TEXT,
  phone TEXT,
  email TEXT,
  source TEXT,
  service_interest TEXT,
  message TEXT,
  score INTEGER DEFAULT 0 CHECK (score BETWEEN 0 AND 100),
  temperature TEXT,
  status TEXT DEFAULT 'novo',
  do_not_contact BOOLEAN DEFAULT FALSE,
  opt_in_whatsapp BOOLEAN DEFAULT FALSE,
  next_followup_at TIMESTAMPTZ,
  last_reply_at TIMESTAMPTZ,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_r2r_leads_phone ON r2r.leads(phone);
CREATE INDEX IF NOT EXISTS idx_r2r_leads_email ON r2r.leads(email);
CREATE INDEX IF NOT EXISTS idx_r2r_leads_status_score ON r2r.leads(status, score DESC);

CREATE TABLE IF NOT EXISTS r2r.conversations (
  id BIGSERIAL PRIMARY KEY,
  lead_key TEXT,
  phone TEXT,
  direction TEXT NOT NULL CHECK (direction IN ('inbound','outbound')),
  channel TEXT NOT NULL DEFAULT 'whatsapp',
  message_id TEXT,
  message TEXT,
  stage TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(channel, message_id)
);

CREATE TABLE IF NOT EXISTS r2r.outreach_log (
  id BIGSERIAL PRIMARY KEY,
  lead_key TEXT,
  phone TEXT,
  campaign TEXT,
  status TEXT,
  message_hash TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_r2r_outreach_phone ON r2r.outreach_log(phone);
CREATE INDEX IF NOT EXISTS idx_r2r_outreach_sent ON r2r.outreach_log(sent_at DESC);

CREATE TABLE IF NOT EXISTS r2r.meetings (
  id BIGSERIAL PRIMARY KEY,
  lead_key TEXT,
  name TEXT,
  email TEXT,
  phone TEXT,
  service_interest TEXT,
  calendar_event_id TEXT,
  meeting_url TEXT,
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  status TEXT DEFAULT 'agendada',
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS r2r.proposals (
  id BIGSERIAL PRIMARY KEY,
  lead_key TEXT,
  title TEXT,
  status TEXT DEFAULT 'rascunho',
  amount NUMERIC(14,2),
  content TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS r2r.clients (
  id BIGSERIAL PRIMARY KEY,
  client_key TEXT UNIQUE NOT NULL,
  name TEXT,
  company TEXT,
  phone TEXT,
  email TEXT,
  service TEXT,
  status TEXT DEFAULT 'ativo',
  mrr NUMERIC(14,2) DEFAULT 0,
  risk_level TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS r2r.metrics (
  id BIGSERIAL PRIMARY KEY,
  client_key TEXT,
  platform TEXT,
  account_id TEXT,
  campaign_id TEXT,
  metric_date DATE,
  spend NUMERIC(14,2),
  leads INTEGER,
  conversions NUMERIC(14,2),
  revenue NUMERIC(14,2),
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS r2r.sales (
  id BIGSERIAL PRIMARY KEY,
  lead_key TEXT,
  client_key TEXT,
  service TEXT,
  value NUMERIC(14,2) NOT NULL DEFAULT 0,
  recurring_value NUMERIC(14,2) NOT NULL DEFAULT 0,
  status TEXT DEFAULT 'fechada',
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  closed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS r2r.incidents (
  id BIGSERIAL PRIMARY KEY,
  severity TEXT,
  workflow TEXT,
  node TEXT,
  message TEXT,
  execution_id TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
