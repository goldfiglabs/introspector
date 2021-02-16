INSERT INTO aws_elasticbeanstalk_application
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  applicationarn.attr_value #>> '{}' AS applicationarn,
  applicationname.attr_value #>> '{}' AS applicationname,
  description.attr_value #>> '{}' AS description,
  (TO_TIMESTAMP(datecreated.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS datecreated,
  (TO_TIMESTAMP(dateupdated.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS dateupdated,
  versions.attr_value::jsonb AS versions,
  configurationtemplates.attr_value::jsonb AS configurationtemplates,
  resourcelifecycleconfig.attr_value::jsonb AS resourcelifecycleconfig,
  tags.attr_value::jsonb AS tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS applicationarn
    ON applicationarn.resource_id = R.id
    AND applicationarn.type = 'provider'
    AND lower(applicationarn.attr_name) = 'applicationarn'
  LEFT JOIN resource_attribute AS applicationname
    ON applicationname.resource_id = R.id
    AND applicationname.type = 'provider'
    AND lower(applicationname.attr_name) = 'applicationname'
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
  LEFT JOIN resource_attribute AS datecreated
    ON datecreated.resource_id = R.id
    AND datecreated.type = 'provider'
    AND lower(datecreated.attr_name) = 'datecreated'
  LEFT JOIN resource_attribute AS dateupdated
    ON dateupdated.resource_id = R.id
    AND dateupdated.type = 'provider'
    AND lower(dateupdated.attr_name) = 'dateupdated'
  LEFT JOIN resource_attribute AS versions
    ON versions.resource_id = R.id
    AND versions.type = 'provider'
    AND lower(versions.attr_name) = 'versions'
  LEFT JOIN resource_attribute AS configurationtemplates
    ON configurationtemplates.resource_id = R.id
    AND configurationtemplates.type = 'provider'
    AND lower(configurationtemplates.attr_name) = 'configurationtemplates'
  LEFT JOIN resource_attribute AS resourcelifecycleconfig
    ON resourcelifecycleconfig.resource_id = R.id
    AND resourcelifecycleconfig.type = 'provider'
    AND lower(resourcelifecycleconfig.attr_name) = 'resourcelifecycleconfig'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
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
  AND R.provider_type = 'Application'
  AND R.service = 'elasticbeanstalk'
ON CONFLICT (_id) DO UPDATE
SET
    applicationarn = EXCLUDED.applicationarn,
    applicationname = EXCLUDED.applicationname,
    description = EXCLUDED.description,
    datecreated = EXCLUDED.datecreated,
    dateupdated = EXCLUDED.dateupdated,
    versions = EXCLUDED.versions,
    configurationtemplates = EXCLUDED.configurationtemplates,
    resourcelifecycleconfig = EXCLUDED.resourcelifecycleconfig,
    tags = EXCLUDED.tags,
    _account_id = EXCLUDED._account_id
  ;

