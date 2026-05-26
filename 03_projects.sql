CREATE TABLE projects (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Ownership
  employer_id           UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,

  -- Project details
  title                 TEXT NOT NULL CHECK (char_length(title) BETWEEN 3 AND 150),
  description           TEXT CHECK (char_length(description) <= 5000),
  
  -- Budget & Financial
  budget_amount         NUMERIC(12, 2) NOT NULL CHECK (budget_amount > 0),
  currency              CHAR(3) NOT NULL DEFAULT 'USD',  -- ISO 4217

  -- Computed financial columns (populated on escrow deposit)
  platform_fee_amount   NUMERIC(12, 2)  -- budget_amount * 0.05
    GENERATED ALWAYS AS (ROUND(budget_amount * 0.05, 2)) STORED,
  freelancer_pool_amount NUMERIC(12, 2) -- budget_amount * 0.95
    GENERATED ALWAYS AS (ROUND(budget_amount * 0.95, 2)) STORED,

  -- Stripe references
  stripe_payment_intent_id  TEXT UNIQUE,  -- PaymentIntent used for escrow deposit
  stripe_transfer_group     TEXT UNIQUE,  -- Groups all related transfers for this project

  -- State machine
  status                project_status NOT NULL DEFAULT 'draft',

  -- Completion handshake (both must confirm to trigger payout)
  employer_confirmed_complete   BOOLEAN NOT NULL DEFAULT FALSE,
  freelancer_confirmed_complete BOOLEAN NOT NULL DEFAULT FALSE,

  -- Deadlines
  deadline              TIMESTAMPTZ,
  funded_at             TIMESTAMPTZ,
  completed_at          TIMESTAMPTZ,

  -- Audit
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_projects_updated_at
  BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

-- ─────────────────────────────────────────────
-- Project Members (accepted freelancers + their revenue split)
-- ─────────────────────────────────────────────
CREATE TABLE project_members (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id        UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,

  -- Revenue split (set by employer after invitation is accepted)
  revenue_percentage NUMERIC(5, 2)
    CHECK (revenue_percentage > 0 AND revenue_percentage <= 100),

  -- Computed payout (populated when project completes)
  -- = freelancer_pool_amount * (revenue_percentage / 100)
  calculated_payout_amount  NUMERIC(12, 2),

  -- Payout tracking
  payout_status     payout_status NOT NULL DEFAULT 'queued',
  payout_id         UUID,  -- FK to payouts table (set after payout triggered)

  joined_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- A user can only be a member of the same project once
  UNIQUE (project_id, user_id)
);

-- Business rule: Total revenue_percentage across all members of a project ≤ 100%
-- Enforced via application layer + DB check function below

CREATE OR REPLACE FUNCTION check_total_revenue_percentage()
RETURNS TRIGGER AS $$
DECLARE
  total NUMERIC;
BEGIN
  SELECT COALESCE(SUM(revenue_percentage), 0)
  INTO total
  FROM project_members
  WHERE project_id = NEW.project_id
    AND id != NEW.id;  -- Exclude current row on UPDATE

  IF (total + COALESCE(NEW.revenue_percentage, 0)) > 100 THEN
    RAISE EXCEPTION 'Total revenue percentage for project exceeds 100%%. Current: %%, Attempted to add: %%',
      total, NEW.revenue_percentage;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_revenue_percentage_cap
  BEFORE INSERT OR UPDATE OF revenue_percentage ON project_members
  FOR EACH ROW EXECUTE FUNCTION check_total_revenue_percentage();

CREATE TRIGGER set_project_members_updated_at
  BEFORE UPDATE ON project_members
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
