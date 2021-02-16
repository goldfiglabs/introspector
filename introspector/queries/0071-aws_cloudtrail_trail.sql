INSERT INTO aws_cloudtrail_trail
SELECT
  R.id AS _id,
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
  LEFT JOIN resource_attribute AS name
    ON name.resource_id = R.id
    AND name.type = 'provider'
    AND lower(name.attr_name) = 'name'
  LEFT JOIN resource_attribute AS s3bucketname
    ON s3bucketname.resource_id = R.id
    AND s3bucketname.type = 'provider'
    AND lower(s3bucketname.attr_name) = 's3bucketname'
  LEFT JOIN resource_attribute AS s3keyprefix
    ON s3keyprefix.resource_id = R.id
    AND s3keyprefix.type = 'provider'
    AND lower(s3keyprefix.attr_name) = 's3keyprefix'
  LEFT JOIN resource_attribute AS snstopicname
    ON snstopicname.resource_id = R.id
    AND snstopicname.type = 'provider'
    AND lower(snstopicname.attr_name) = 'snstopicname'
  LEFT JOIN resource_attribute AS snstopicarn
    ON snstopicarn.resource_id = R.id
    AND snstopicarn.type = 'provider'
    AND lower(snstopicarn.attr_name) = 'snstopicarn'
  LEFT JOIN resource_attribute AS includeglobalserviceevents
    ON includeglobalserviceevents.resource_id = R.id
    AND includeglobalserviceevents.type = 'provider'
    AND lower(includeglobalserviceevents.attr_name) = 'includeglobalserviceevents'
  LEFT JOIN resource_attribute AS ismultiregiontrail
    ON ismultiregiontrail.resource_id = R.id
    AND ismultiregiontrail.type = 'provider'
    AND lower(ismultiregiontrail.attr_name) = 'ismultiregiontrail'
  LEFT JOIN resource_attribute AS homeregion
    ON homeregion.resource_id = R.id
    AND homeregion.type = 'provider'
    AND lower(homeregion.attr_name) = 'homeregion'
  LEFT JOIN resource_attribute AS trailarn
    ON trailarn.resource_id = R.id
    AND trailarn.type = 'provider'
    AND lower(trailarn.attr_name) = 'trailarn'
  LEFT JOIN resource_attribute AS logfilevalidationenabled
    ON logfilevalidationenabled.resource_id = R.id
    AND logfilevalidationenabled.type = 'provider'
    AND lower(logfilevalidationenabled.attr_name) = 'logfilevalidationenabled'
  LEFT JOIN resource_attribute AS cloudwatchlogsloggrouparn
    ON cloudwatchlogsloggrouparn.resource_id = R.id
    AND cloudwatchlogsloggrouparn.type = 'provider'
    AND lower(cloudwatchlogsloggrouparn.attr_name) = 'cloudwatchlogsloggrouparn'
  LEFT JOIN resource_attribute AS cloudwatchlogsrolearn
    ON cloudwatchlogsrolearn.resource_id = R.id
    AND cloudwatchlogsrolearn.type = 'provider'
    AND lower(cloudwatchlogsrolearn.attr_name) = 'cloudwatchlogsrolearn'
  LEFT JOIN resource_attribute AS kmskeyid
    ON kmskeyid.resource_id = R.id
    AND kmskeyid.type = 'provider'
    AND lower(kmskeyid.attr_name) = 'kmskeyid'
  LEFT JOIN resource_attribute AS hascustomeventselectors
    ON hascustomeventselectors.resource_id = R.id
    AND hascustomeventselectors.type = 'provider'
    AND lower(hascustomeventselectors.attr_name) = 'hascustomeventselectors'
  LEFT JOIN resource_attribute AS hasinsightselectors
    ON hasinsightselectors.resource_id = R.id
    AND hasinsightselectors.type = 'provider'
    AND lower(hasinsightselectors.attr_name) = 'hasinsightselectors'
  LEFT JOIN resource_attribute AS isorganizationtrail
    ON isorganizationtrail.resource_id = R.id
    AND isorganizationtrail.type = 'provider'
    AND lower(isorganizationtrail.attr_name) = 'isorganizationtrail'
  LEFT JOIN resource_attribute AS islogging
    ON islogging.resource_id = R.id
    AND islogging.type = 'provider'
    AND lower(islogging.attr_name) = 'islogging'
  LEFT JOIN resource_attribute AS latestdeliveryerror
    ON latestdeliveryerror.resource_id = R.id
    AND latestdeliveryerror.type = 'provider'
    AND lower(latestdeliveryerror.attr_name) = 'latestdeliveryerror'
  LEFT JOIN resource_attribute AS latestnotificationerror
    ON latestnotificationerror.resource_id = R.id
    AND latestnotificationerror.type = 'provider'
    AND lower(latestnotificationerror.attr_name) = 'latestnotificationerror'
  LEFT JOIN resource_attribute AS latestdeliverytime
    ON latestdeliverytime.resource_id = R.id
    AND latestdeliverytime.type = 'provider'
    AND lower(latestdeliverytime.attr_name) = 'latestdeliverytime'
  LEFT JOIN resource_attribute AS latestnotificationtime
    ON latestnotificationtime.resource_id = R.id
    AND latestnotificationtime.type = 'provider'
    AND lower(latestnotificationtime.attr_name) = 'latestnotificationtime'
  LEFT JOIN resource_attribute AS startloggingtime
    ON startloggingtime.resource_id = R.id
    AND startloggingtime.type = 'provider'
    AND lower(startloggingtime.attr_name) = 'startloggingtime'
  LEFT JOIN resource_attribute AS stoploggingtime
    ON stoploggingtime.resource_id = R.id
    AND stoploggingtime.type = 'provider'
    AND lower(stoploggingtime.attr_name) = 'stoploggingtime'
  LEFT JOIN resource_attribute AS latestcloudwatchlogsdeliveryerror
    ON latestcloudwatchlogsdeliveryerror.resource_id = R.id
    AND latestcloudwatchlogsdeliveryerror.type = 'provider'
    AND lower(latestcloudwatchlogsdeliveryerror.attr_name) = 'latestcloudwatchlogsdeliveryerror'
  LEFT JOIN resource_attribute AS latestcloudwatchlogsdeliverytime
    ON latestcloudwatchlogsdeliverytime.resource_id = R.id
    AND latestcloudwatchlogsdeliverytime.type = 'provider'
    AND lower(latestcloudwatchlogsdeliverytime.attr_name) = 'latestcloudwatchlogsdeliverytime'
  LEFT JOIN resource_attribute AS latestdigestdeliverytime
    ON latestdigestdeliverytime.resource_id = R.id
    AND latestdigestdeliverytime.type = 'provider'
    AND lower(latestdigestdeliverytime.attr_name) = 'latestdigestdeliverytime'
  LEFT JOIN resource_attribute AS latestdigestdeliveryerror
    ON latestdigestdeliveryerror.resource_id = R.id
    AND latestdigestdeliveryerror.type = 'provider'
    AND lower(latestdigestdeliveryerror.attr_name) = 'latestdigestdeliveryerror'
  LEFT JOIN resource_attribute AS latestdeliveryattempttime
    ON latestdeliveryattempttime.resource_id = R.id
    AND latestdeliveryattempttime.type = 'provider'
    AND lower(latestdeliveryattempttime.attr_name) = 'latestdeliveryattempttime'
  LEFT JOIN resource_attribute AS latestnotificationattempttime
    ON latestnotificationattempttime.resource_id = R.id
    AND latestnotificationattempttime.type = 'provider'
    AND lower(latestnotificationattempttime.attr_name) = 'latestnotificationattempttime'
  LEFT JOIN resource_attribute AS latestnotificationattemptsucceeded
    ON latestnotificationattemptsucceeded.resource_id = R.id
    AND latestnotificationattemptsucceeded.type = 'provider'
    AND lower(latestnotificationattemptsucceeded.attr_name) = 'latestnotificationattemptsucceeded'
  LEFT JOIN resource_attribute AS latestdeliveryattemptsucceeded
    ON latestdeliveryattemptsucceeded.resource_id = R.id
    AND latestdeliveryattemptsucceeded.type = 'provider'
    AND lower(latestdeliveryattemptsucceeded.attr_name) = 'latestdeliveryattemptsucceeded'
  LEFT JOIN resource_attribute AS timeloggingstarted
    ON timeloggingstarted.resource_id = R.id
    AND timeloggingstarted.type = 'provider'
    AND lower(timeloggingstarted.attr_name) = 'timeloggingstarted'
  LEFT JOIN resource_attribute AS timeloggingstopped
    ON timeloggingstopped.resource_id = R.id
    AND timeloggingstopped.type = 'provider'
    AND lower(timeloggingstopped.attr_name) = 'timeloggingstopped'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS eventselectors
    ON eventselectors.resource_id = R.id
    AND eventselectors.type = 'provider'
    AND lower(eventselectors.attr_name) = 'eventselectors'
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
  AND R.provider_type = 'Trail'
  AND R.service = 'cloudtrail'
