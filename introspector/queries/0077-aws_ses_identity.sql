WITH attrs AS (
  SELECT
    resource_id,
    jsonb_object_agg(attr_name, attr_value) FILTER (WHERE type = 'provider') AS provider,
    jsonb_object_agg(attr_name, attr_value) FILTER (WHERE type = 'Metadata') AS metadata
  FROM
    resource_attribute
  WHERE
    provider_account_id = :provider_account_id
  GROUP BY resource_id
)
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
  (attrs.provider ->> 'DkimEnabled')::boolean AS dkimenabled,
  attrs.provider ->> 'DkimVerificationStatus' AS dkimverificationstatus,
  attrs.provider -> 'DkimTokens' AS dkimtokens,
  attrs.provider ->> 'MailFromDomain' AS mailfromdomain,
  attrs.provider ->> 'MailFromDomainStatus' AS mailfromdomainstatus,
  attrs.provider ->> 'BehaviorOnMXFailure' AS behavioronmxfailure,
  attrs.provider ->> 'BounceTopic' AS bouncetopic,
  attrs.provider ->> 'ComplaintTopic' AS complainttopic,
  attrs.provider ->> 'DeliveryTopic' AS deliverytopic,
  (attrs.provider ->> 'ForwardingEnabled')::boolean AS forwardingenabled,
  (attrs.provider ->> 'HeadersInBounceNotificationsEnabled')::boolean AS headersinbouncenotificationsenabled,
  (attrs.provider ->> 'HeadersInComplaintNotificationsEnabled')::boolean AS headersincomplaintnotificationsenabled,
  (attrs.provider ->> 'HeadersInDeliveryNotificationsEnabled')::boolean AS headersindeliverynotificationsenabled,
  attrs.provider -> 'Policies' AS policies,
  attrs.provider ->> 'VerificationStatus' AS verificationstatus,
  attrs.provider ->> 'VerificationToken' AS verificationtoken,
  attrs.metadata -> 'Policy' AS policy,
  
    _bouncetopic_id.target_id AS _bouncetopic_id,
    _complainttopic_id.target_id AS _complainttopic_id,
    _deliverytopic_id.target_id AS _deliverytopic_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
        AND _aws_sns_topic.provider_account_id = :provider_account_id
    WHERE
      _aws_sns_topic_relation.relation = 'publishes-to'
      AND _aws_sns_topic_relation.provider_account_id = :provider_account_id
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
        AND _aws_sns_topic.provider_account_id = :provider_account_id
    WHERE
      _aws_sns_topic_relation.relation = 'publishes-to'
      AND _aws_sns_topic_relation.provider_account_id = :provider_account_id
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
        AND _aws_sns_topic.provider_account_id = :provider_account_id
    WHERE
      _aws_sns_topic_relation.relation = 'publishes-to'
      AND _aws_sns_topic_relation.provider_account_id = :provider_account_id
  ) AS _deliverytopic_id ON _deliverytopic_id.resource_id = R.id
  LEFT JOIN (
    SELECT
      unique_account_mapping.resource_id,
      unique_account_mapping.target_ids[1] as target_id
    FROM
      (
        SELECT
          ARRAY_AGG(_aws_organizations_account_relation.target_id) AS target_ids,
          _aws_organizations_account_relation.resource_id
        FROM
          resource AS _aws_organizations_account
          INNER JOIN resource_relation AS _aws_organizations_account_relation
            ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
        WHERE
          _aws_organizations_account.provider_type = 'Account'
          AND _aws_organizations_account.service = 'organizations'
          AND _aws_organizations_account.provider_account_id = :provider_account_id
          AND _aws_organizations_account_relation.relation = 'in'
          AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'Identity'
  AND R.service = 'ses'
ON CONFLICT (_id) DO UPDATE
SET
    DkimEnabled = EXCLUDED.DkimEnabled,
    DkimVerificationStatus = EXCLUDED.DkimVerificationStatus,
    DkimTokens = EXCLUDED.DkimTokens,
    MailFromDomain = EXCLUDED.MailFromDomain,
    MailFromDomainStatus = EXCLUDED.MailFromDomainStatus,
    BehaviorOnMXFailure = EXCLUDED.BehaviorOnMXFailure,
    BounceTopic = EXCLUDED.BounceTopic,
    ComplaintTopic = EXCLUDED.ComplaintTopic,
    DeliveryTopic = EXCLUDED.DeliveryTopic,
    ForwardingEnabled = EXCLUDED.ForwardingEnabled,
    HeadersInBounceNotificationsEnabled = EXCLUDED.HeadersInBounceNotificationsEnabled,
    HeadersInComplaintNotificationsEnabled = EXCLUDED.HeadersInComplaintNotificationsEnabled,
    HeadersInDeliveryNotificationsEnabled = EXCLUDED.HeadersInDeliveryNotificationsEnabled,
    Policies = EXCLUDED.Policies,
    VerificationStatus = EXCLUDED.VerificationStatus,
    VerificationToken = EXCLUDED.VerificationToken,
    _policy = EXCLUDED._policy,
    _bouncetopic_id = EXCLUDED._bouncetopic_id,
    _complainttopic_id = EXCLUDED._complainttopic_id,
    _deliverytopic_id = EXCLUDED._deliverytopic_id,
    _account_id = EXCLUDED._account_id
  ;

