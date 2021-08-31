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
  attrs.provider ->> 'deploymentId' AS deploymentid,
  attrs.provider ->> 'clientCertificateId' AS clientcertificateid,
  attrs.provider ->> 'stageName' AS stagename,
  attrs.provider ->> 'description' AS description,
  (attrs.provider ->> 'cacheClusterEnabled')::boolean AS cacheclusterenabled,
  attrs.provider ->> 'cacheClusterSize' AS cacheclustersize,
  attrs.provider ->> 'cacheClusterStatus' AS cacheclusterstatus,
  attrs.provider -> 'methodSettings' AS methodsettings,
  attrs.provider -> 'variables' AS variables,
  attrs.provider ->> 'documentationVersion' AS documentationversion,
  attrs.provider -> 'accessLogSettings' AS accesslogsettings,
  attrs.provider -> 'canarySettings' AS canarysettings,
  (attrs.provider ->> 'tracingEnabled')::boolean AS tracingenabled,
  attrs.provider ->> 'webAclArn' AS webaclarn,
  attrs.provider -> 'tags' AS tags,
  (TO_TIMESTAMP(attrs.provider ->> 'createdDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createddate,
  (TO_TIMESTAMP(attrs.provider ->> 'lastUpdatedDate', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS lastupdateddate,
  attrs.metadata -> 'Tags' AS tags,
  
    _restapi_id.target_id AS _restapi_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
        AND _aws_apigateway_restapi.provider_account_id = :provider_account_id
    WHERE
      _aws_apigateway_restapi_relation.relation = 'belongs-to'
      AND _aws_apigateway_restapi_relation.provider_account_id = :provider_account_id
  ) AS _restapi_id ON _restapi_id.resource_id = R.id
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
  AND R.provider_type = 'Stage'
  AND R.service = 'apigateway'
ON CONFLICT (_id) DO UPDATE
SET
    deploymentId = EXCLUDED.deploymentId,
    clientCertificateId = EXCLUDED.clientCertificateId,
    stageName = EXCLUDED.stageName,
    description = EXCLUDED.description,
    cacheClusterEnabled = EXCLUDED.cacheClusterEnabled,
    cacheClusterSize = EXCLUDED.cacheClusterSize,
    cacheClusterStatus = EXCLUDED.cacheClusterStatus,
    methodSettings = EXCLUDED.methodSettings,
    variables = EXCLUDED.variables,
    documentationVersion = EXCLUDED.documentationVersion,
    accessLogSettings = EXCLUDED.accessLogSettings,
    canarySettings = EXCLUDED.canarySettings,
    tracingEnabled = EXCLUDED.tracingEnabled,
    webAclArn = EXCLUDED.webAclArn,
    tags = EXCLUDED.tags,
    createdDate = EXCLUDED.createdDate,
    lastUpdatedDate = EXCLUDED.lastUpdatedDate,
    _tags = EXCLUDED._tags,
    _restapi_id = EXCLUDED._restapi_id,
    _account_id = EXCLUDED._account_id
  ;

