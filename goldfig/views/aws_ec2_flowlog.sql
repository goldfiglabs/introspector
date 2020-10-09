DROP MATERIALIZED VIEW IF EXISTS aws_ec2_flowlog CASCADE;

CREATE MATERIALIZED VIEW aws_ec2_flowlog AS
SELECT
  R.id AS resource_id,
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
  LEFT JOIN resource_attribute AS deliverlogserrormessage
    ON deliverlogserrormessage.resource_id = R.id
    AND deliverlogserrormessage.type = 'provider'
    AND lower(deliverlogserrormessage.attr_name) = 'deliverlogserrormessage'
  LEFT JOIN resource_attribute AS deliverlogspermissionarn
    ON deliverlogspermissionarn.resource_id = R.id
    AND deliverlogspermissionarn.type = 'provider'
    AND lower(deliverlogspermissionarn.attr_name) = 'deliverlogspermissionarn'
  LEFT JOIN resource_attribute AS deliverlogsstatus
    ON deliverlogsstatus.resource_id = R.id
    AND deliverlogsstatus.type = 'provider'
    AND lower(deliverlogsstatus.attr_name) = 'deliverlogsstatus'
  LEFT JOIN resource_attribute AS flowlogid
    ON flowlogid.resource_id = R.id
    AND flowlogid.type = 'provider'
    AND lower(flowlogid.attr_name) = 'flowlogid'
  LEFT JOIN resource_attribute AS flowlogstatus
    ON flowlogstatus.resource_id = R.id
    AND flowlogstatus.type = 'provider'
    AND lower(flowlogstatus.attr_name) = 'flowlogstatus'
  LEFT JOIN resource_attribute AS loggroupname
    ON loggroupname.resource_id = R.id
    AND loggroupname.type = 'provider'
    AND lower(loggroupname.attr_name) = 'loggroupname'
  LEFT JOIN resource_attribute AS resourceid
    ON resourceid.resource_id = R.id
    AND resourceid.type = 'provider'
    AND lower(resourceid.attr_name) = 'resourceid'
  LEFT JOIN resource_attribute AS traffictype
    ON traffictype.resource_id = R.id
    AND traffictype.type = 'provider'
    AND lower(traffictype.attr_name) = 'traffictype'
  LEFT JOIN resource_attribute AS logdestinationtype
    ON logdestinationtype.resource_id = R.id
    AND logdestinationtype.type = 'provider'
    AND lower(logdestinationtype.attr_name) = 'logdestinationtype'
  LEFT JOIN resource_attribute AS logdestination
    ON logdestination.resource_id = R.id
    AND logdestination.type = 'provider'
    AND lower(logdestination.attr_name) = 'logdestination'
  LEFT JOIN resource_attribute AS logformat
    ON logformat.resource_id = R.id
    AND logformat.type = 'provider'
    AND lower(logformat.attr_name) = 'logformat'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS maxaggregationinterval
    ON maxaggregationinterval.resource_id = R.id
    AND maxaggregationinterval.type = 'provider'
    AND lower(maxaggregationinterval.attr_name) = 'maxaggregationinterval'
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
    WHERE
      _aws_iam_role_relation.relation = 'acts-as'
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
    WHERE
      _aws_logs_loggroup_relation.relation = 'publishes-to'
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
    WHERE
      _aws_s3_bucket_relation.relation = 'publishes-to'
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
    WHERE
      _aws_ec2_vpc_relation.relation = 'logs'
  ) AS _vpc_id ON _vpc_id.resource_id = R.id
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
  AND LOWER(R.provider_type) = 'flowlog'
  AND R.service = 'ec2'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_ec2_flowlog;

COMMENT ON MATERIALIZED VIEW aws_ec2_flowlog IS 'ec2 flowlog resources and their associated attributes.';

