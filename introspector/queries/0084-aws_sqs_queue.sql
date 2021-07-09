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
INSERT INTO aws_sqs_queue (
  _id,
  uri,
  provider_account_id,
  receivemessagewaittimeseconds,
  visibilitytimeout,
  approximatenumberofmessages,
  approximatenumberofmessagesnotvisible,
  approximatenumberofmessagesdelayed,
  delayseconds,
  createdtimestamp,
  lastmodifiedtimestamp,
  queuearn,
  maximummessagesize,
  messageretentionperiod,
  url,
  tags,
  policy,
  redrivepolicy,
  fifoqueue,
  contentbaseddeduplication,
  kmsmasterkeyid,
  kmsdatakeyreuseperiodsecond,
  _tags,
  _policy,
  _kms_key_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  (attrs.provider ->> 'ReceiveMessageWaitTimeSeconds')::integer AS receivemessagewaittimeseconds,
  (attrs.provider ->> 'VisibilityTimeout')::integer AS visibilitytimeout,
  (attrs.provider ->> 'ApproximateNumberOfMessages')::integer AS approximatenumberofmessages,
  (attrs.provider ->> 'ApproximateNumberOfMessagesNotVisible')::integer AS approximatenumberofmessagesnotvisible,
  (attrs.provider ->> 'ApproximateNumberOfMessagesDelayed')::integer AS approximatenumberofmessagesdelayed,
  (attrs.provider ->> 'DelaySeconds')::integer AS delayseconds,
  TIMESTAMP WITH TIME ZONE 'epoch' + (attrs.provider ->> 'CreatedTimestamp')::double precision * INTERVAL '1 second' AS createdtimestamp,
  TIMESTAMP WITH TIME ZONE 'epoch' + (attrs.provider ->> 'LastModifiedTimestamp')::double precision * INTERVAL '1 second' AS lastmodifiedtimestamp,
  attrs.provider ->> 'QueueArn' AS queuearn,
  (attrs.provider ->> 'MaximumMessageSize')::integer AS maximummessagesize,
  (attrs.provider ->> 'MessageRetentionPeriod')::integer AS messageretentionperiod,
  attrs.provider ->> 'url' AS url,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider -> 'Policy' AS policy,
  attrs.provider -> 'RedrivePolicy' AS redrivepolicy,
  (attrs.provider ->> 'FifoQueue')::boolean AS fifoqueue,
  (attrs.provider ->> 'ContentBasedDeduplication')::boolean AS contentbaseddeduplication,
  attrs.provider ->> 'KmsMasterKeyId' AS kmsmasterkeyid,
  attrs.provider ->> 'KmsDataKeyReusePeriodSecond' AS kmsdatakeyreuseperiodsecond,
  attrs.metadata -> 'Tags' AS tags,
  attrs.metadata -> 'Policy' AS policy,
  
    _kms_key_id.target_id AS _kms_key_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_kms_key_relation.resource_id AS resource_id,
      _aws_kms_key.id AS target_id
    FROM
      resource_relation AS _aws_kms_key_relation
      INNER JOIN resource AS _aws_kms_key
        ON _aws_kms_key_relation.target_id = _aws_kms_key.id
        AND _aws_kms_key.provider_type = 'Key'
        AND _aws_kms_key.service = 'kms'
        AND _aws_kms_key.provider_account_id = :provider_account_id
    WHERE
      _aws_kms_key_relation.relation = 'has-key'
      AND _aws_kms_key_relation.provider_account_id = :provider_account_id
  ) AS _kms_key_id ON _kms_key_id.resource_id = R.id
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
          AND _aws_organizations_account_relation.provider_account_id = 8
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'Queue'
  AND R.service = 'sqs'
ON CONFLICT (_id) DO UPDATE
SET
    ReceiveMessageWaitTimeSeconds = EXCLUDED.ReceiveMessageWaitTimeSeconds,
    VisibilityTimeout = EXCLUDED.VisibilityTimeout,
    ApproximateNumberOfMessages = EXCLUDED.ApproximateNumberOfMessages,
    ApproximateNumberOfMessagesNotVisible = EXCLUDED.ApproximateNumberOfMessagesNotVisible,
    ApproximateNumberOfMessagesDelayed = EXCLUDED.ApproximateNumberOfMessagesDelayed,
    DelaySeconds = EXCLUDED.DelaySeconds,
    CreatedTimestamp = EXCLUDED.CreatedTimestamp,
    LastModifiedTimestamp = EXCLUDED.LastModifiedTimestamp,
    QueueArn = EXCLUDED.QueueArn,
    MaximumMessageSize = EXCLUDED.MaximumMessageSize,
    MessageRetentionPeriod = EXCLUDED.MessageRetentionPeriod,
    url = EXCLUDED.url,
    Tags = EXCLUDED.Tags,
    Policy = EXCLUDED.Policy,
    RedrivePolicy = EXCLUDED.RedrivePolicy,
    FifoQueue = EXCLUDED.FifoQueue,
    ContentBasedDeduplication = EXCLUDED.ContentBasedDeduplication,
    KmsMasterKeyId = EXCLUDED.KmsMasterKeyId,
    KmsDataKeyReusePeriodSecond = EXCLUDED.KmsDataKeyReusePeriodSecond,
    _tags = EXCLUDED._tags,
    _policy = EXCLUDED._policy,
    _kms_key_id = EXCLUDED._kms_key_id,
    _account_id = EXCLUDED._account_id
  ;

