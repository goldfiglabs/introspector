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
INSERT INTO aws_elasticbeanstalk_applicationversion (
  _id,
  uri,
  provider_account_id,
  applicationversionarn,
  applicationname,
  description,
  versionlabel,
  sourcebuildinformation,
  buildarn,
  sourcebundle,
  datecreated,
  dateupdated,
  status,
  tags,
  _tags,
  _application_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'ApplicationVersionArn' AS applicationversionarn,
  attrs.provider ->> 'ApplicationName' AS applicationname,
  attrs.provider ->> 'Description' AS description,
  attrs.provider ->> 'VersionLabel' AS versionlabel,
  attrs.provider -> 'SourceBuildInformation' AS sourcebuildinformation,
  attrs.provider ->> 'BuildArn' AS buildarn,
  attrs.provider -> 'SourceBundle' AS sourcebundle,
  (TO_TIMESTAMP(attrs.provider ->> 'DateCreated', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS datecreated,
  (TO_TIMESTAMP(attrs.provider ->> 'DateUpdated', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS dateupdated,
  attrs.provider ->> 'Status' AS status,
  attrs.provider -> 'Tags' AS tags,
  attrs.metadata -> 'Tags' AS tags,
  
    _application_id.target_id AS _application_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_elasticbeanstalk_application_relation.resource_id AS resource_id,
      _aws_elasticbeanstalk_application.id AS target_id
    FROM
      resource_relation AS _aws_elasticbeanstalk_application_relation
      INNER JOIN resource AS _aws_elasticbeanstalk_application
        ON _aws_elasticbeanstalk_application_relation.target_id = _aws_elasticbeanstalk_application.id
        AND _aws_elasticbeanstalk_application.provider_type = 'Application'
        AND _aws_elasticbeanstalk_application.service = 'elasticbeanstalk'
        AND _aws_elasticbeanstalk_application.provider_account_id = :provider_account_id
    WHERE
      _aws_elasticbeanstalk_application_relation.relation = 'belongs-to'
      AND _aws_elasticbeanstalk_application_relation.provider_account_id = :provider_account_id
  ) AS _application_id ON _application_id.resource_id = R.id
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
  AND R.provider_type = 'ApplicationVersion'
  AND R.service = 'elasticbeanstalk'
ON CONFLICT (_id) DO UPDATE
SET
    ApplicationVersionArn = EXCLUDED.ApplicationVersionArn,
    ApplicationName = EXCLUDED.ApplicationName,
    Description = EXCLUDED.Description,
    VersionLabel = EXCLUDED.VersionLabel,
    SourceBuildInformation = EXCLUDED.SourceBuildInformation,
    BuildArn = EXCLUDED.BuildArn,
    SourceBundle = EXCLUDED.SourceBundle,
    DateCreated = EXCLUDED.DateCreated,
    DateUpdated = EXCLUDED.DateUpdated,
    Status = EXCLUDED.Status,
    Tags = EXCLUDED.Tags,
    _tags = EXCLUDED._tags,
    _application_id = EXCLUDED._application_id,
    _account_id = EXCLUDED._account_id
  ;

