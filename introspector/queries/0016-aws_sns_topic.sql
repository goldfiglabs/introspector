INSERT INTO aws_sns_topic (
  _id,
  uri,
  provider_account_id,
  topicarn,
  tags,
  deliverypolicy,
  displayname,
  owner,
  policy,
  subscriptionsconfirmed,
  subscriptionsdeleted,
  subscriptionspending,
  effectivedeliverypolicy,
  kmsmasterkeyid,
  _tags,
  _policy,
  _account_id
)
SELECT
  R.id AS _id,
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
  _tags.attr_value::jsonb AS _tags,
  _policy.attr_value::jsonb AS _policy,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS topicarn
    ON topicarn.resource_id = R.id
    AND topicarn.type = 'provider'
    AND lower(topicarn.attr_name) = 'topicarn'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS DeliveryPolicy
    ON DeliveryPolicy.resource_id = R.id
    AND DeliveryPolicy.type = 'provider'
    AND lower(DeliveryPolicy.attr_name) = 'deliverypolicy'
  LEFT JOIN resource_attribute AS DisplayName
    ON DisplayName.resource_id = R.id
    AND DisplayName.type = 'provider'
    AND lower(DisplayName.attr_name) = 'displayname'
  LEFT JOIN resource_attribute AS Owner
    ON Owner.resource_id = R.id
    AND Owner.type = 'provider'
    AND lower(Owner.attr_name) = 'owner'
  LEFT JOIN resource_attribute AS Policy
    ON Policy.resource_id = R.id
    AND Policy.type = 'provider'
    AND lower(Policy.attr_name) = 'policy'
  LEFT JOIN resource_attribute AS SubscriptionsConfirmed
    ON SubscriptionsConfirmed.resource_id = R.id
    AND SubscriptionsConfirmed.type = 'provider'
    AND lower(SubscriptionsConfirmed.attr_name) = 'subscriptionsconfirmed'
  LEFT JOIN resource_attribute AS SubscriptionsDeleted
    ON SubscriptionsDeleted.resource_id = R.id
    AND SubscriptionsDeleted.type = 'provider'
    AND lower(SubscriptionsDeleted.attr_name) = 'subscriptionsdeleted'
  LEFT JOIN resource_attribute AS SubscriptionsPending
    ON SubscriptionsPending.resource_id = R.id
    AND SubscriptionsPending.type = 'provider'
    AND lower(SubscriptionsPending.attr_name) = 'subscriptionspending'
  LEFT JOIN resource_attribute AS EffectiveDeliveryPolicy
    ON EffectiveDeliveryPolicy.resource_id = R.id
    AND EffectiveDeliveryPolicy.type = 'provider'
    AND lower(EffectiveDeliveryPolicy.attr_name) = 'effectivedeliverypolicy'
  LEFT JOIN resource_attribute AS KmsMasterKeyId
    ON KmsMasterKeyId.resource_id = R.id
    AND KmsMasterKeyId.type = 'provider'
    AND lower(KmsMasterKeyId.attr_name) = 'kmsmasterkeyid'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS _policy
    ON _policy.resource_id = R.id
    AND _policy.type = 'Metadata'
    AND lower(_policy.attr_name) = 'policy'
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
  AND R.provider_type = 'Topic'
  AND R.service = 'sns'
ON CONFLICT (_id) DO UPDATE
SET
    topicarn = EXCLUDED.topicarn,
    tags = EXCLUDED.tags,
    DeliveryPolicy = EXCLUDED.DeliveryPolicy,
    DisplayName = EXCLUDED.DisplayName,
    Owner = EXCLUDED.Owner,
    Policy = EXCLUDED.Policy,
    SubscriptionsConfirmed = EXCLUDED.SubscriptionsConfirmed,
    SubscriptionsDeleted = EXCLUDED.SubscriptionsDeleted,
    SubscriptionsPending = EXCLUDED.SubscriptionsPending,
    EffectiveDeliveryPolicy = EXCLUDED.EffectiveDeliveryPolicy,
    KmsMasterKeyId = EXCLUDED.KmsMasterKeyId,
    _tags = EXCLUDED._tags,
    _policy = EXCLUDED._policy,
    _account_id = EXCLUDED._account_id
  ;

