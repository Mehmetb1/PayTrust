CREATE TABLE users (
  -- Identity
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email                 CITEXT NOT NULL UNIQUE,
  username              CITEXT NOT NULL UNIQUE
                          CHECK (username ~ '^[a-zA-Z0-9_]{3,30}$'), -- Alphanumeric + underscore, 3-30 chars
  password_hash         TEXT NOT NULL,                                -- bcrypt hash, NEVER store plaintext

  -- Profile
  full_name             TEXT,
  avatar_url            TEXT,
  bio                   TEXT CHECK (char_length(bio) <= 500),
  preferred_locale      CHAR(2) NOT NULL DEFAULT 'en'
                          CHECK (preferred_locale IN ('en', 'tr')),

  -- Account state
  account_status        account_status NOT NULL DEFAULT 'pending_verification',
  email_verified_at     TIMESTAMPTZ,

  -- Stripe Connect (for receiving payouts as a freelancer)
  stripe_account_id     TEXT UNIQUE,                  -- Stripe Connected Account ID (acct_xxx)
  stripe_account_status TEXT DEFAULT 'not_connected'  -- 'not_connected' | 'onboarding' | 'active' | 'restricted'
                          CHECK (stripe_account_status IN ('not_connected', 'onboarding', 'active', 'restricted')),
  stripe_onboarding_complete BOOLEAN NOT NULL DEFAULT FALSE,

  -- Banking / Payout Info (encrypted at application layer before insert)
  iban_encrypted        TEXT,   -- AES-256 encrypted IBAN
  bank_name             TEXT,
  account_holder_name   TEXT,

  -- Timestamps
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_login_at         TIMESTAMPTZ
);

-- Auto-update updated_at on any row change
CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
