INSERT INTO aws_logs_loggroup (
  _id,
  uri,
  provider_account_id,
  loggroupname,
  creationtime,
  retentionindays,
  metricfiltercount,
  arn,
  storedbytes,
  kmskeyid,
  tags,
  metricfilters,
  _tags,
  _account_id
)
SELECT
  R.id AS _id,
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
  _tags.attr_value::jsonb AS _tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS loggroupname
    ON loggroupname.resource_id = R.id
    AND loggroupname.type = 'provider'
    AND lower(loggroupname.attr_name) = 'loggroupname'
  LEFT JOIN resource_attribute AS creationtime
    ON creationtime.resource_id = R.id
    AND creationtime.type = 'provider'
    AND lower(creationtime.attr_name) = 'creationtime'
  LEFT JOIN resource_attribute AS retentionindays
    ON retentionindays.resource_id = R.id
    AND retentionindays.type = 'provider'
    AND lower(retentionindays.attr_name) = 'retentionindays'
  LEFT JOIN resource_attribute AS metricfiltercount
    ON metricfiltercount.resource_id = R.id
    AND metricfiltercount.type = 'provider'
    AND lower(metricfiltercount.attr_name) = 'metricfiltercount'
  LEFT JOIN resource_attribute AS arn
    ON arn.resource_id = R.id
    AND arn.type = 'provider'
    AND lower(arn.attr_name) = 'arn'
  LEFT JOIN resource_attribute AS storedbytes
    ON storedbytes.resource_id = R.id
    AND storedbytes.type = 'provider'
    AND lower(storedbytes.attr_name) = 'storedbytes'
  LEFT JOIN resource_attribute AS kmskeyid
    ON kmskeyid.resource_id = R.id
    AND kmskeyid.type = 'provider'
    AND lower(kmskeyid.attr_name) = 'kmskeyid'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS metricfilters
    ON metricfilters.resource_id = R.id
    AND metricfilters.type = 'provider'
    AND lower(metricfilters.attr_name) = 'metricfilters'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = '_tags'
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
  AND R.provider_type = 'LogGroup'
  AND R.service = 'logs'
ON CONFLICT (_id) DO UPDATE
SET
    loggroupname = EXCLUDED.loggroupname,
    creationtime = EXCLUDED.creationtime,
    retentionindays = EXCLUDED.retentionindays,
    metricfiltercount = EXCLUDED.metricfiltercount,
    arn = EXCLUDED.arn,
    storedbytes = EXCLUDED.storedbytes,
    kmskeyid = EXCLUDED.kmskeyid,
    tags = EXCLUDED.tags,
    metricfilters = EXCLUDED.metricfilters,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;

