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
  includeglobalserviceevents.attr_value::boolean AS includeglobalserviceevents,
  ismultiregiontrail.attr_value::boolean AS ismultiregiontrail,
  homeregion.attr_value #>> '{}' AS homeregion,
  trailarn.attr_value #>> '{}' AS trailarn,
  logfilevalidationenabled.attr_value::boolean AS logfilevalidationenabled,
  cloudwatchlogsloggrouparn.attr_value #>> '{}' AS cloudwatchlogsloggrouparn,
  cloudwatchlogsrolearn.attr_value #>> '{}' AS cloudwatchlogsrolearn,
  kmskeyid.attr_value #>> '{}' AS kmskeyid,
  hascustomeventselectors.attr_value::boolean AS hascustomeventselectors,
  hasinsightselectors.attr_value::boolean AS hasinsightselectors,
  isorganizationtrail.attr_value::boolean AS isorganizationtrail,
  
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

