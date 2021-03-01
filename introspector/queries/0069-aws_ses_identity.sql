INSERT INTO aws_ses_identity (
  _id,
  uri,
  provider_account_id,
  dkimenabled,
  dkimverificationstatus,
  dkimtokens,
  mailfromdomain,
  mailfromdomainstatus,
  behavioronmxfailure,
  bouncetopic,
  complainttopic,
  deliverytopic,
  forwardingenabled,
  headersinbouncenotificationsenabled,
  headersincomplaintnotificationsenabled,
  headersindeliverynotificationsenabled,
  policies,
  verificationstatus,
  verificationtoken,
  _policy,
  _bouncetopic_id,_complainttopic_id,_deliverytopic_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  (dkimenabled.attr_value #>> '{}')::boolean AS dkimenabled,
  dkimverificationstatus.attr_value #>> '{}' AS dkimverificationstatus,
  dkimtokens.attr_value::jsonb AS dkimtokens,
  mailfromdomain.attr_value #>> '{}' AS mailfromdomain,
  mailfromdomainstatus.attr_value #>> '{}' AS mailfromdomainstatus,
  behavioronmxfailure.attr_value #>> '{}' AS behavioronmxfailure,
  bouncetopic.attr_value #>> '{}' AS bouncetopic,
  complainttopic.attr_value #>> '{}' AS complainttopic,
  deliverytopic.attr_value #>> '{}' AS deliverytopic,
  (forwardingenabled.attr_value #>> '{}')::boolean AS forwardingenabled,
  (headersinbouncenotificationsenabled.attr_value #>> '{}')::boolean AS headersinbouncenotificationsenabled,
  (headersincomplaintnotificationsenabled.attr_value #>> '{}')::boolean AS headersincomplaintnotificationsenabled,
  (headersindeliverynotificationsenabled.attr_value #>> '{}')::boolean AS headersindeliverynotificationsenabled,
  policies.attr_value::jsonb AS policies,
  verificationstatus.attr_value #>> '{}' AS verificationstatus,
  verificationtoken.attr_value #>> '{}' AS verificationtoken,
  _policy.attr_value::jsonb AS _policy,
  
    _bouncetopic_id.target_id AS _bouncetopic_id,
    _complainttopic_id.target_id AS _complainttopic_id,
    _deliverytopic_id.target_id AS _deliverytopic_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS dkimenabled
    ON dkimenabled.resource_id = R.id
    AND dkimenabled.type = 'provider'
    AND lower(dkimenabled.attr_name) = 'dkimenabled'
  LEFT JOIN resource_attribute AS dkimverificationstatus
    ON dkimverificationstatus.resource_id = R.id
    AND dkimverificationstatus.type = 'provider'
    AND lower(dkimverificationstatus.attr_name) = 'dkimverificationstatus'
  LEFT JOIN resource_attribute AS dkimtokens
    ON dkimtokens.resource_id = R.id
    AND dkimtokens.type = 'provider'
    AND lower(dkimtokens.attr_name) = 'dkimtokens'
  LEFT JOIN resource_attribute AS mailfromdomain
    ON mailfromdomain.resource_id = R.id
    AND mailfromdomain.type = 'provider'
    AND lower(mailfromdomain.attr_name) = 'mailfromdomain'
  LEFT JOIN resource_attribute AS mailfromdomainstatus
    ON mailfromdomainstatus.resource_id = R.id
    AND mailfromdomainstatus.type = 'provider'
    AND lower(mailfromdomainstatus.attr_name) = 'mailfromdomainstatus'
  LEFT JOIN resource_attribute AS behavioronmxfailure
    ON behavioronmxfailure.resource_id = R.id
    AND behavioronmxfailure.type = 'provider'
    AND lower(behavioronmxfailure.attr_name) = 'behavioronmxfailure'
  LEFT JOIN resource_attribute AS bouncetopic
    ON bouncetopic.resource_id = R.id
    AND bouncetopic.type = 'provider'
    AND lower(bouncetopic.attr_name) = 'bouncetopic'
  LEFT JOIN resource_attribute AS complainttopic
    ON complainttopic.resource_id = R.id
    AND complainttopic.type = 'provider'
    AND lower(complainttopic.attr_name) = 'complainttopic'
  LEFT JOIN resource_attribute AS deliverytopic
    ON deliverytopic.resource_id = R.id
    AND deliverytopic.type = 'provider'
    AND lower(deliverytopic.attr_name) = 'deliverytopic'
  LEFT JOIN resource_attribute AS forwardingenabled
    ON forwardingenabled.resource_id = R.id
    AND forwardingenabled.type = 'provider'
    AND lower(forwardingenabled.attr_name) = 'forwardingenabled'
  LEFT JOIN resource_attribute AS headersinbouncenotificationsenabled
    ON headersinbouncenotificationsenabled.resource_id = R.id
    AND headersinbouncenotificationsenabled.type = 'provider'
    AND lower(headersinbouncenotificationsenabled.attr_name) = 'headersinbouncenotificationsenabled'
  LEFT JOIN resource_attribute AS headersincomplaintnotificationsenabled
    ON headersincomplaintnotificationsenabled.resource_id = R.id
    AND headersincomplaintnotificationsenabled.type = 'provider'
    AND lower(headersincomplaintnotificationsenabled.attr_name) = 'headersincomplaintnotificationsenabled'
  LEFT JOIN resource_attribute AS headersindeliverynotificationsenabled
    ON headersindeliverynotificationsenabled.resource_id = R.id
    AND headersindeliverynotificationsenabled.type = 'provider'
    AND lower(headersindeliverynotificationsenabled.attr_name) = 'headersindeliverynotificationsenabled'
  LEFT JOIN resource_attribute AS policies
    ON policies.resource_id = R.id
    AND policies.type = 'provider'
    AND lower(policies.attr_name) = 'policies'
  LEFT JOIN resource_attribute AS verificationstatus
    ON verificationstatus.resource_id = R.id
    AND verificationstatus.type = 'provider'
    AND lower(verificationstatus.attr_name) = 'verificationstatus'
  LEFT JOIN resource_attribute AS verificationtoken
    ON verificationtoken.resource_id = R.id
    AND verificationtoken.type = 'provider'
    AND lower(verificationtoken.attr_name) = 'verificationtoken'
  LEFT JOIN resource_attribute AS _policy
    ON _policy.resource_id = R.id
    AND _policy.type = 'Metadata'
    AND lower(_policy.attr_name) = 'policy'
  LEFT JOIN (
    SELECT
      _aws_sns_topic_relation.resource_id AS resource_id,
      _aws_sns_topic.id AS target_id
    FROM
      resource_relation AS _aws_sns_topic_relation
      INNER JOIN resource AS _aws_sns_topic
        ON _aws_sns_topic_relation.target_id = _aws_sns_topic.id
        AND _aws_sns_topic.provider_type = 'Topic'
        AND _aws_sns_topic.service = 'sns'
    WHERE
      _aws_sns_topic_relation.relation = 'publishes-to'
  ) AS _bouncetopic_id ON _bouncetopic_id.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_sns_topic_relation.resource_id AS resource_id,
      _aws_sns_topic.id AS target_id
    FROM
      resource_relation AS _aws_sns_topic_relation
      INNER JOIN resource AS _aws_sns_topic
        ON _aws_sns_topic_relation.target_id = _aws_sns_topic.id
        AND _aws_sns_topic.provider_type = 'Topic'
        AND _aws_sns_topic.service = 'sns'
    WHERE
      _aws_sns_topic_relation.relation = 'publishes-to'
  ) AS _complainttopic_id ON _complainttopic_id.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_sns_topic_relation.resource_id AS resource_id,
      _aws_sns_topic.id AS target_id
    FROM
      resource_relation AS _aws_sns_topic_relation
      INNER JOIN resource AS _aws_sns_topic
        ON _aws_sns_topic_relation.target_id = _aws_sns_topic.id
        AND _aws_sns_topic.provider_type = 'Topic'
        AND _aws_sns_topic.service = 'sns'
    WHERE
      _aws_sns_topic_relation.relation = 'publishes-to'
  ) AS _deliverytopic_id ON _deliverytopic_id.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_organizations_account_relation.resource_id AS resource_id,
      _aws_organizations_account.id AS target_id
    FROM
    (
      SELECT
        _aws_organizations_account_relation.resource_id AS resource_id
      FROM
        resource_relation AS _aws_organizations_account_relation
        INNER JOIN resource AS _aws_organizations_account
          ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
          AND _aws_organizations_account.provider_type = 'Account'
          AND _aws_organizations_account.service = 'organizations'
      WHERE
        _aws_organizations_account_relation.relation = 'in'
      GROUP BY _aws_organizations_account_relation.resource_id
      HAVING COUNT(*) = 1
    ) AS unique_account_mapping
    INNER JOIN resource_relation AS _aws_organizations_account_relation
      ON _aws_organizations_account_relation.resource_id = unique_account_mapping.resource_id
    INNER JOIN resource AS _aws_organizations_account
      ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
      AND _aws_organizations_account.provider_type = 'Account'
      AND _aws_organizations_account.service = 'organizations'
    WHERE
        _aws_organizations_account_relation.relation = 'in'
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  PA.provider = 'aws'
  AND R.provider_type = 'Identity'
  AND R.service = 'ses'
ON CONFLICT (_id) DO UPDATE
SET
    dkimenabled = EXCLUDED.dkimenabled,
    dkimverificationstatus = EXCLUDED.dkimverificationstatus,
    dkimtokens = EXCLUDED.dkimtokens,
    mailfromdomain = EXCLUDED.mailfromdomain,
    mailfromdomainstatus = EXCLUDED.mailfromdomainstatus,
    behavioronmxfailure = EXCLUDED.behavioronmxfailure,
    bouncetopic = EXCLUDED.bouncetopic,
    complainttopic = EXCLUDED.complainttopic,
    deliverytopic = EXCLUDED.deliverytopic,
    forwardingenabled = EXCLUDED.forwardingenabled,
    headersinbouncenotificationsenabled = EXCLUDED.headersinbouncenotificationsenabled,
    headersincomplaintnotificationsenabled = EXCLUDED.headersincomplaintnotificationsenabled,
    headersindeliverynotificationsenabled = EXCLUDED.headersindeliverynotificationsenabled,
    policies = EXCLUDED.policies,
    verificationstatus = EXCLUDED.verificationstatus,
    verificationtoken = EXCLUDED.verificationtoken,
    _policy = EXCLUDED._policy,
    _bouncetopic_id = EXCLUDED._bouncetopic_id,
    _complainttopic_id = EXCLUDED._complainttopic_id,
    _deliverytopic_id = EXCLUDED._deliverytopic_id,
    _account_id = EXCLUDED._account_id
  ;

