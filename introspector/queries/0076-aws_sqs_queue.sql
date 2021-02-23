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
  (ReceiveMessageWaitTimeSeconds.attr_value #>> '{}')::integer AS receivemessagewaittimeseconds,
  (VisibilityTimeout.attr_value #>> '{}')::integer AS visibilitytimeout,
  (ApproximateNumberOfMessages.attr_value #>> '{}')::integer AS approximatenumberofmessages,
  (ApproximateNumberOfMessagesNotVisible.attr_value #>> '{}')::integer AS approximatenumberofmessagesnotvisible,
  (ApproximateNumberOfMessagesDelayed.attr_value #>> '{}')::integer AS approximatenumberofmessagesdelayed,
  (DelaySeconds.attr_value #>> '{}')::integer AS delayseconds,
  TIMESTAMP WITH TIME ZONE 'epoch' + (CreatedTimestamp.attr_value #>> '{}')::double precision * INTERVAL '1 second' AS createdtimestamp,
  TIMESTAMP WITH TIME ZONE 'epoch' + (LastModifiedTimestamp.attr_value #>> '{}')::double precision * INTERVAL '1 second' AS lastmodifiedtimestamp,
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
  _tags.attr_value::jsonb AS _tags,
  _policy.attr_value::jsonb AS _policy,
  
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

