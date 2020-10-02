DROP MATERIALIZED VIEW IF EXISTS aws_apigateway_stage CASCADE;

CREATE MATERIALIZED VIEW aws_apigateway_stage AS
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
  deploymentid.attr_value #>> '{}' AS deploymentid,
  clientcertificateid.attr_value #>> '{}' AS clientcertificateid,
  stagename.attr_value #>> '{}' AS stagename,
  description.attr_value #>> '{}' AS description,
  (cacheclusterenabled.attr_value #>> '{}')::boolean AS cacheclusterenabled,
  cacheclustersize.attr_value #>> '{}' AS cacheclustersize,
  cacheclusterstatus.attr_value #>> '{}' AS cacheclusterstatus,
  methodsettings.attr_value::jsonb AS methodsettings,
  variables.attr_value::jsonb AS variables,
  documentationversion.attr_value #>> '{}' AS documentationversion,
  accesslogsettings.attr_value::jsonb AS accesslogsettings,
  canarysettings.attr_value::jsonb AS canarysettings,
  (tracingenabled.attr_value #>> '{}')::boolean AS tracingenabled,
  webaclarn.attr_value #>> '{}' AS webaclarn,
  tags.attr_value::jsonb AS tags,
  (TO_TIMESTAMP(createddate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createddate,
  (TO_TIMESTAMP(lastupdateddate.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS lastupdateddate,
  
    _restapi_id.target_id AS _restapi_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS deploymentid
    ON deploymentid.id = R.id
    AND deploymentid.attr_name = 'deploymentid'
  LEFT JOIN attrs AS clientcertificateid
    ON clientcertificateid.id = R.id
    AND clientcertificateid.attr_name = 'clientcertificateid'
  LEFT JOIN attrs AS stagename
    ON stagename.id = R.id
    AND stagename.attr_name = 'stagename'
  LEFT JOIN attrs AS description
    ON description.id = R.id
    AND description.attr_name = 'description'
  LEFT JOIN attrs AS cacheclusterenabled
    ON cacheclusterenabled.id = R.id
    AND cacheclusterenabled.attr_name = 'cacheclusterenabled'
  LEFT JOIN attrs AS cacheclustersize
    ON cacheclustersize.id = R.id
    AND cacheclustersize.attr_name = 'cacheclustersize'
  LEFT JOIN attrs AS cacheclusterstatus
    ON cacheclusterstatus.id = R.id
    AND cacheclusterstatus.attr_name = 'cacheclusterstatus'
  LEFT JOIN attrs AS methodsettings
    ON methodsettings.id = R.id
    AND methodsettings.attr_name = 'methodsettings'
  LEFT JOIN attrs AS variables
    ON variables.id = R.id
    AND variables.attr_name = 'variables'
  LEFT JOIN attrs AS documentationversion
    ON documentationversion.id = R.id
    AND documentationversion.attr_name = 'documentationversion'
  LEFT JOIN attrs AS accesslogsettings
    ON accesslogsettings.id = R.id
    AND accesslogsettings.attr_name = 'accesslogsettings'
  LEFT JOIN attrs AS canarysettings
    ON canarysettings.id = R.id
    AND canarysettings.attr_name = 'canarysettings'
  LEFT JOIN attrs AS tracingenabled
    ON tracingenabled.id = R.id
    AND tracingenabled.attr_name = 'tracingenabled'
  LEFT JOIN attrs AS webaclarn
    ON webaclarn.id = R.id
    AND webaclarn.attr_name = 'webaclarn'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS createddate
    ON createddate.id = R.id
    AND createddate.attr_name = 'createddate'
  LEFT JOIN attrs AS lastupdateddate
    ON lastupdateddate.id = R.id
    AND lastupdateddate.attr_name = 'lastupdateddate'
  LEFT JOIN (
    SELECT
      _aws_apigateway_restapi_relation.resource_id AS resource_id,
      _aws_apigateway_restapi.id AS target_id
    FROM
      resource_relation AS _aws_apigateway_restapi_relation
      INNER JOIN resource AS _aws_apigateway_restapi
        ON _aws_apigateway_restapi_relation.target_id = _aws_apigateway_restapi.id
        AND _aws_apigateway_restapi.provider_type = 'RestApi'
        AND _aws_apigateway_restapi.service = 'apigateway'
    WHERE
      _aws_apigateway_restapi_relation.relation = 'belongs-to'
  ) AS _restapi_id ON _restapi_id.resource_id = R.id
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
  AND LOWER(R.provider_type) = 'stage'
  AND R.service = 'apigateway'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_apigateway_stage;

COMMENT ON MATERIALIZED VIEW aws_apigateway_stage IS 'apigateway stage resources and their associated attributes.';

