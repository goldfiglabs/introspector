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
  (TO_TIMESTAMP(creationtime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS creationtime,
  deliverlogserrormessage.attr_value #>> '{}' AS deliverlogserrormessage,
  deliverlogspermissionarn.attr_value #>> '{}' AS deliverlogspermissionarn,
  deliverlogsstatus.attr_value #>> '{}' AS deliverlogsstatus,
  flowlogid.attr_value #>> '{}' AS flowlogid,
  flowlogstatus.attr_value #>> '{}' AS flowlogstatus,
  loggroupname.attr_value #>> '{}' AS loggroupname,
  resourceid.attr_value #>> '{}' AS resourceid,
  traffictype.attr_value #>> '{}' AS traffictype,
  logdestinationtype.attr_value #>> '{}' AS logdestinationtype,
  logdestination.attr_value #>> '{}' AS logdestination,
  logformat.attr_value #>> '{}' AS logformat,
  tags.attr_value::jsonb AS tags,
  (maxaggregationinterval.attr_value #>> '{}')::integer AS maxaggregationinterval,
  _tags.attr_value::jsonb AS _tags,
  
    _iam_role_id.target_id AS _iam_role_id,
    _logs_loggroup_id.target_id AS _logs_loggroup_id,
    _s3_bucket_id.target_id AS _s3_bucket_id,
    _vpc_id.target_id AS _vpc_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS creationtime
    ON creationtime.resource_id = R.id
    AND creationtime.type = 'provider'
    AND lower(creationtime.attr_name) = 'creationtime'
    AND creationtime.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS deliverlogserrormessage
    ON deliverlogserrormessage.resource_id = R.id
    AND deliverlogserrormessage.type = 'provider'
    AND lower(deliverlogserrormessage.attr_name) = 'deliverlogserrormessage'
    AND deliverlogserrormessage.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS deliverlogspermissionarn
    ON deliverlogspermissionarn.resource_id = R.id
    AND deliverlogspermissionarn.type = 'provider'
    AND lower(deliverlogspermissionarn.attr_name) = 'deliverlogspermissionarn'
    AND deliverlogspermissionarn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS deliverlogsstatus
    ON deliverlogsstatus.resource_id = R.id
    AND deliverlogsstatus.type = 'provider'
    AND lower(deliverlogsstatus.attr_name) = 'deliverlogsstatus'
    AND deliverlogsstatus.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS flowlogid
    ON flowlogid.resource_id = R.id
    AND flowlogid.type = 'provider'
    AND lower(flowlogid.attr_name) = 'flowlogid'
    AND flowlogid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS flowlogstatus
    ON flowlogstatus.resource_id = R.id
    AND flowlogstatus.type = 'provider'
    AND lower(flowlogstatus.attr_name) = 'flowlogstatus'
    AND flowlogstatus.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS loggroupname
    ON loggroupname.resource_id = R.id
    AND loggroupname.type = 'provider'
    AND lower(loggroupname.attr_name) = 'loggroupname'
    AND loggroupname.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS resourceid
    ON resourceid.resource_id = R.id
    AND resourceid.type = 'provider'
    AND lower(resourceid.attr_name) = 'resourceid'
    AND resourceid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS traffictype
    ON traffictype.resource_id = R.id
    AND traffictype.type = 'provider'
    AND lower(traffictype.attr_name) = 'traffictype'
    AND traffictype.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS logdestinationtype
    ON logdestinationtype.resource_id = R.id
    AND logdestinationtype.type = 'provider'
    AND lower(logdestinationtype.attr_name) = 'logdestinationtype'
    AND logdestinationtype.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS logdestination
    ON logdestination.resource_id = R.id
    AND logdestination.type = 'provider'
    AND lower(logdestination.attr_name) = 'logdestination'
    AND logdestination.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS logformat
    ON logformat.resource_id = R.id
    AND logformat.type = 'provider'
    AND lower(logformat.attr_name) = 'logformat'
    AND logformat.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
    AND tags.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS maxaggregationinterval
    ON maxaggregationinterval.resource_id = R.id
    AND maxaggregationinterval.type = 'provider'
    AND lower(maxaggregationinterval.attr_name) = 'maxaggregationinterval'
    AND maxaggregationinterval.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
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
      _aws_organizations_account_relation.resource_id AS resource_id,
      _aws_organizations_account.id AS target_id
    FROM
    (
      SELECT
        _aws_organizations_account_relation.resource_id AS resource_id
      FROM
        resource_relation AS _aws_organizations_account_relation
        INNER JOIN resource AS _aws_organizations_account
          ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
          AND _aws_organizations_account.provider_type = 'Account'
          AND _aws_organizations_account.service = 'organizations'
      WHERE
        _aws_organizations_account_relation.relation = 'in'
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
      GROUP BY _aws_organizations_account_relation.resource_id
      HAVING COUNT(*) = 1
    ) AS unique_account_mapping
    INNER JOIN resource_relation AS _aws_organizations_account_relation
      ON _aws_organizations_account_relation.resource_id = unique_account_mapping.resource_id
    INNER JOIN resource AS _aws_organizations_account
      ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
      AND _aws_organizations_account.provider_type = 'Account'
      AND _aws_organizations_account.service = 'organizations'
      AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
    WHERE
        _aws_organizations_account_relation.relation = 'in'
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND PA.provider = 'aws'
  AND R.provider_type = 'FlowLog'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    creationtime = EXCLUDED.creationtime,
    deliverlogserrormessage = EXCLUDED.deliverlogserrormessage,
    deliverlogspermissionarn = EXCLUDED.deliverlogspermissionarn,
    deliverlogsstatus = EXCLUDED.deliverlogsstatus,
    flowlogid = EXCLUDED.flowlogid,
    flowlogstatus = EXCLUDED.flowlogstatus,
    loggroupname = EXCLUDED.loggroupname,
    resourceid = EXCLUDED.resourceid,
    traffictype = EXCLUDED.traffictype,
    logdestinationtype = EXCLUDED.logdestinationtype,
    logdestination = EXCLUDED.logdestination,
    logformat = EXCLUDED.logformat,
    tags = EXCLUDED.tags,
    maxaggregationinterval = EXCLUDED.maxaggregationinterval,
    _tags = EXCLUDED._tags,
    _iam_role_id = EXCLUDED._iam_role_id,
    _logs_loggroup_id = EXCLUDED._logs_loggroup_id,
    _s3_bucket_id = EXCLUDED._s3_bucket_id,
    _vpc_id = EXCLUDED._vpc_id,
    _account_id = EXCLUDED._account_id
  ;

