DROP MATERIALIZED VIEW IF EXISTS aws_cloudtrail_trail CASCADE;

CREATE MATERIALIZED VIEW aws_cloudtrail_trail AS
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
  name.attr_value #>> '{}' AS name,
  s3bucketname.attr_value #>> '{}' AS s3bucketname,
  s3keyprefix.attr_value #>> '{}' AS s3keyprefix,
  snstopicname.attr_value #>> '{}' AS snstopicname,
  snstopicarn.attr_value #>> '{}' AS snstopicarn,
  (includeglobalserviceevents.attr_value #>> '{}')::boolean AS includeglobalserviceevents,
  (ismultiregiontrail.attr_value #>> '{}')::boolean AS ismultiregiontrail,
  homeregion.attr_value #>> '{}' AS homeregion,
  trailarn.attr_value #>> '{}' AS trailarn,
  (logfilevalidationenabled.attr_value #>> '{}')::boolean AS logfilevalidationenabled,
  cloudwatchlogsloggrouparn.attr_value #>> '{}' AS cloudwatchlogsloggrouparn,
  cloudwatchlogsrolearn.attr_value #>> '{}' AS cloudwatchlogsrolearn,
  kmskeyid.attr_value #>> '{}' AS kmskeyid,
  (hascustomeventselectors.attr_value #>> '{}')::boolean AS hascustomeventselectors,
  (hasinsightselectors.attr_value #>> '{}')::boolean AS hasinsightselectors,
  (isorganizationtrail.attr_value #>> '{}')::boolean AS isorganizationtrail,
  (islogging.attr_value #>> '{}')::boolean AS islogging,
  latestdeliveryerror.attr_value #>> '{}' AS latestdeliveryerror,
  latestnotificationerror.attr_value #>> '{}' AS latestnotificationerror,
  (TO_TIMESTAMP(latestdeliverytime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS latestdeliverytime,
  (TO_TIMESTAMP(latestnotificationtime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS latestnotificationtime,
  (TO_TIMESTAMP(startloggingtime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS startloggingtime,
  (TO_TIMESTAMP(stoploggingtime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS stoploggingtime,
  latestcloudwatchlogsdeliveryerror.attr_value #>> '{}' AS latestcloudwatchlogsdeliveryerror,
  (TO_TIMESTAMP(latestcloudwatchlogsdeliverytime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS latestcloudwatchlogsdeliverytime,
  (TO_TIMESTAMP(latestdigestdeliverytime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS latestdigestdeliverytime,
  latestdigestdeliveryerror.attr_value #>> '{}' AS latestdigestdeliveryerror,
  latestdeliveryattempttime.attr_value #>> '{}' AS latestdeliveryattempttime,
  latestnotificationattempttime.attr_value #>> '{}' AS latestnotificationattempttime,
  latestnotificationattemptsucceeded.attr_value #>> '{}' AS latestnotificationattemptsucceeded,
  latestdeliveryattemptsucceeded.attr_value #>> '{}' AS latestdeliveryattemptsucceeded,
  timeloggingstarted.attr_value #>> '{}' AS timeloggingstarted,
  timeloggingstopped.attr_value #>> '{}' AS timeloggingstopped,
  tags.attr_value::jsonb AS tags,
  eventselectors.attr_value::jsonb AS eventselectors,
  
    _s3_bucket_id.target_id AS _s3_bucket_id,
    _logs_loggroup_id.target_id AS _logs_loggroup_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS name
    ON name.id = R.id
    AND name.attr_name = 'name'
  LEFT JOIN attrs AS s3bucketname
    ON s3bucketname.id = R.id
    AND s3bucketname.attr_name = 's3bucketname'
  LEFT JOIN attrs AS s3keyprefix
    ON s3keyprefix.id = R.id
    AND s3keyprefix.attr_name = 's3keyprefix'
  LEFT JOIN attrs AS snstopicname
    ON snstopicname.id = R.id
    AND snstopicname.attr_name = 'snstopicname'
  LEFT JOIN attrs AS snstopicarn
    ON snstopicarn.id = R.id
    AND snstopicarn.attr_name = 'snstopicarn'
  LEFT JOIN attrs AS includeglobalserviceevents
    ON includeglobalserviceevents.id = R.id
    AND includeglobalserviceevents.attr_name = 'includeglobalserviceevents'
  LEFT JOIN attrs AS ismultiregiontrail
    ON ismultiregiontrail.id = R.id
    AND ismultiregiontrail.attr_name = 'ismultiregiontrail'
  LEFT JOIN attrs AS homeregion
    ON homeregion.id = R.id
    AND homeregion.attr_name = 'homeregion'
  LEFT JOIN attrs AS trailarn
    ON trailarn.id = R.id
    AND trailarn.attr_name = 'trailarn'
  LEFT JOIN attrs AS logfilevalidationenabled
    ON logfilevalidationenabled.id = R.id
    AND logfilevalidationenabled.attr_name = 'logfilevalidationenabled'
  LEFT JOIN attrs AS cloudwatchlogsloggrouparn
    ON cloudwatchlogsloggrouparn.id = R.id
    AND cloudwatchlogsloggrouparn.attr_name = 'cloudwatchlogsloggrouparn'
  LEFT JOIN attrs AS cloudwatchlogsrolearn
    ON cloudwatchlogsrolearn.id = R.id
    AND cloudwatchlogsrolearn.attr_name = 'cloudwatchlogsrolearn'
  LEFT JOIN attrs AS kmskeyid
    ON kmskeyid.id = R.id
    AND kmskeyid.attr_name = 'kmskeyid'
  LEFT JOIN attrs AS hascustomeventselectors
    ON hascustomeventselectors.id = R.id
    AND hascustomeventselectors.attr_name = 'hascustomeventselectors'
  LEFT JOIN attrs AS hasinsightselectors
    ON hasinsightselectors.id = R.id
    AND hasinsightselectors.attr_name = 'hasinsightselectors'
  LEFT JOIN attrs AS isorganizationtrail
    ON isorganizationtrail.id = R.id
    AND isorganizationtrail.attr_name = 'isorganizationtrail'
  LEFT JOIN attrs AS islogging
    ON islogging.id = R.id
    AND islogging.attr_name = 'islogging'
  LEFT JOIN attrs AS latestdeliveryerror
    ON latestdeliveryerror.id = R.id
    AND latestdeliveryerror.attr_name = 'latestdeliveryerror'
  LEFT JOIN attrs AS latestnotificationerror
    ON latestnotificationerror.id = R.id
    AND latestnotificationerror.attr_name = 'latestnotificationerror'
  LEFT JOIN attrs AS latestdeliverytime
    ON latestdeliverytime.id = R.id
    AND latestdeliverytime.attr_name = 'latestdeliverytime'
  LEFT JOIN attrs AS latestnotificationtime
    ON latestnotificationtime.id = R.id
    AND latestnotificationtime.attr_name = 'latestnotificationtime'
  LEFT JOIN attrs AS startloggingtime
    ON startloggingtime.id = R.id
    AND startloggingtime.attr_name = 'startloggingtime'
  LEFT JOIN attrs AS stoploggingtime
    ON stoploggingtime.id = R.id
    AND stoploggingtime.attr_name = 'stoploggingtime'
  LEFT JOIN attrs AS latestcloudwatchlogsdeliveryerror
    ON latestcloudwatchlogsdeliveryerror.id = R.id
    AND latestcloudwatchlogsdeliveryerror.attr_name = 'latestcloudwatchlogsdeliveryerror'
  LEFT JOIN attrs AS latestcloudwatchlogsdeliverytime
    ON latestcloudwatchlogsdeliverytime.id = R.id
    AND latestcloudwatchlogsdeliverytime.attr_name = 'latestcloudwatchlogsdeliverytime'
  LEFT JOIN attrs AS latestdigestdeliverytime
    ON latestdigestdeliverytime.id = R.id
    AND latestdigestdeliverytime.attr_name = 'latestdigestdeliverytime'
  LEFT JOIN attrs AS latestdigestdeliveryerror
    ON latestdigestdeliveryerror.id = R.id
    AND latestdigestdeliveryerror.attr_name = 'latestdigestdeliveryerror'
  LEFT JOIN attrs AS latestdeliveryattempttime
    ON latestdeliveryattempttime.id = R.id
    AND latestdeliveryattempttime.attr_name = 'latestdeliveryattempttime'
  LEFT JOIN attrs AS latestnotificationattempttime
    ON latestnotificationattempttime.id = R.id
    AND latestnotificationattempttime.attr_name = 'latestnotificationattempttime'
  LEFT JOIN attrs AS latestnotificationattemptsucceeded
    ON latestnotificationattemptsucceeded.id = R.id
    AND latestnotificationattemptsucceeded.attr_name = 'latestnotificationattemptsucceeded'
  LEFT JOIN attrs AS latestdeliveryattemptsucceeded
    ON latestdeliveryattemptsucceeded.id = R.id
    AND latestdeliveryattemptsucceeded.attr_name = 'latestdeliveryattemptsucceeded'
  LEFT JOIN attrs AS timeloggingstarted
    ON timeloggingstarted.id = R.id
    AND timeloggingstarted.attr_name = 'timeloggingstarted'
  LEFT JOIN attrs AS timeloggingstopped
    ON timeloggingstopped.id = R.id
    AND timeloggingstopped.attr_name = 'timeloggingstopped'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS eventselectors
    ON eventselectors.id = R.id
    AND eventselectors.attr_name = 'eventselectors'
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
      _aws_s3_bucket_relation.relation = 'forwards-to'
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
    WHERE
      _aws_logs_loggroup_relation.relation = 'uses-group'
  ) AS _logs_loggroup_id ON _logs_loggroup_id.resource_id = R.id
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
  AND LOWER(R.provider_type) = 'trail'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_cloudtrail_trail;

COMMENT ON MATERIALIZED VIEW aws_cloudtrail_trail IS 'cloudtrail trail resources and their associated attributes.';

