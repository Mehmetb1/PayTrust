CREATE TABLE payouts (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id            UUID NOT NULL REFERENCES projects(id) ON DELETE RESTRICT,
  project_member_id     UUID NOT NULL REFERENCES project_members(id) ON DELETE RESTRICT,
  recipient_user_id     UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,

  -- The Stripe Connected Account to transfer funds to
  stripe_account_id     TEXT NOT NULL,  -- recipient's acct_xxx

  amount                NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  currency              CHAR(3) NOT NULL DEFAULT 'USD',

  -- Stripe transfer details
  stripe_transfer_id    TEXT UNIQUE,    -- tr_xxx created by Stripe
  stripe_payout_id      TEXT,           -- po_xxx (Stripe's bank-level payout)

  status                payout_status NOT NULL DEFAULT 'queued',
  failure_reason        TEXT,

  initiated_at          TIMESTAMPTZ,
  completed_at          TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- One payout record per member per project
  UNIQUE (project_id, project_member_id)
);

CREATE TRIGGER set_payouts_updated_at
  BEFORE UPDATE ON payouts
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
