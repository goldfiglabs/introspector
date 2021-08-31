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
  attrs.provider ->> 'name' AS name,
  attrs.provider ->> 'arn' AS arn,
  (TO_TIMESTAMP(attrs.provider ->> 'createdAt', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdat,
  attrs.provider ->> 'version' AS version,
  attrs.provider ->> 'endpoint' AS endpoint,
  attrs.provider ->> 'roleArn' AS rolearn,
  attrs.provider -> 'resourcesVpcConfig' AS resourcesvpcconfig,
  attrs.provider -> 'kubernetesNetworkConfig' AS kubernetesnetworkconfig,
  attrs.provider -> 'logging' AS logging,
  attrs.provider -> 'identity' AS identity,
  attrs.provider ->> 'status' AS status,
  attrs.provider -> 'certificateAuthority' AS certificateauthority,
  attrs.provider ->> 'clientRequestToken' AS clientrequesttoken,
  attrs.provider ->> 'platformVersion' AS platformversion,
  attrs.provider -> 'tags' AS tags,
  attrs.provider -> 'encryptionConfig' AS encryptionconfig,
  attrs.metadata -> 'Tags' AS tags,
  
    _iam_role_id.target_id AS _iam_role_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
  AND R.provider_type = 'Cluster'
  AND R.service = 'eks'
ON CONFLICT (_id) DO UPDATE
SET
    name = EXCLUDED.name,
    arn = EXCLUDED.arn,
    createdAt = EXCLUDED.createdAt,
    version = EXCLUDED.version,
    endpoint = EXCLUDED.endpoint,
    roleArn = EXCLUDED.roleArn,
    resourcesVpcConfig = EXCLUDED.resourcesVpcConfig,
    kubernetesNetworkConfig = EXCLUDED.kubernetesNetworkConfig,
    logging = EXCLUDED.logging,
    identity = EXCLUDED.identity,
    status = EXCLUDED.status,
    certificateAuthority = EXCLUDED.certificateAuthority,
    clientRequestToken = EXCLUDED.clientRequestToken,
    platformVersion = EXCLUDED.platformVersion,
    tags = EXCLUDED.tags,
    encryptionConfig = EXCLUDED.encryptionConfig,
    _tags = EXCLUDED._tags,
    _iam_role_id = EXCLUDED._iam_role_id,
    _account_id = EXCLUDED._account_id
  ;

