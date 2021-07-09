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
  policy,
  _policy,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'logGroupName' AS loggroupname,
  (attrs.provider ->> 'creationTime')::bigint AS creationtime,
  (attrs.provider ->> 'retentionInDays')::integer AS retentionindays,
  (attrs.provider ->> 'metricFilterCount')::integer AS metricfiltercount,
  attrs.provider ->> 'arn' AS arn,
  (attrs.provider ->> 'storedBytes')::bigint AS storedbytes,
  attrs.provider ->> 'kmsKeyId' AS kmskeyid,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider -> 'MetricFilters' AS metricfilters,
  attrs.metadata -> 'Tags' AS tags,
  attrs.provider -> 'policy' AS policy,
  attrs.metadata -> 'Policy' AS policy,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
  AND R.provider_type = 'LogGroup'
  AND R.service = 'logs'
ON CONFLICT (_id) DO UPDATE
SET
    logGroupName = EXCLUDED.logGroupName,
    creationTime = EXCLUDED.creationTime,
    retentionInDays = EXCLUDED.retentionInDays,
    metricFilterCount = EXCLUDED.metricFilterCount,
    arn = EXCLUDED.arn,
    storedBytes = EXCLUDED.storedBytes,
    kmsKeyId = EXCLUDED.kmsKeyId,
    Tags = EXCLUDED.Tags,
    MetricFilters = EXCLUDED.MetricFilters,
    _tags = EXCLUDED._tags,
    policy = EXCLUDED.policy,
    _policy = EXCLUDED._policy,
    _account_id = EXCLUDED._account_id
  ;

