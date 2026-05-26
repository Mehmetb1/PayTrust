-- Required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";      -- UUID primary keys
CREATE EXTENSION IF NOT EXISTS "pgcrypto";        -- Secure token hashing
CREATE EXTENSION IF NOT EXISTS "citext";          -- Case-insensitive text (usernames/emails)
