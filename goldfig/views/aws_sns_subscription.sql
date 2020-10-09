DROP MATERIALIZED VIEW IF EXISTS aws_sns_subscription CASCADE;

CREATE MATERIALIZED VIEW aws_sns_subscription AS
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
  LEFT JOIN resource_attribute AS subscriptionarn
    ON subscriptionarn.resource_id = R.id
    AND subscriptionarn.type = 'provider'
    AND lower(subscriptionarn.attr_name) = 'subscriptionarn'
  LEFT JOIN resource_attribute AS owner
    ON owner.resource_id = R.id
    AND owner.type = 'provider'
    AND lower(owner.attr_name) = 'owner'
  LEFT JOIN resource_attribute AS protocol
    ON protocol.resource_id = R.id
    AND protocol.type = 'provider'
    AND lower(protocol.attr_name) = 'protocol'
  LEFT JOIN resource_attribute AS endpoint
    ON endpoint.resource_id = R.id
    AND endpoint.type = 'provider'
    AND lower(endpoint.attr_name) = 'endpoint'
  LEFT JOIN resource_attribute AS topicarn
    ON topicarn.resource_id = R.id
    AND topicarn.type = 'provider'
    AND lower(topicarn.attr_name) = 'topicarn'
  LEFT JOIN resource_attribute AS ConfirmationWasAuthenticated
    ON ConfirmationWasAuthenticated.resource_id = R.id
    AND ConfirmationWasAuthenticated.type = 'provider'
    AND lower(ConfirmationWasAuthenticated.attr_name) = 'confirmationwasauthenticated'
  LEFT JOIN resource_attribute AS DeliveryPolicy
    ON DeliveryPolicy.resource_id = R.id
    AND DeliveryPolicy.type = 'provider'
    AND lower(DeliveryPolicy.attr_name) = 'deliverypolicy'
  LEFT JOIN resource_attribute AS EffectiveDeliveryPolicy
    ON EffectiveDeliveryPolicy.resource_id = R.id
    AND EffectiveDeliveryPolicy.type = 'provider'
    AND lower(EffectiveDeliveryPolicy.attr_name) = 'effectivedeliverypolicy'
  LEFT JOIN resource_attribute AS FilterPolicy
    ON FilterPolicy.resource_id = R.id
    AND FilterPolicy.type = 'provider'
    AND lower(FilterPolicy.attr_name) = 'filterpolicy'
  LEFT JOIN resource_attribute AS PendingConfirmation
    ON PendingConfirmation.resource_id = R.id
    AND PendingConfirmation.type = 'provider'
    AND lower(PendingConfirmation.attr_name) = 'pendingconfirmation'
  LEFT JOIN resource_attribute AS RawMessageDelivery
    ON RawMessageDelivery.resource_id = R.id
    AND RawMessageDelivery.type = 'provider'
    AND lower(RawMessageDelivery.attr_name) = 'rawmessagedelivery'
  LEFT JOIN resource_attribute AS RedrivePolicy
    ON RedrivePolicy.resource_id = R.id
    AND RedrivePolicy.type = 'provider'
    AND lower(RedrivePolicy.attr_name) = 'redrivepolicy'
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
  AND R.service = 'sns'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_sns_subscription;

COMMENT ON MATERIALIZED VIEW aws_sns_subscription IS 'sns subscription resources and their associated attributes.';

