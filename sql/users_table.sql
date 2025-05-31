CREATE TABLE IF NOT EXISTS users (
  id          SERIAL PRIMARY KEY,
  name        TEXT NOT NULL,
  email       TEXT UNIQUE NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- seed some initial rows
INSERT INTO users (name, email)
VALUES
  ('Alice', 'alice@example.com'),
  ('Bob',   'bob@example.com')
ON CONFLICT DO NOTHING;