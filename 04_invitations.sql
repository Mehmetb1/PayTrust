CREATE TABLE invitations (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id      UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  
  -- Who sent it (must be the project employer)
  inviter_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Who receives it (looked up by username at invite time)
  invitee_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  status          invitation_status NOT NULL DEFAULT 'pending',
  
  -- Optional personal message from employer
  message         TEXT CHECK (char_length(message) <= 500),

  responded_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Prevent duplicate active invitations for same project/user
  UNIQUE (project_id, invitee_id)
);

CREATE TRIGGER set_invitations_updated_at
  BEFORE UPDATE ON invitations
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
