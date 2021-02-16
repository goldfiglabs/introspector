-- migrate:up

CREATE TABLE IF NOT EXISTS aws_ses_identity (
  _id INTEGER NOT NULL PRIMARY KEY,
  uri TEXT NOT NULL,
  provider_account_id INTEGER NOT NULL,dkimenabled BOOLEAN,
  dkimverificationstatus TEXT,
  dkimtokens JSONB,
  mailfromdomain TEXT,
  mailfromdomainstatus TEXT,
  behavioronmxfailure TEXT,
  bouncetopic TEXT,
  complainttopic TEXT,
  deliverytopic TEXT,
  forwardingenabled BOOLEAN,
  headersinbouncenotificationsenabled BOOLEAN,
  headersincomplaintnotificationsenabled BOOLEAN,
  headersindeliverynotificationsenabled BOOLEAN,
  policies JSONB,
  verificationstatus TEXT,
  verificationtoken TEXT,
  _bouncetopic_id INTEGER,
    FOREIGN KEY (_bouncetopic_id) REFERENCES aws_sns_topic (_id) ON DELETE SET NULL,
  _complainttopic_id INTEGER,
    FOREIGN KEY (_complainttopic_id) REFERENCES aws_sns_topic (_id) ON DELETE SET NULL,
  _deliverytopic_id INTEGER,
    FOREIGN KEY (_deliverytopic_id) REFERENCES aws_sns_topic (_id) ON DELETE SET NULL,
  _account_id INTEGER,
    FOREIGN KEY (_account_id) REFERENCES aws_organizations_account (_id) ON DELETE SET NULL,
  FOREIGN KEY (provider_account_id) REFERENCES public.provider_account (id) ON DELETE CASCADE,
  FOREIGN KEY (_id) REFERENCES public.resource (id) ON DELETE CASCADE
);

COMMENT ON TABLE aws_ses_identity IS 'ses Identity resources and their associated attributes.';

ALTER TABLE aws_ses_identity ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_aws_ses_identity ON aws_ses_identity
USING (
  current_user = 'introspector_ro'
  OR
  provider_account_id = current_setting('introspector.provider_account_id', true)::int
);

