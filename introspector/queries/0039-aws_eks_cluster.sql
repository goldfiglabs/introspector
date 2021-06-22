INSERT INTO aws_eks_cluster (
  _id,
  uri,
  provider_account_id,
  name,
  arn,
  createdat,
  version,
  endpoint,
  rolearn,
  resourcesvpcconfig,
  kubernetesnetworkconfig,
  logging,
  identity,
  status,
  certificateauthority,
  clientrequesttoken,
  platformversion,
  tags,
  encryptionconfig,
  _tags,
  _iam_role_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  name.attr_value #>> '{}' AS name,
  arn.attr_value #>> '{}' AS arn,
  (TO_TIMESTAMP(createdat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdat,
  version.attr_value #>> '{}' AS version,
  endpoint.attr_value #>> '{}' AS endpoint,
  rolearn.attr_value #>> '{}' AS rolearn,
  resourcesvpcconfig.attr_value::jsonb AS resourcesvpcconfig,
  kubernetesnetworkconfig.attr_value::jsonb AS kubernetesnetworkconfig,
  logging.attr_value::jsonb AS logging,
  identity.attr_value::jsonb AS identity,
  status.attr_value #>> '{}' AS status,
  certificateauthority.attr_value::jsonb AS certificateauthority,
  clientrequesttoken.attr_value #>> '{}' AS clientrequesttoken,
  platformversion.attr_value #>> '{}' AS platformversion,
  tags.attr_value::jsonb AS tags,
  encryptionconfig.attr_value::jsonb AS encryptionconfig,
  _tags.attr_value::jsonb AS _tags,
  
    _iam_role_id.target_id AS _iam_role_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS name
    ON name.resource_id = R.id
    AND name.type = 'provider'
    AND lower(name.attr_name) = 'name'
    AND name.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS arn
    ON arn.resource_id = R.id
    AND arn.type = 'provider'
    AND lower(arn.attr_name) = 'arn'
    AND arn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS createdat
    ON createdat.resource_id = R.id
    AND createdat.type = 'provider'
    AND lower(createdat.attr_name) = 'createdat'
    AND createdat.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS version
    ON version.resource_id = R.id
    AND version.type = 'provider'
    AND lower(version.attr_name) = 'version'
    AND version.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS endpoint
    ON endpoint.resource_id = R.id
    AND endpoint.type = 'provider'
    AND lower(endpoint.attr_name) = 'endpoint'
    AND endpoint.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS rolearn
    ON rolearn.resource_id = R.id
    AND rolearn.type = 'provider'
    AND lower(rolearn.attr_name) = 'rolearn'
    AND rolearn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS resourcesvpcconfig
    ON resourcesvpcconfig.resource_id = R.id
    AND resourcesvpcconfig.type = 'provider'
    AND lower(resourcesvpcconfig.attr_name) = 'resourcesvpcconfig'
    AND resourcesvpcconfig.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS kubernetesnetworkconfig
    ON kubernetesnetworkconfig.resource_id = R.id
    AND kubernetesnetworkconfig.type = 'provider'
    AND lower(kubernetesnetworkconfig.attr_name) = 'kubernetesnetworkconfig'
    AND kubernetesnetworkconfig.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS logging
    ON logging.resource_id = R.id
    AND logging.type = 'provider'
    AND lower(logging.attr_name) = 'logging'
    AND logging.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS identity
    ON identity.resource_id = R.id
    AND identity.type = 'provider'
    AND lower(identity.attr_name) = 'identity'
    AND identity.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS status
    ON status.resource_id = R.id
    AND status.type = 'provider'
    AND lower(status.attr_name) = 'status'
    AND status.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS certificateauthority
    ON certificateauthority.resource_id = R.id
    AND certificateauthority.type = 'provider'
    AND lower(certificateauthority.attr_name) = 'certificateauthority'
    AND certificateauthority.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS clientrequesttoken
    ON clientrequesttoken.resource_id = R.id
    AND clientrequesttoken.type = 'provider'
    AND lower(clientrequesttoken.attr_name) = 'clientrequesttoken'
    AND clientrequesttoken.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS platformversion
    ON platformversion.resource_id = R.id
    AND platformversion.type = 'provider'
    AND lower(platformversion.attr_name) = 'platformversion'
    AND platformversion.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
    AND tags.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS encryptionconfig
    ON encryptionconfig.resource_id = R.id
    AND encryptionconfig.type = 'provider'
    AND lower(encryptionconfig.attr_name) = 'encryptionconfig'
    AND encryptionconfig.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
  LEFT JOIN (
    SELECT
      _aws_iam_role_relation.resource_id AS resource_id,
      _aws_iam_role.id AS target_id
    FROM
      resource_relation AS _aws_iam_role_relation
      INNER JOIN resource AS _aws_iam_role
        ON _aws_iam_role_relation.target_id = _aws_iam_role.id
        AND _aws_iam_role.provider_type = 'Role'
        AND _aws_iam_role.service = 'iam'
        AND _aws_iam_role.provider_account_id = :provider_account_id
    WHERE
      _aws_iam_role_relation.relation = 'acts-as'
      AND _aws_iam_role_relation.provider_account_id = :provider_account_id
  ) AS _iam_role_id ON _iam_role_id.resource_id = R.id
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
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
      GROUP BY _aws_organizations_account_relation.resource_id
      HAVING COUNT(*) = 1
    ) AS unique_account_mapping
    INNER JOIN resource_relation AS _aws_organizations_account_relation
      ON _aws_organizations_account_relation.resource_id = unique_account_mapping.resource_id
    INNER JOIN resource AS _aws_organizations_account
      ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
      AND _aws_organizations_account.provider_type = 'Account'
      AND _aws_organizations_account.service = 'organizations'
      AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
    WHERE
        _aws_organizations_account_relation.relation = 'in'
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND PA.provider = 'aws'
  AND R.provider_type = 'Cluster'
  AND R.service = 'eks'
ON CONFLICT (_id) DO UPDATE
SET
    name = EXCLUDED.name,
    arn = EXCLUDED.arn,
    createdat = EXCLUDED.createdat,
    version = EXCLUDED.version,
    endpoint = EXCLUDED.endpoint,
    rolearn = EXCLUDED.rolearn,
    resourcesvpcconfig = EXCLUDED.resourcesvpcconfig,
    kubernetesnetworkconfig = EXCLUDED.kubernetesnetworkconfig,
    logging = EXCLUDED.logging,
    identity = EXCLUDED.identity,
    status = EXCLUDED.status,
    certificateauthority = EXCLUDED.certificateauthority,
    clientrequesttoken = EXCLUDED.clientrequesttoken,
    platformversion = EXCLUDED.platformversion,
    tags = EXCLUDED.tags,
    encryptionconfig = EXCLUDED.encryptionconfig,
    _tags = EXCLUDED._tags,
    _iam_role_id = EXCLUDED._iam_role_id,
    _account_id = EXCLUDED._account_id
  ;

