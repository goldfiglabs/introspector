DROP MATERIALIZED VIEW IF EXISTS aws_sns_topic CASCADE;

CREATE MATERIALIZED VIEW aws_sns_topic AS
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
  topicarn.attr_value #>> '{}' AS topicarn,
  tags.attr_value::jsonb AS tags,
  DeliveryPolicy.attr_value::jsonb AS deliverypolicy,
  DisplayName.attr_value #>> '{}' AS displayname,
  Owner.attr_value #>> '{}' AS owner,
  Policy.attr_value::jsonb AS policy,
  (SubscriptionsConfirmed.attr_value #>> '{}')::integer AS subscriptionsconfirmed,
  (SubscriptionsDeleted.attr_value #>> '{}')::integer AS subscriptionsdeleted,
  (SubscriptionsPending.attr_value #>> '{}')::integer AS subscriptionspending,
  EffectiveDeliveryPolicy.attr_value::jsonb AS effectivedeliverypolicy,
  KmsMasterKeyId.attr_value #>> '{}' AS kmsmasterkeyid,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS topicarn
    ON topicarn.id = R.id
    AND topicarn.attr_name = 'topicarn'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS DeliveryPolicy
    ON DeliveryPolicy.id = R.id
    AND DeliveryPolicy.attr_name = 'deliverypolicy'
  LEFT JOIN attrs AS DisplayName
    ON DisplayName.id = R.id
    AND DisplayName.attr_name = 'displayname'
  LEFT JOIN attrs AS Owner
    ON Owner.id = R.id
    AND Owner.attr_name = 'owner'
  LEFT JOIN attrs AS Policy
    ON Policy.id = R.id
    AND Policy.attr_name = 'policy'
  LEFT JOIN attrs AS SubscriptionsConfirmed
    ON SubscriptionsConfirmed.id = R.id
    AND SubscriptionsConfirmed.attr_name = 'subscriptionsconfirmed'
  LEFT JOIN attrs AS SubscriptionsDeleted
    ON SubscriptionsDeleted.id = R.id
    AND SubscriptionsDeleted.attr_name = 'subscriptionsdeleted'
  LEFT JOIN attrs AS SubscriptionsPending
    ON SubscriptionsPending.id = R.id
    AND SubscriptionsPending.attr_name = 'subscriptionspending'
  LEFT JOIN attrs AS EffectiveDeliveryPolicy
    ON EffectiveDeliveryPolicy.id = R.id
    AND EffectiveDeliveryPolicy.attr_name = 'effectivedeliverypolicy'
  LEFT JOIN attrs AS KmsMasterKeyId
    ON KmsMasterKeyId.id = R.id
    AND KmsMasterKeyId.attr_name = 'kmsmasterkeyid'
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
  AND LOWER(R.provider_type) = 'topic'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_sns_topic;

COMMENT ON MATERIALIZED VIEW aws_sns_topic IS 'sns topic resources and their associated attributes.';

