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
INSERT INTO aws_ec2_flowlog (
  _id,
  uri,
  provider_account_id,
  creationtime,
  deliverlogserrormessage,
  deliverlogspermissionarn,
  deliverlogsstatus,
  flowlogid,
  flowlogstatus,
  loggroupname,
  resourceid,
  traffictype,
  logdestinationtype,
  logdestination,
  logformat,
  tags,
  maxaggregationinterval,
  _tags,
  _iam_role_id,_logs_loggroup_id,_s3_bucket_id,_vpc_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  (TO_TIMESTAMP(attrs.provider ->> 'CreationTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS creationtime,
  attrs.provider ->> 'DeliverLogsErrorMessage' AS deliverlogserrormessage,
  attrs.provider ->> 'DeliverLogsPermissionArn' AS deliverlogspermissionarn,
  attrs.provider ->> 'DeliverLogsStatus' AS deliverlogsstatus,
  attrs.provider ->> 'FlowLogId' AS flowlogid,
  attrs.provider ->> 'FlowLogStatus' AS flowlogstatus,
  attrs.provider ->> 'LogGroupName' AS loggroupname,
  attrs.provider ->> 'ResourceId' AS resourceid,
  attrs.provider ->> 'TrafficType' AS traffictype,
  attrs.provider ->> 'LogDestinationType' AS logdestinationtype,
  attrs.provider ->> 'LogDestination' AS logdestination,
  attrs.provider ->> 'LogFormat' AS logformat,
  attrs.provider -> 'Tags' AS tags,
  (attrs.provider ->> 'MaxAggregationInterval')::integer AS maxaggregationinterval,
  attrs.metadata -> 'Tags' AS tags,
  
    _iam_role_id.target_id AS _iam_role_id,
    _logs_loggroup_id.target_id AS _logs_loggroup_id,
    _s3_bucket_id.target_id AS _s3_bucket_id,
    _vpc_id.target_id AS _vpc_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_iam_role_relation.resource_id AS resource_id,
      _aws_iam_role.id AS target_id
    FROM
      resource_relation AS _aws_iam_role_relation
      INNER JOIN resource AS _aws_iam_role
        ON _aws_iam_role_relation.target_id = _aws_iam_role.id
        AND _aws_iam_role.provider_type = 'Role'
        AND _aws_iam_role.service = 'iam'
        AND _aws_iam_role.provider_account_id = :provider_account_id
    WHERE
      _aws_iam_role_relation.relation = 'acts-as'
      AND _aws_iam_role_relation.provider_account_id = :provider_account_id
  ) AS _iam_role_id ON _iam_role_id.resource_id = R.id
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
      _aws_logs_loggroup_relation.relation = 'publishes-to'
      AND _aws_logs_loggroup_relation.provider_account_id = :provider_account_id
  ) AS _logs_loggroup_id ON _logs_loggroup_id.resource_id = R.id
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
      _aws_s3_bucket_relation.relation = 'publishes-to'
      AND _aws_s3_bucket_relation.provider_account_id = :provider_account_id
  ) AS _s3_bucket_id ON _s3_bucket_id.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_ec2_vpc_relation.resource_id AS resource_id,
      _aws_ec2_vpc.id AS target_id
    FROM
      resource_relation AS _aws_ec2_vpc_relation
      INNER JOIN resource AS _aws_ec2_vpc
        ON _aws_ec2_vpc_relation.target_id = _aws_ec2_vpc.id
        AND _aws_ec2_vpc.provider_type = 'Vpc'
        AND _aws_ec2_vpc.service = 'ec2'
        AND _aws_ec2_vpc.provider_account_id = :provider_account_id
    WHERE
      _aws_ec2_vpc_relation.relation = 'logs'
      AND _aws_ec2_vpc_relation.provider_account_id = :provider_account_id
  ) AS _vpc_id ON _vpc_id.resource_id = R.id
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
  AND R.provider_type = 'FlowLog'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    CreationTime = EXCLUDED.CreationTime,
    DeliverLogsErrorMessage = EXCLUDED.DeliverLogsErrorMessage,
    DeliverLogsPermissionArn = EXCLUDED.DeliverLogsPermissionArn,
    DeliverLogsStatus = EXCLUDED.DeliverLogsStatus,
    FlowLogId = EXCLUDED.FlowLogId,
    FlowLogStatus = EXCLUDED.FlowLogStatus,
    LogGroupName = EXCLUDED.LogGroupName,
    ResourceId = EXCLUDED.ResourceId,
    TrafficType = EXCLUDED.TrafficType,
    LogDestinationType = EXCLUDED.LogDestinationType,
    LogDestination = EXCLUDED.LogDestination,
    LogFormat = EXCLUDED.LogFormat,
    Tags = EXCLUDED.Tags,
    MaxAggregationInterval = EXCLUDED.MaxAggregationInterval,
    _tags = EXCLUDED._tags,
    _iam_role_id = EXCLUDED._iam_role_id,
    _logs_loggroup_id = EXCLUDED._logs_loggroup_id,
    _s3_bucket_id = EXCLUDED._s3_bucket_id,
    _vpc_id = EXCLUDED._vpc_id,
    _account_id = EXCLUDED._account_id
  ;

