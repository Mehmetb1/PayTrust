CREATE TABLE otp_tokens (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  email           CITEXT NOT NULL,

  -- Store a hash of the OTP, never the plaintext 6-digit code
  token_hash      TEXT NOT NULL,   -- SHA-256 hash of the OTP

  -- OTP purpose
  purpose         TEXT NOT NULL DEFAULT 'email_verification'
                    CHECK (purpose IN ('email_verification', 'login_2fa', 'password_reset')),

  expires_at      TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '15 minutes'),
  used_at         TIMESTAMPTZ,     -- Set when successfully consumed
  is_used         BOOLEAN NOT NULL DEFAULT FALSE,

  -- Brute-force protection
  attempt_count   INT NOT NULL DEFAULT 0,
  max_attempts    INT NOT NULL DEFAULT 5,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- One active, unused token per user per purpose at a time
  -- (old tokens are invalidated by marking is_used=true before creating new)
  CONSTRAINT no_expired_reuse CHECK (expires_at > created_at)
);

-- Auto-expire: cleanup job or Supabase pg_cron can call this
CREATE OR REPLACE FUNCTION cleanup_expired_otps()
RETURNS void AS $$
BEGIN
  DELETE FROM otp_tokens
  WHERE expires_at < NOW() OR is_used = TRUE;
END;
$$ LANGUAGE plpgsql;
