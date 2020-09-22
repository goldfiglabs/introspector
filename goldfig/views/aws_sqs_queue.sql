DROP MATERIALIZED VIEW IF EXISTS aws_sqs_queue CASCADE;

CREATE MATERIALIZED VIEW aws_sqs_queue AS
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
  (ReceiveMessageWaitTimeSeconds.attr_value #>> '{}')::integer AS receivemessagewaittimeseconds,
  (VisibilityTimeout.attr_value #>> '{}')::integer AS visibilitytimeout,
  (ApproximateNumberOfMessages.attr_value #>> '{}')::integer AS approximatenumberofmessages,
  (ApproximateNumberOfMessagesNotVisible.attr_value #>> '{}')::integer AS approximatenumberofmessagesnotvisible,
  (TO_TIMESTAMP(CreatedTimestamp.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdtimestamp,
  (TO_TIMESTAMP(LastModifiedTimestamp.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS lastmodifiedtimestamp,
  QueueArn.attr_value #>> '{}' AS queuearn,
  (MaximumMessageSize.attr_value #>> '{}')::integer AS maximummessagesize,
  (MessageRetentionPeriod.attr_value #>> '{}')::integer AS messageretentionperiod,
  url.attr_value #>> '{}' AS url,
  Tags.attr_value::jsonb AS tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS ReceiveMessageWaitTimeSeconds
    ON ReceiveMessageWaitTimeSeconds.id = R.id
    AND ReceiveMessageWaitTimeSeconds.attr_name = 'receivemessagewaittimeseconds'
  LEFT JOIN attrs AS VisibilityTimeout
    ON VisibilityTimeout.id = R.id
    AND VisibilityTimeout.attr_name = 'visibilitytimeout'
  LEFT JOIN attrs AS ApproximateNumberOfMessages
    ON ApproximateNumberOfMessages.id = R.id
    AND ApproximateNumberOfMessages.attr_name = 'approximatenumberofmessages'
  LEFT JOIN attrs AS ApproximateNumberOfMessagesNotVisible
    ON ApproximateNumberOfMessagesNotVisible.id = R.id
    AND ApproximateNumberOfMessagesNotVisible.attr_name = 'approximatenumberofmessagesnotvisible'
  LEFT JOIN attrs AS CreatedTimestamp
    ON CreatedTimestamp.id = R.id
    AND CreatedTimestamp.attr_name = 'createdtimestamp'
  LEFT JOIN attrs AS LastModifiedTimestamp
    ON LastModifiedTimestamp.id = R.id
    AND LastModifiedTimestamp.attr_name = 'lastmodifiedtimestamp'
  LEFT JOIN attrs AS QueueArn
    ON QueueArn.id = R.id
    AND QueueArn.attr_name = 'queuearn'
  LEFT JOIN attrs AS MaximumMessageSize
    ON MaximumMessageSize.id = R.id
    AND MaximumMessageSize.attr_name = 'maximummessagesize'
  LEFT JOIN attrs AS MessageRetentionPeriod
    ON MessageRetentionPeriod.id = R.id
    AND MessageRetentionPeriod.attr_name = 'messageretentionperiod'
  LEFT JOIN attrs AS url
    ON url.id = R.id
    AND url.attr_name = 'url'
  LEFT JOIN attrs AS Tags
    ON Tags.id = R.id
    AND Tags.attr_name = 'tags'
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
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_sqs_queue;

COMMENT ON MATERIALIZED VIEW aws_sqs_queue IS 'sqs queue resources and their associated attributes.';

