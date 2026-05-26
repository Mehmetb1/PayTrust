-- Project lifecycle state machine
CREATE TYPE project_status AS ENUM (
  'draft',          -- Created, not yet funded
  'funded',         -- Escrow deposit confirmed
  'active',         -- Work in progress
  'pending_review', -- Employer marked complete, awaiting freelancer confirmation
  'completed',      -- Both parties confirmed — triggers payout
  'disputed',       -- Flagged for manual review
  'cancelled'       -- Refunded, closed
);

-- Invitation workflow states
CREATE TYPE invitation_status AS ENUM (
  'pending',
  'accepted',
  'declined',
  'revoked'
);

-- Financial transaction types
CREATE TYPE transaction_type AS ENUM (
  'escrow_deposit',       -- Employer funds the project
  'payout_freelancer',    -- Individual freelancer receives their cut
  'commission_platform',  -- 5% platform fee captured
  'refund_employer'       -- Project cancelled, employer refunded
);

-- Transaction settlement states
CREATE TYPE transaction_status AS ENUM (
  'pending',
  'processing',
  'succeeded',
  'failed',
  'refunded'
);

-- Notification types
CREATE TYPE notification_type AS ENUM (
  'project_invitation',
  'invitation_accepted',
  'invitation_declined',
  'project_funded',
  'project_completed',
  'payout_initiated',
  'payout_succeeded',
  'payout_failed',
  'project_disputed'
);

-- User account status
CREATE TYPE account_status AS ENUM (
  'pending_verification', -- OTP not confirmed yet
  'active',
  'suspended'
);

-- Payout status
CREATE TYPE payout_status AS ENUM (
  'queued',
  'processing',
  'paid',
  'failed'
);
