DROP MATERIALIZED VIEW IF EXISTS aws_logs_loggroup CASCADE;

CREATE MATERIALIZED VIEW aws_logs_loggroup AS
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
  loggroupname.attr_value #>> '{}' AS loggroupname,
  (creationtime.attr_value #>> '{}')::bigint AS creationtime,
  (retentionindays.attr_value #>> '{}')::integer AS retentionindays,
  (metricfiltercount.attr_value #>> '{}')::integer AS metricfiltercount,
  arn.attr_value #>> '{}' AS arn,
  (storedbytes.attr_value #>> '{}')::bigint AS storedbytes,
  kmskeyid.attr_value #>> '{}' AS kmskeyid,
  tags.attr_value::jsonb AS tags,
  metricfilters.attr_value::jsonb AS metricfilters,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS loggroupname
    ON loggroupname.id = R.id
    AND loggroupname.attr_name = 'loggroupname'
  LEFT JOIN attrs AS creationtime
    ON creationtime.id = R.id
    AND creationtime.attr_name = 'creationtime'
  LEFT JOIN attrs AS retentionindays
    ON retentionindays.id = R.id
    AND retentionindays.attr_name = 'retentionindays'
  LEFT JOIN attrs AS metricfiltercount
    ON metricfiltercount.id = R.id
    AND metricfiltercount.attr_name = 'metricfiltercount'
  LEFT JOIN attrs AS arn
    ON arn.id = R.id
    AND arn.attr_name = 'arn'
  LEFT JOIN attrs AS storedbytes
    ON storedbytes.id = R.id
    AND storedbytes.attr_name = 'storedbytes'
  LEFT JOIN attrs AS kmskeyid
    ON kmskeyid.id = R.id
    AND kmskeyid.attr_name = 'kmskeyid'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS metricfilters
    ON metricfilters.id = R.id
    AND metricfilters.attr_name = 'metricfilters'
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
  AND LOWER(R.provider_type) = 'loggroup'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_logs_loggroup;

COMMENT ON MATERIALIZED VIEW aws_logs_loggroup IS 'logs loggroup resources and their associated attributes.';