ON CONFLICT (_id) DO UPDATE
SET
    name = EXCLUDED.name,
    s3bucketname = EXCLUDED.s3bucketname,
    s3keyprefix = EXCLUDED.s3keyprefix,
    snstopicname = EXCLUDED.snstopicname,
    snstopicarn = EXCLUDED.snstopicarn,
    includeglobalserviceevents = EXCLUDED.includeglobalserviceevents,
    ismultiregiontrail = EXCLUDED.ismultiregiontrail,
    homeregion = EXCLUDED.homeregion,
    trailarn = EXCLUDED.trailarn,
    logfilevalidationenabled = EXCLUDED.logfilevalidationenabled,
    cloudwatchlogsloggrouparn = EXCLUDED.cloudwatchlogsloggrouparn,
    cloudwatchlogsrolearn = EXCLUDED.cloudwatchlogsrolearn,
    kmskeyid = EXCLUDED.kmskeyid,
    hascustomeventselectors = EXCLUDED.hascustomeventselectors,
    hasinsightselectors = EXCLUDED.hasinsightselectors,
    isorganizationtrail = EXCLUDED.isorganizationtrail,
    islogging = EXCLUDED.islogging,
    latestdeliveryerror = EXCLUDED.latestdeliveryerror,
    latestnotificationerror = EXCLUDED.latestnotificationerror,
    latestdeliverytime = EXCLUDED.latestdeliverytime,
    latestnotificationtime = EXCLUDED.latestnotificationtime,
    startloggingtime = EXCLUDED.startloggingtime,
    stoploggingtime = EXCLUDED.stoploggingtime,
    latestcloudwatchlogsdeliveryerror = EXCLUDED.latestcloudwatchlogsdeliveryerror,
    latestcloudwatchlogsdeliverytime = EXCLUDED.latestcloudwatchlogsdeliverytime,
    latestdigestdeliverytime = EXCLUDED.latestdigestdeliverytime,
    latestdigestdeliveryerror = EXCLUDED.latestdigestdeliveryerror,
    latestdeliveryattempttime = EXCLUDED.latestdeliveryattempttime,
    latestnotificationattempttime = EXCLUDED.latestnotificationattempttime,
    latestnotificationattemptsucceeded = EXCLUDED.latestnotificationattemptsucceeded,
    latestdeliveryattemptsucceeded = EXCLUDED.latestdeliveryattemptsucceeded,
    timeloggingstarted = EXCLUDED.timeloggingstarted,
    timeloggingstopped = EXCLUDED.timeloggingstopped,
    tags = EXCLUDED.tags,
    eventselectors = EXCLUDED.eventselectors,
    _s3_bucket_id = EXCLUDED._s3_bucket_id,
    _logs_loggroup_id = EXCLUDED._logs_loggroup_id,
    _account_id = EXCLUDED._account_id
  ;

