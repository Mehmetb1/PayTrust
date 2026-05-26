CREATE TABLE notifications (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  type            notification_type NOT NULL,
  title_key       TEXT NOT NULL,   -- i18n translation key e.g. "notifications.project_invitation"
  body_key        TEXT NOT NULL,   -- i18n translation key
  
  -- Dynamic values to interpolate into translated strings
  -- e.g. { "projectTitle": "My App", "inviterName": "john_doe" }
  metadata        JSONB NOT NULL DEFAULT '{}',

  -- Reference to the source entity (polymorphic link)
  related_project_id    UUID REFERENCES projects(id) ON DELETE SET NULL,
  related_invitation_id UUID REFERENCES invitations(id) ON DELETE SET NULL,
  related_payout_id     UUID REFERENCES payouts(id) ON DELETE SET NULL,

  is_read         BOOLEAN NOT NULL DEFAULT FALSE,
  read_at         TIMESTAMPTZ,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
