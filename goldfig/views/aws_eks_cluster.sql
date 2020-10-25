DROP MATERIALIZED VIEW IF EXISTS aws_eks_cluster CASCADE;

CREATE MATERIALIZED VIEW aws_eks_cluster AS
SELECT
  R.id AS resource_id,
  R.uri,
  R.provider_account_id,
  name.attr_value #>> '{}' AS name,
  arn.attr_value #>> '{}' AS arn,
  (TO_TIMESTAMP(createdat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdat,
  version.attr_value #>> '{}' AS version,
  endpoint.attr_value #>> '{}' AS endpoint,
  rolearn.attr_value #>> '{}' AS rolearn,
  resourcesvpcconfig.attr_value::jsonb AS resourcesvpcconfig,
  logging.attr_value::jsonb AS logging,
  identity.attr_value::jsonb AS identity,
  status.attr_value #>> '{}' AS status,
  certificateauthority.attr_value::jsonb AS certificateauthority,
  clientrequesttoken.attr_value #>> '{}' AS clientrequesttoken,
  platformversion.attr_value #>> '{}' AS platformversion,
  tags.attr_value::jsonb AS tags,
  encryptionconfig.attr_value::jsonb AS encryptionconfig,
  
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
  LEFT JOIN resource_attribute AS arn
    ON arn.resource_id = R.id
    AND arn.type = 'provider'
    AND lower(arn.attr_name) = 'arn'
  LEFT JOIN resource_attribute AS createdat
    ON createdat.resource_id = R.id
    AND createdat.type = 'provider'
    AND lower(createdat.attr_name) = 'createdat'
  LEFT JOIN resource_attribute AS version
    ON version.resource_id = R.id
    AND version.type = 'provider'
    AND lower(version.attr_name) = 'version'
  LEFT JOIN resource_attribute AS endpoint
    ON endpoint.resource_id = R.id
    AND endpoint.type = 'provider'
    AND lower(endpoint.attr_name) = 'endpoint'
  LEFT JOIN resource_attribute AS rolearn
    ON rolearn.resource_id = R.id
    AND rolearn.type = 'provider'
    AND lower(rolearn.attr_name) = 'rolearn'
  LEFT JOIN resource_attribute AS resourcesvpcconfig
    ON resourcesvpcconfig.resource_id = R.id
    AND resourcesvpcconfig.type = 'provider'
    AND lower(resourcesvpcconfig.attr_name) = 'resourcesvpcconfig'
  LEFT JOIN resource_attribute AS logging
    ON logging.resource_id = R.id
    AND logging.type = 'provider'
    AND lower(logging.attr_name) = 'logging'
  LEFT JOIN resource_attribute AS identity
    ON identity.resource_id = R.id
    AND identity.type = 'provider'
    AND lower(identity.attr_name) = 'identity'
  LEFT JOIN resource_attribute AS status
    ON status.resource_id = R.id
    AND status.type = 'provider'
    AND lower(status.attr_name) = 'status'
  LEFT JOIN resource_attribute AS certificateauthority
    ON certificateauthority.resource_id = R.id
    AND certificateauthority.type = 'provider'
    AND lower(certificateauthority.attr_name) = 'certificateauthority'
  LEFT JOIN resource_attribute AS clientrequesttoken
    ON clientrequesttoken.resource_id = R.id
    AND clientrequesttoken.type = 'provider'
    AND lower(clientrequesttoken.attr_name) = 'clientrequesttoken'
  LEFT JOIN resource_attribute AS platformversion
    ON platformversion.resource_id = R.id
    AND platformversion.type = 'provider'
    AND lower(platformversion.attr_name) = 'platformversion'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS encryptionconfig
    ON encryptionconfig.resource_id = R.id
    AND encryptionconfig.type = 'provider'
    AND lower(encryptionconfig.attr_name) = 'encryptionconfig'
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
    WHERE
      _aws_iam_role_relation.relation = 'acts-as'
  ) AS _iam_role_id ON _iam_role_id.resource_id = R.id
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
  AND R.provider_type = 'Cluster'
  AND R.service = 'eks'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_eks_cluster;

COMMENT ON MATERIALIZED VIEW aws_eks_cluster IS 'eks Cluster resources and their associated attributes.';

