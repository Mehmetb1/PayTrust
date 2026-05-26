-- ─────────────────────────────────────────────
-- PERFORMANCE INDEXES
-- ─────────────────────────────────────────────

-- Users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_stripe_account ON users(stripe_account_id) WHERE stripe_account_id IS NOT NULL;

-- Projects
CREATE INDEX idx_projects_employer ON projects(employer_id);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_stripe_intent ON projects(stripe_payment_intent_id) WHERE stripe_payment_intent_id IS NOT NULL;

-- Project Members
CREATE INDEX idx_project_members_project ON project_members(project_id);
CREATE INDEX idx_project_members_user ON project_members(user_id);

-- Invitations
CREATE INDEX idx_invitations_project ON invitations(project_id);
CREATE INDEX idx_invitations_invitee ON invitations(invitee_id);
CREATE INDEX idx_invitations_status ON invitations(status) WHERE status = 'pending';

-- Escrow Transactions
CREATE INDEX idx_escrow_project ON escrow_transactions(project_id);
CREATE INDEX idx_escrow_stripe_intent ON escrow_transactions(stripe_payment_intent_id);
CREATE INDEX idx_escrow_type_status ON escrow_transactions(transaction_type, status);

-- Payouts
CREATE INDEX idx_payouts_project ON payouts(project_id);
CREATE INDEX idx_payouts_recipient ON payouts(recipient_user_id);
CREATE INDEX idx_payouts_status ON payouts(status) WHERE status IN ('queued', 'processing');

-- Notifications
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);

-- OTP Tokens
CREATE INDEX idx_otp_user_purpose ON otp_tokens(user_id, purpose) WHERE is_used = FALSE;
CREATE INDEX idx_otp_expires ON otp_tokens(expires_at) WHERE is_used = FALSE;


-- ─────────────────────────────────────────────
-- ROW-LEVEL SECURITY (Supabase-ready)
-- ─────────────────────────────────────────────

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE escrow_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE otp_tokens ENABLE ROW LEVEL SECURITY;

-- Users: can only see/edit their own record
CREATE POLICY "users_select_own" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "users_update_own" ON users FOR UPDATE USING (auth.uid() = id);

-- Projects: visible to employer + accepted members
CREATE POLICY "projects_select" ON projects FOR SELECT USING (
  auth.uid() = employer_id OR
  auth.uid() IN (
    SELECT user_id FROM project_members WHERE project_id = id
  )
);
CREATE POLICY "projects_insert_employer" ON projects FOR INSERT WITH CHECK (auth.uid() = employer_id);
CREATE POLICY "projects_update_employer" ON projects FOR UPDATE USING (auth.uid() = employer_id);

-- Project Members: visible to employer + the member themselves
CREATE POLICY "project_members_select" ON project_members FOR SELECT USING (
  auth.uid() = user_id OR
  auth.uid() IN (SELECT employer_id FROM projects WHERE id = project_id)
);

-- Invitations: visible to inviter and invitee
CREATE POLICY "invitations_select" ON invitations FOR SELECT USING (
  auth.uid() = inviter_id OR auth.uid() = invitee_id
);
CREATE POLICY "invitations_insert_employer" ON invitations FOR INSERT WITH CHECK (
  auth.uid() = inviter_id
);
CREATE POLICY "invitations_update_invitee" ON invitations FOR UPDATE USING (
  auth.uid() = invitee_id  -- Only invitee can accept/decline
);

-- Notifications: strictly private
CREATE POLICY "notifications_own" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "notifications_update_own" ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- OTP Tokens: strictly private
CREATE POLICY "otp_own" ON otp_tokens FOR SELECT USING (auth.uid() = user_id);

-- Escrow & Payouts: only parties involved + server-side service role
CREATE POLICY "escrow_select" ON escrow_transactions FOR SELECT USING (
  auth.uid() = from_user_id OR auth.uid() = to_user_id OR
  auth.uid() IN (SELECT employer_id FROM projects WHERE id = project_id)
);
CREATE POLICY "payouts_select" ON payouts FOR SELECT USING (
  auth.uid() = recipient_user_id OR
  auth.uid() IN (SELECT employer_id FROM projects WHERE id = project_id)
);
