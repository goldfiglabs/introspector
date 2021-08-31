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
  attrs.provider ->> 'TopicArn' AS topicarn,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider -> 'DeliveryPolicy' AS deliverypolicy,
  attrs.provider ->> 'DisplayName' AS displayname,
  attrs.provider ->> 'Owner' AS owner,
  attrs.provider -> 'Policy' AS policy,
  (attrs.provider ->> 'SubscriptionsConfirmed')::integer AS subscriptionsconfirmed,
  (attrs.provider ->> 'SubscriptionsDeleted')::integer AS subscriptionsdeleted,
  (attrs.provider ->> 'SubscriptionsPending')::integer AS subscriptionspending,
  attrs.provider -> 'EffectiveDeliveryPolicy' AS effectivedeliverypolicy,
  attrs.provider ->> 'KmsMasterKeyId' AS kmsmasterkeyid,
  attrs.metadata -> 'Tags' AS tags,
  attrs.metadata -> 'Policy' AS policy,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
  AND R.provider_type = 'Topic'
  AND R.service = 'sns'
ON CONFLICT (_id) DO UPDATE
SET
    TopicArn = EXCLUDED.TopicArn,
    Tags = EXCLUDED.Tags,
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

