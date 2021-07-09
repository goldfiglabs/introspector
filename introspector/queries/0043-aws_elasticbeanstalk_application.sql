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
INSERT INTO aws_elasticbeanstalk_application (
  _id,
  uri,
  provider_account_id,
  applicationarn,
  applicationname,
  description,
  datecreated,
  dateupdated,
  versions,
  configurationtemplates,
  resourcelifecycleconfig,
  tags,
  _tags,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'ApplicationArn' AS applicationarn,
  attrs.provider ->> 'ApplicationName' AS applicationname,
  attrs.provider ->> 'Description' AS description,
  (TO_TIMESTAMP(attrs.provider ->> 'DateCreated', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS datecreated,
  (TO_TIMESTAMP(attrs.provider ->> 'DateUpdated', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS dateupdated,
  attrs.provider -> 'Versions' AS versions,
  attrs.provider -> 'ConfigurationTemplates' AS configurationtemplates,
  attrs.provider -> 'ResourceLifecycleConfig' AS resourcelifecycleconfig,
  attrs.provider -> 'Tags' AS tags,
  attrs.metadata -> 'Tags' AS tags,
  
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
  AND R.provider_type = 'Application'
  AND R.service = 'elasticbeanstalk'
ON CONFLICT (_id) DO UPDATE
SET
    ApplicationArn = EXCLUDED.ApplicationArn,
    ApplicationName = EXCLUDED.ApplicationName,
    Description = EXCLUDED.Description,
    DateCreated = EXCLUDED.DateCreated,
    DateUpdated = EXCLUDED.DateUpdated,
    Versions = EXCLUDED.Versions,
    ConfigurationTemplates = EXCLUDED.ConfigurationTemplates,
    ResourceLifecycleConfig = EXCLUDED.ResourceLifecycleConfig,
    Tags = EXCLUDED.Tags,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;

