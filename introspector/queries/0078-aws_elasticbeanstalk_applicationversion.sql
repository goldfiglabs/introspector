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
  applicationversionarn.attr_value #>> '{}' AS applicationversionarn,
  applicationname.attr_value #>> '{}' AS applicationname,
  description.attr_value #>> '{}' AS description,
  versionlabel.attr_value #>> '{}' AS versionlabel,
  sourcebuildinformation.attr_value::jsonb AS sourcebuildinformation,
  buildarn.attr_value #>> '{}' AS buildarn,
  sourcebundle.attr_value::jsonb AS sourcebundle,
  (TO_TIMESTAMP(datecreated.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS datecreated,
  (TO_TIMESTAMP(dateupdated.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS dateupdated,
  status.attr_value #>> '{}' AS status,
  tags.attr_value::jsonb AS tags,
  _tags.attr_value::jsonb AS _tags,
  
    _application_id.target_id AS _application_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS applicationversionarn
    ON applicationversionarn.resource_id = R.id
    AND applicationversionarn.type = 'provider'
    AND lower(applicationversionarn.attr_name) = 'applicationversionarn'
  LEFT JOIN resource_attribute AS applicationname
    ON applicationname.resource_id = R.id
    AND applicationname.type = 'provider'
    AND lower(applicationname.attr_name) = 'applicationname'
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
  LEFT JOIN resource_attribute AS versionlabel
    ON versionlabel.resource_id = R.id
    AND versionlabel.type = 'provider'
    AND lower(versionlabel.attr_name) = 'versionlabel'
  LEFT JOIN resource_attribute AS sourcebuildinformation
    ON sourcebuildinformation.resource_id = R.id
    AND sourcebuildinformation.type = 'provider'
    AND lower(sourcebuildinformation.attr_name) = 'sourcebuildinformation'
  LEFT JOIN resource_attribute AS buildarn
    ON buildarn.resource_id = R.id
    AND buildarn.type = 'provider'
    AND lower(buildarn.attr_name) = 'buildarn'
  LEFT JOIN resource_attribute AS sourcebundle
    ON sourcebundle.resource_id = R.id
    AND sourcebundle.type = 'provider'
    AND lower(sourcebundle.attr_name) = 'sourcebundle'
  LEFT JOIN resource_attribute AS datecreated
    ON datecreated.resource_id = R.id
    AND datecreated.type = 'provider'
    AND lower(datecreated.attr_name) = 'datecreated'
  LEFT JOIN resource_attribute AS dateupdated
    ON dateupdated.resource_id = R.id
    AND dateupdated.type = 'provider'
    AND lower(dateupdated.attr_name) = 'dateupdated'
  LEFT JOIN resource_attribute AS status
    ON status.resource_id = R.id
    AND status.type = 'provider'
    AND lower(status.attr_name) = 'status'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
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
    WHERE
      _aws_elasticbeanstalk_application_relation.relation = 'belongs-to'
  ) AS _application_id ON _application_id.resource_id = R.id
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
      GROUP BY _aws_organizations_account_relation.resource_id
      HAVING COUNT(*) = 1
    ) AS unique_account_mapping
    INNER JOIN resource_relation AS _aws_organizations_account_relation
      ON _aws_organizations_account_relation.resource_id = unique_account_mapping.resource_id
    INNER JOIN resource AS _aws_organizations_account
      ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
      AND _aws_organizations_account.provider_type = 'Account'
      AND _aws_organizations_account.service = 'organizations'
    WHERE
        _aws_organizations_account_relation.relation = 'in'
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  PA.provider = 'aws'
  AND R.provider_type = 'ApplicationVersion'
  AND R.service = 'elasticbeanstalk'
ON CONFLICT (_id) DO UPDATE
SET
    applicationversionarn = EXCLUDED.applicationversionarn,
    applicationname = EXCLUDED.applicationname,
    description = EXCLUDED.description,
    versionlabel = EXCLUDED.versionlabel,
    sourcebuildinformation = EXCLUDED.sourcebuildinformation,
    buildarn = EXCLUDED.buildarn,
    sourcebundle = EXCLUDED.sourcebundle,
    datecreated = EXCLUDED.datecreated,
    dateupdated = EXCLUDED.dateupdated,
    status = EXCLUDED.status,
    tags = EXCLUDED.tags,
    _tags = EXCLUDED._tags,
    _application_id = EXCLUDED._application_id,
    _account_id = EXCLUDED._account_id
  ;

