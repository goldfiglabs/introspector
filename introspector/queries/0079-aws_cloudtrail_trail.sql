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
INSERT INTO aws_cloudtrail_trail (
  _id,
  uri,
  provider_account_id,
  name,
  s3bucketname,
  s3keyprefix,
  snstopicname,
  snstopicarn,
  includeglobalserviceevents,
  ismultiregiontrail,
  homeregion,
  trailarn,
  logfilevalidationenabled,
  cloudwatchlogsloggrouparn,
  cloudwatchlogsrolearn,
  kmskeyid,
  hascustomeventselectors,
  hasinsightselectors,
  isorganizationtrail,
  islogging,
  latestdeliveryerror,
  latestnotificationerror,
  latestdeliverytime,
  latestnotificationtime,
  startloggingtime,
  stoploggingtime,
  latestcloudwatchlogsdeliveryerror,
  latestcloudwatchlogsdeliverytime,
  latestdigestdeliverytime,
  latestdigestdeliveryerror,
  latestdeliveryattempttime,
  latestnotificationattempttime,
  latestnotificationattemptsucceeded,
  latestdeliveryattemptsucceeded,
  timeloggingstarted,
  timeloggingstopped,
  tags,
  eventselectors,
  _tags,
  _s3_bucket_id,_logs_loggroup_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'Name' AS name,
  attrs.provider ->> 'S3BucketName' AS s3bucketname,
  attrs.provider ->> 'S3KeyPrefix' AS s3keyprefix,
  attrs.provider ->> 'SnsTopicName' AS snstopicname,
  attrs.provider ->> 'SnsTopicARN' AS snstopicarn,
  (attrs.provider ->> 'IncludeGlobalServiceEvents')::boolean AS includeglobalserviceevents,
  (attrs.provider ->> 'IsMultiRegionTrail')::boolean AS ismultiregiontrail,
  attrs.provider ->> 'HomeRegion' AS homeregion,
  attrs.provider ->> 'TrailARN' AS trailarn,
  (attrs.provider ->> 'LogFileValidationEnabled')::boolean AS logfilevalidationenabled,
  attrs.provider ->> 'CloudWatchLogsLogGroupArn' AS cloudwatchlogsloggrouparn,
  attrs.provider ->> 'CloudWatchLogsRoleArn' AS cloudwatchlogsrolearn,
  attrs.provider ->> 'KmsKeyId' AS kmskeyid,
  (attrs.provider ->> 'HasCustomEventSelectors')::boolean AS hascustomeventselectors,
  (attrs.provider ->> 'HasInsightSelectors')::boolean AS hasinsightselectors,
  (attrs.provider ->> 'IsOrganizationTrail')::boolean AS isorganizationtrail,
  (attrs.provider ->> 'IsLogging')::boolean AS islogging,
  attrs.provider ->> 'LatestDeliveryError' AS latestdeliveryerror,
  attrs.provider ->> 'LatestNotificationError' AS latestnotificationerror,
  (TO_TIMESTAMP(attrs.provider ->> 'LatestDeliveryTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS latestdeliverytime,
  (TO_TIMESTAMP(attrs.provider ->> 'LatestNotificationTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS latestnotificationtime,
  (TO_TIMESTAMP(attrs.provider ->> 'StartLoggingTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS startloggingtime,
  (TO_TIMESTAMP(attrs.provider ->> 'StopLoggingTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS stoploggingtime,
  attrs.provider ->> 'LatestCloudWatchLogsDeliveryError' AS latestcloudwatchlogsdeliveryerror,
  (TO_TIMESTAMP(attrs.provider ->> 'LatestCloudWatchLogsDeliveryTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS latestcloudwatchlogsdeliverytime,
  (TO_TIMESTAMP(attrs.provider ->> 'LatestDigestDeliveryTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS latestdigestdeliverytime,
  attrs.provider ->> 'LatestDigestDeliveryError' AS latestdigestdeliveryerror,
  attrs.provider ->> 'LatestDeliveryAttemptTime' AS latestdeliveryattempttime,
  attrs.provider ->> 'LatestNotificationAttemptTime' AS latestnotificationattempttime,
  attrs.provider ->> 'LatestNotificationAttemptSucceeded' AS latestnotificationattemptsucceeded,
  attrs.provider ->> 'LatestDeliveryAttemptSucceeded' AS latestdeliveryattemptsucceeded,
  attrs.provider ->> 'TimeLoggingStarted' AS timeloggingstarted,
  attrs.provider ->> 'TimeLoggingStopped' AS timeloggingstopped,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider -> 'EventSelectors' AS eventselectors,
  attrs.metadata -> 'Tags' AS tags,
  
    _s3_bucket_id.target_id AS _s3_bucket_id,
    _logs_loggroup_id.target_id AS _logs_loggroup_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_s3_bucket_relation.resource_id AS resource_id,
      _aws_s3_bucket.id AS target_id
    FROM
      resource_relation AS _aws_s3_bucket_relation
      INNER JOIN resource AS _aws_s3_bucket
        ON _aws_s3_bucket_relation.target_id = _aws_s3_bucket.id
        AND _aws_s3_bucket.provider_type = 'Bucket'
        AND _aws_s3_bucket.service = 's3'
        AND _aws_s3_bucket.provider_account_id = :provider_account_id
    WHERE
      _aws_s3_bucket_relation.relation = 'forwards-to'
      AND _aws_s3_bucket_relation.provider_account_id = :provider_account_id
  ) AS _s3_bucket_id ON _s3_bucket_id.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_logs_loggroup_relation.resource_id AS resource_id,
      _aws_logs_loggroup.id AS target_id
    FROM
      resource_relation AS _aws_logs_loggroup_relation
      INNER JOIN resource AS _aws_logs_loggroup
        ON _aws_logs_loggroup_relation.target_id = _aws_logs_loggroup.id
        AND _aws_logs_loggroup.provider_type = 'LogGroup'
        AND _aws_logs_loggroup.service = 'logs'
        AND _aws_logs_loggroup.provider_account_id = :provider_account_id
    WHERE
      _aws_logs_loggroup_relation.relation = 'uses-group'
      AND _aws_logs_loggroup_relation.provider_account_id = :provider_account_id
  ) AS _logs_loggroup_id ON _logs_loggroup_id.resource_id = R.id
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
  AND R.provider_type = 'Trail'
  AND R.service = 'cloudtrail'
ON CONFLICT (_id) DO UPDATE
SET
    Name = EXCLUDED.Name,
    S3BucketName = EXCLUDED.S3BucketName,
    S3KeyPrefix = EXCLUDED.S3KeyPrefix,
    SnsTopicName = EXCLUDED.SnsTopicName,
    SnsTopicARN = EXCLUDED.SnsTopicARN,
    IncludeGlobalServiceEvents = EXCLUDED.IncludeGlobalServiceEvents,
    IsMultiRegionTrail = EXCLUDED.IsMultiRegionTrail,
    HomeRegion = EXCLUDED.HomeRegion,
    TrailARN = EXCLUDED.TrailARN,
    LogFileValidationEnabled = EXCLUDED.LogFileValidationEnabled,
    CloudWatchLogsLogGroupArn = EXCLUDED.CloudWatchLogsLogGroupArn,
    CloudWatchLogsRoleArn = EXCLUDED.CloudWatchLogsRoleArn,
    KmsKeyId = EXCLUDED.KmsKeyId,
    HasCustomEventSelectors = EXCLUDED.HasCustomEventSelectors,
    HasInsightSelectors = EXCLUDED.HasInsightSelectors,
    IsOrganizationTrail = EXCLUDED.IsOrganizationTrail,
    IsLogging = EXCLUDED.IsLogging,
    LatestDeliveryError = EXCLUDED.LatestDeliveryError,
    LatestNotificationError = EXCLUDED.LatestNotificationError,
    LatestDeliveryTime = EXCLUDED.LatestDeliveryTime,
    LatestNotificationTime = EXCLUDED.LatestNotificationTime,
    StartLoggingTime = EXCLUDED.StartLoggingTime,
    StopLoggingTime = EXCLUDED.StopLoggingTime,
    LatestCloudWatchLogsDeliveryError = EXCLUDED.LatestCloudWatchLogsDeliveryError,
    LatestCloudWatchLogsDeliveryTime = EXCLUDED.LatestCloudWatchLogsDeliveryTime,
    LatestDigestDeliveryTime = EXCLUDED.LatestDigestDeliveryTime,
    LatestDigestDeliveryError = EXCLUDED.LatestDigestDeliveryError,
    LatestDeliveryAttemptTime = EXCLUDED.LatestDeliveryAttemptTime,
    LatestNotificationAttemptTime = EXCLUDED.LatestNotificationAttemptTime,
    LatestNotificationAttemptSucceeded = EXCLUDED.LatestNotificationAttemptSucceeded,
    LatestDeliveryAttemptSucceeded = EXCLUDED.LatestDeliveryAttemptSucceeded,
    TimeLoggingStarted = EXCLUDED.TimeLoggingStarted,
    TimeLoggingStopped = EXCLUDED.TimeLoggingStopped,
    Tags = EXCLUDED.Tags,
    EventSelectors = EXCLUDED.EventSelectors,
    _tags = EXCLUDED._tags,
    _s3_bucket_id = EXCLUDED._s3_bucket_id,
    _logs_loggroup_id = EXCLUDED._logs_loggroup_id,
    _account_id = EXCLUDED._account_id
  ;

