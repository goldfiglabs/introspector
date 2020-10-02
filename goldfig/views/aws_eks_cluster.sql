DROP MATERIALIZED VIEW IF EXISTS aws_eks_cluster CASCADE;

CREATE MATERIALIZED VIEW aws_eks_cluster AS
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
  LEFT JOIN attrs AS name
    ON name.id = R.id
    AND name.attr_name = 'name'
  LEFT JOIN attrs AS arn
    ON arn.id = R.id
    AND arn.attr_name = 'arn'
  LEFT JOIN attrs AS createdat
    ON createdat.id = R.id
    AND createdat.attr_name = 'createdat'
  LEFT JOIN attrs AS version
    ON version.id = R.id
    AND version.attr_name = 'version'
  LEFT JOIN attrs AS endpoint
    ON endpoint.id = R.id
    AND endpoint.attr_name = 'endpoint'
  LEFT JOIN attrs AS rolearn
    ON rolearn.id = R.id
    AND rolearn.attr_name = 'rolearn'
  LEFT JOIN attrs AS resourcesvpcconfig
    ON resourcesvpcconfig.id = R.id
    AND resourcesvpcconfig.attr_name = 'resourcesvpcconfig'
  LEFT JOIN attrs AS logging
    ON logging.id = R.id
    AND logging.attr_name = 'logging'
  LEFT JOIN attrs AS identity
    ON identity.id = R.id
    AND identity.attr_name = 'identity'
  LEFT JOIN attrs AS status
    ON status.id = R.id
    AND status.attr_name = 'status'
  LEFT JOIN attrs AS certificateauthority
    ON certificateauthority.id = R.id
    AND certificateauthority.attr_name = 'certificateauthority'
  LEFT JOIN attrs AS clientrequesttoken
    ON clientrequesttoken.id = R.id
    AND clientrequesttoken.attr_name = 'clientrequesttoken'
  LEFT JOIN attrs AS platformversion
    ON platformversion.id = R.id
    AND platformversion.attr_name = 'platformversion'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS encryptionconfig
    ON encryptionconfig.id = R.id
    AND encryptionconfig.attr_name = 'encryptionconfig'
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
  AND LOWER(R.provider_type) = 'cluster'
  AND R.service = 'eks'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_eks_cluster;

COMMENT ON MATERIALIZED VIEW aws_eks_cluster IS 'eks cluster resources and their associated attributes.';

