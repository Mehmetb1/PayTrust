-- Full audit trail of every money movement on the platform
CREATE TABLE escrow_transactions (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id            UUID NOT NULL REFERENCES projects(id) ON DELETE RESTRICT,

  -- Who is involved
  from_user_id          UUID REFERENCES users(id),  -- NULL for initial Stripe inbound
  to_user_id            UUID REFERENCES users(id),  -- NULL for platform commission

  transaction_type      transaction_type NOT NULL,
  status                transaction_status NOT NULL DEFAULT 'pending',

  -- Amounts
  amount                NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  currency              CHAR(3) NOT NULL DEFAULT 'USD',

  -- Stripe references for reconciliation
  stripe_payment_intent_id  TEXT,
  stripe_transfer_id        TEXT,
  stripe_charge_id          TEXT,
  stripe_refund_id          TEXT,

  -- Raw Stripe event payload for debugging/audit
  stripe_raw_event      JSONB,

  -- Error tracking
  failure_reason        TEXT,

  processed_at          TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_escrow_transactions_updated_at
  BEFORE UPDATE ON escrow_transactions
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
