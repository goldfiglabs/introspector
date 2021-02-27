INSERT INTO aws_apigateway_stage (
  _id,
  uri,
  provider_account_id,
  deploymentid,
  clientcertificateid,
  stagename,
  description,
  cacheclusterenabled,
  cacheclustersize,
  cacheclusterstatus,
  methodsettings,
  variables,
  documentationversion,
  accesslogsettings,
  canarysettings,
  tracingenabled,
  webaclarn,
  tags,
  createddate,
  lastupdateddate,
  _tags,
  _restapi_id,_account_id
)
SELECT
  R.id AS _id,
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
  _tags.attr_value::jsonb AS _tags,
  
    _restapi_id.target_id AS _restapi_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS deploymentid
    ON deploymentid.resource_id = R.id
    AND deploymentid.type = 'provider'
    AND lower(deploymentid.attr_name) = 'deploymentid'
  LEFT JOIN resource_attribute AS clientcertificateid
    ON clientcertificateid.resource_id = R.id
    AND clientcertificateid.type = 'provider'
    AND lower(clientcertificateid.attr_name) = 'clientcertificateid'
  LEFT JOIN resource_attribute AS stagename
    ON stagename.resource_id = R.id
    AND stagename.type = 'provider'
    AND lower(stagename.attr_name) = 'stagename'
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
  LEFT JOIN resource_attribute AS cacheclusterenabled
    ON cacheclusterenabled.resource_id = R.id
    AND cacheclusterenabled.type = 'provider'
    AND lower(cacheclusterenabled.attr_name) = 'cacheclusterenabled'
  LEFT JOIN resource_attribute AS cacheclustersize
    ON cacheclustersize.resource_id = R.id
    AND cacheclustersize.type = 'provider'
    AND lower(cacheclustersize.attr_name) = 'cacheclustersize'
  LEFT JOIN resource_attribute AS cacheclusterstatus
    ON cacheclusterstatus.resource_id = R.id
    AND cacheclusterstatus.type = 'provider'
    AND lower(cacheclusterstatus.attr_name) = 'cacheclusterstatus'
  LEFT JOIN resource_attribute AS methodsettings
    ON methodsettings.resource_id = R.id
    AND methodsettings.type = 'provider'
    AND lower(methodsettings.attr_name) = 'methodsettings'
  LEFT JOIN resource_attribute AS variables
    ON variables.resource_id = R.id
    AND variables.type = 'provider'
    AND lower(variables.attr_name) = 'variables'
  LEFT JOIN resource_attribute AS documentationversion
    ON documentationversion.resource_id = R.id
    AND documentationversion.type = 'provider'
    AND lower(documentationversion.attr_name) = 'documentationversion'
  LEFT JOIN resource_attribute AS accesslogsettings
    ON accesslogsettings.resource_id = R.id
    AND accesslogsettings.type = 'provider'
    AND lower(accesslogsettings.attr_name) = 'accesslogsettings'
  LEFT JOIN resource_attribute AS canarysettings
    ON canarysettings.resource_id = R.id
    AND canarysettings.type = 'provider'
    AND lower(canarysettings.attr_name) = 'canarysettings'
  LEFT JOIN resource_attribute AS tracingenabled
    ON tracingenabled.resource_id = R.id
    AND tracingenabled.type = 'provider'
    AND lower(tracingenabled.attr_name) = 'tracingenabled'
  LEFT JOIN resource_attribute AS webaclarn
    ON webaclarn.resource_id = R.id
    AND webaclarn.type = 'provider'
    AND lower(webaclarn.attr_name) = 'webaclarn'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS createddate
    ON createddate.resource_id = R.id
    AND createddate.type = 'provider'
    AND lower(createddate.attr_name) = 'createddate'
  LEFT JOIN resource_attribute AS lastupdateddate
    ON lastupdateddate.resource_id = R.id
    AND lastupdateddate.type = 'provider'
    AND lower(lastupdateddate.attr_name) = 'lastupdateddate'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
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
  AND R.provider_type = 'Stage'
  AND R.service = 'apigateway'
ON CONFLICT (_id) DO UPDATE
SET
    deploymentid = EXCLUDED.deploymentid,
    clientcertificateid = EXCLUDED.clientcertificateid,
    stagename = EXCLUDED.stagename,
    description = EXCLUDED.description,
    cacheclusterenabled = EXCLUDED.cacheclusterenabled,
    cacheclustersize = EXCLUDED.cacheclustersize,
    cacheclusterstatus = EXCLUDED.cacheclusterstatus,
    methodsettings = EXCLUDED.methodsettings,
    variables = EXCLUDED.variables,
    documentationversion = EXCLUDED.documentationversion,
    accesslogsettings = EXCLUDED.accesslogsettings,
    canarysettings = EXCLUDED.canarysettings,
    tracingenabled = EXCLUDED.tracingenabled,
    webaclarn = EXCLUDED.webaclarn,
    tags = EXCLUDED.tags,
    createddate = EXCLUDED.createddate,
    lastupdateddate = EXCLUDED.lastupdateddate,
    _tags = EXCLUDED._tags,
    _restapi_id = EXCLUDED._restapi_id,
    _account_id = EXCLUDED._account_id
  ;

