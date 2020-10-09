DROP MATERIALIZED VIEW IF EXISTS aws_sqs_queue CASCADE;

CREATE MATERIALIZED VIEW aws_sqs_queue AS
SELECT
  R.id AS resource_id,
  R.uri,
  R.provider_account_id,
  (ReceiveMessageWaitTimeSeconds.attr_value #>> '{}')::integer AS receivemessagewaittimeseconds,
  (VisibilityTimeout.attr_value #>> '{}')::integer AS visibilitytimeout,
  (ApproximateNumberOfMessages.attr_value #>> '{}')::integer AS approximatenumberofmessages,
  (ApproximateNumberOfMessagesNotVisible.attr_value #>> '{}')::integer AS approximatenumberofmessagesnotvisible,
  (ApproximateNumberOfMessagesDelayed.attr_value #>> '{}')::integer AS approximatenumberofmessagesdelayed,
  (DelaySeconds.attr_value #>> '{}')::integer AS delayseconds,
  (TO_TIMESTAMP(CreatedTimestamp.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdtimestamp,
  (TO_TIMESTAMP(LastModifiedTimestamp.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS lastmodifiedtimestamp,
  QueueArn.attr_value #>> '{}' AS queuearn,
  (MaximumMessageSize.attr_value #>> '{}')::integer AS maximummessagesize,
  (MessageRetentionPeriod.attr_value #>> '{}')::integer AS messageretentionperiod,
  url.attr_value #>> '{}' AS url,
  Tags.attr_value::jsonb AS tags,
  Policy.attr_value::jsonb AS policy,
  RedrivePolicy.attr_value::jsonb AS redrivepolicy,
  (FifoQueue.attr_value #>> '{}')::boolean AS fifoqueue,
  (ContentBasedDeduplication.attr_value #>> '{}')::boolean AS contentbaseddeduplication,
  KmsMasterKeyId.attr_value #>> '{}' AS kmsmasterkeyid,
  KmsDataKeyReusePeriodSecond.attr_value #>> '{}' AS kmsdatakeyreuseperiodsecond,
  
    _kms_key_id.target_id AS _kms_key_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS ReceiveMessageWaitTimeSeconds
    ON ReceiveMessageWaitTimeSeconds.resource_id = R.id
    AND ReceiveMessageWaitTimeSeconds.type = 'provider'
    AND lower(ReceiveMessageWaitTimeSeconds.attr_name) = 'receivemessagewaittimeseconds'
  LEFT JOIN resource_attribute AS VisibilityTimeout
    ON VisibilityTimeout.resource_id = R.id
    AND VisibilityTimeout.type = 'provider'
    AND lower(VisibilityTimeout.attr_name) = 'visibilitytimeout'
  LEFT JOIN resource_attribute AS ApproximateNumberOfMessages
    ON ApproximateNumberOfMessages.resource_id = R.id
    AND ApproximateNumberOfMessages.type = 'provider'
    AND lower(ApproximateNumberOfMessages.attr_name) = 'approximatenumberofmessages'
  LEFT JOIN resource_attribute AS ApproximateNumberOfMessagesNotVisible
    ON ApproximateNumberOfMessagesNotVisible.resource_id = R.id
    AND ApproximateNumberOfMessagesNotVisible.type = 'provider'
    AND lower(ApproximateNumberOfMessagesNotVisible.attr_name) = 'approximatenumberofmessagesnotvisible'
  LEFT JOIN resource_attribute AS ApproximateNumberOfMessagesDelayed
    ON ApproximateNumberOfMessagesDelayed.resource_id = R.id
    AND ApproximateNumberOfMessagesDelayed.type = 'provider'
    AND lower(ApproximateNumberOfMessagesDelayed.attr_name) = 'approximatenumberofmessagesdelayed'
  LEFT JOIN resource_attribute AS DelaySeconds
    ON DelaySeconds.resource_id = R.id
    AND DelaySeconds.type = 'provider'
    AND lower(DelaySeconds.attr_name) = 'delayseconds'
  LEFT JOIN resource_attribute AS CreatedTimestamp
    ON CreatedTimestamp.resource_id = R.id
    AND CreatedTimestamp.type = 'provider'
    AND lower(CreatedTimestamp.attr_name) = 'createdtimestamp'
  LEFT JOIN resource_attribute AS LastModifiedTimestamp
    ON LastModifiedTimestamp.resource_id = R.id
    AND LastModifiedTimestamp.type = 'provider'
    AND lower(LastModifiedTimestamp.attr_name) = 'lastmodifiedtimestamp'
  LEFT JOIN resource_attribute AS QueueArn
    ON QueueArn.resource_id = R.id
    AND QueueArn.type = 'provider'
    AND lower(QueueArn.attr_name) = 'queuearn'
  LEFT JOIN resource_attribute AS MaximumMessageSize
    ON MaximumMessageSize.resource_id = R.id
    AND MaximumMessageSize.type = 'provider'
    AND lower(MaximumMessageSize.attr_name) = 'maximummessagesize'
  LEFT JOIN resource_attribute AS MessageRetentionPeriod
    ON MessageRetentionPeriod.resource_id = R.id
    AND MessageRetentionPeriod.type = 'provider'
    AND lower(MessageRetentionPeriod.attr_name) = 'messageretentionperiod'
  LEFT JOIN resource_attribute AS url
    ON url.resource_id = R.id
    AND url.type = 'provider'
    AND lower(url.attr_name) = 'url'
  LEFT JOIN resource_attribute AS Tags
    ON Tags.resource_id = R.id
    AND Tags.type = 'provider'
    AND lower(Tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS Policy
    ON Policy.resource_id = R.id
    AND Policy.type = 'provider'
    AND lower(Policy.attr_name) = 'policy'
  LEFT JOIN resource_attribute AS RedrivePolicy
    ON RedrivePolicy.resource_id = R.id
    AND RedrivePolicy.type = 'provider'
    AND lower(RedrivePolicy.attr_name) = 'redrivepolicy'
  LEFT JOIN resource_attribute AS FifoQueue
    ON FifoQueue.resource_id = R.id
    AND FifoQueue.type = 'provider'
    AND lower(FifoQueue.attr_name) = 'fifoqueue'
  LEFT JOIN resource_attribute AS ContentBasedDeduplication
    ON ContentBasedDeduplication.resource_id = R.id
    AND ContentBasedDeduplication.type = 'provider'
    AND lower(ContentBasedDeduplication.attr_name) = 'contentbaseddeduplication'
  LEFT JOIN resource_attribute AS KmsMasterKeyId
    ON KmsMasterKeyId.resource_id = R.id
    AND KmsMasterKeyId.type = 'provider'
    AND lower(KmsMasterKeyId.attr_name) = 'kmsmasterkeyid'
  LEFT JOIN resource_attribute AS KmsDataKeyReusePeriodSecond
    ON KmsDataKeyReusePeriodSecond.resource_id = R.id
    AND KmsDataKeyReusePeriodSecond.type = 'provider'
    AND lower(KmsDataKeyReusePeriodSecond.attr_name) = 'kmsdatakeyreuseperiodsecond'
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
    WHERE
      _aws_kms_key_relation.relation = 'has-key'
  ) AS _kms_key_id ON _kms_key_id.resource_id = R.id
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
  AND LOWER(R.provider_type) = 'queue'
  AND R.service = 'sqs'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_sqs_queue;

COMMENT ON MATERIALIZED VIEW aws_sqs_queue IS 'sqs queue resources and their associated attributes.';

