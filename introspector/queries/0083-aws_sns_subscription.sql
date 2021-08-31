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
INSERT INTO aws_sns_subscription (
  _id,
  uri,
  provider_account_id,
  subscriptionarn,
  owner,
  protocol,
  endpoint,
  topicarn,
  confirmationwasauthenticated,
  deliverypolicy,
  effectivedeliverypolicy,
  filterpolicy,
  pendingconfirmation,
  rawmessagedelivery,
  redrivepolicy,
  _topic_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'SubscriptionArn' AS subscriptionarn,
  attrs.provider ->> 'Owner' AS owner,
  attrs.provider ->> 'Protocol' AS protocol,
  attrs.provider ->> 'Endpoint' AS endpoint,
  attrs.provider ->> 'TopicArn' AS topicarn,
  (attrs.provider ->> 'ConfirmationWasAuthenticated')::boolean AS confirmationwasauthenticated,
  attrs.provider -> 'DeliveryPolicy' AS deliverypolicy,
  attrs.provider -> 'EffectiveDeliveryPolicy' AS effectivedeliverypolicy,
  attrs.provider -> 'FilterPolicy' AS filterpolicy,
  (attrs.provider ->> 'PendingConfirmation')::boolean AS pendingconfirmation,
  (attrs.provider ->> 'RawMessageDelivery')::boolean AS rawmessagedelivery,
  attrs.provider -> 'RedrivePolicy' AS redrivepolicy,
  
    _topic_id.target_id AS _topic_id,
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
      _aws_sns_topic_relation.relation = 'subscribes-to'
      AND _aws_sns_topic_relation.provider_account_id = :provider_account_id
  ) AS _topic_id ON _topic_id.resource_id = R.id
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
  AND R.provider_type = 'Subscription'
  AND R.service = 'sns'
ON CONFLICT (_id) DO UPDATE
SET
    SubscriptionArn = EXCLUDED.SubscriptionArn,
    Owner = EXCLUDED.Owner,
    Protocol = EXCLUDED.Protocol,
    Endpoint = EXCLUDED.Endpoint,
    TopicArn = EXCLUDED.TopicArn,
    ConfirmationWasAuthenticated = EXCLUDED.ConfirmationWasAuthenticated,
    DeliveryPolicy = EXCLUDED.DeliveryPolicy,
    EffectiveDeliveryPolicy = EXCLUDED.EffectiveDeliveryPolicy,
    FilterPolicy = EXCLUDED.FilterPolicy,
    PendingConfirmation = EXCLUDED.PendingConfirmation,
    RawMessageDelivery = EXCLUDED.RawMessageDelivery,
    RedrivePolicy = EXCLUDED.RedrivePolicy,
    _topic_id = EXCLUDED._topic_id,
    _account_id = EXCLUDED._account_id
  ;

