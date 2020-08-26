DROP MATERIALIZED VIEW IF EXISTS aws_sns_subscription CASCADE;

CREATE MATERIALIZED VIEW aws_sns_subscription AS
WITH attrs AS (
  SELECT
    R.id,
    LOWER(RA.attr_name) AS attr_name,
    RA.attr_value
  FROM
    resource AS R
    INNER JOIN resource_attribute AS RA
      ON RA.resource_id = R.id
  WHERE
    RA.type = 'provider'
)
SELECT
  R.id AS resource_id,
  R.uri,
  R.provider_account_id,
  subscriptionarn.attr_value #>> '{}' AS subscriptionarn,
  owner.attr_value #>> '{}' AS owner,
  protocol.attr_value #>> '{}' AS protocol,
  endpoint.attr_value #>> '{}' AS endpoint,
  topicarn.attr_value #>> '{}' AS topicarn,
  (ConfirmationWasAuthenticated.attr_value #>> '{}')::boolean AS confirmationwasauthenticated,
  DeliveryPolicy.attr_value::jsonb AS deliverypolicy,
  EffectiveDeliveryPolicy.attr_value::jsonb AS effectivedeliverypolicy,
  FilterPolicy.attr_value::jsonb AS filterpolicy,
  (PendingConfirmation.attr_value #>> '{}')::boolean AS pendingconfirmation,
  (RawMessageDelivery.attr_value #>> '{}')::boolean AS rawmessagedelivery,
  RedrivePolicy.attr_value::jsonb AS redrivepolicy,
  
    _topic_id.target_id AS _topic_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS subscriptionarn
    ON subscriptionarn.id = R.id
    AND subscriptionarn.attr_name = 'subscriptionarn'
  LEFT JOIN attrs AS owner
    ON owner.id = R.id
    AND owner.attr_name = 'owner'
  LEFT JOIN attrs AS protocol
    ON protocol.id = R.id
    AND protocol.attr_name = 'protocol'
  LEFT JOIN attrs AS endpoint
    ON endpoint.id = R.id
    AND endpoint.attr_name = 'endpoint'
  LEFT JOIN attrs AS topicarn
    ON topicarn.id = R.id
    AND topicarn.attr_name = 'topicarn'
  LEFT JOIN attrs AS ConfirmationWasAuthenticated
    ON ConfirmationWasAuthenticated.id = R.id
    AND ConfirmationWasAuthenticated.attr_name = 'confirmationwasauthenticated'
  LEFT JOIN attrs AS DeliveryPolicy
    ON DeliveryPolicy.id = R.id
    AND DeliveryPolicy.attr_name = 'deliverypolicy'
  LEFT JOIN attrs AS EffectiveDeliveryPolicy
    ON EffectiveDeliveryPolicy.id = R.id
    AND EffectiveDeliveryPolicy.attr_name = 'effectivedeliverypolicy'
  LEFT JOIN attrs AS FilterPolicy
    ON FilterPolicy.id = R.id
    AND FilterPolicy.attr_name = 'filterpolicy'
  LEFT JOIN attrs AS PendingConfirmation
    ON PendingConfirmation.id = R.id
    AND PendingConfirmation.attr_name = 'pendingconfirmation'
  LEFT JOIN attrs AS RawMessageDelivery
    ON RawMessageDelivery.id = R.id
    AND RawMessageDelivery.attr_name = 'rawmessagedelivery'
  LEFT JOIN attrs AS RedrivePolicy
    ON RedrivePolicy.id = R.id
    AND RedrivePolicy.attr_name = 'redrivepolicy'
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
      _aws_sns_topic_relation.relation = 'subscribes-to'
  ) AS _topic_id ON _topic_id.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_organizations_account_relation.resource_id AS resource_id,
      _aws_organizations_account.id AS target_id
    FROM
      resource_relation AS _aws_organizations_account_relation
      INNER JOIN resource AS _aws_organizations_account
        ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
        AND _aws_organizations_account.provider_type = 'Account'
        AND _aws_organizations_account.service = 'organizations'
    WHERE
      _aws_organizations_account_relation.relation = 'in'
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  PA.provider = 'aws'
  AND LOWER(R.provider_type) = 'subscription'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_sns_subscription;

COMMENT ON MATERIALIZED VIEW aws_sns_subscription IS 'sns subscription resources and their associated attributes.';

