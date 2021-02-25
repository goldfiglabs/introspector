INSERT INTO aws_glacier_vault (
  _id,
  uri,
  provider_account_id,
  vaultarn,
  vaultname,
  creationdate,
  lastinventorydate,
  numberofarchives,
  sizeinbytes,
  policy,
  tags,
  _tags,
  _policy,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  vaultarn.attr_value #>> '{}' AS vaultarn,
  vaultname.attr_value #>> '{}' AS vaultname,
  creationdate.attr_value #>> '{}' AS creationdate,
  lastinventorydate.attr_value #>> '{}' AS lastinventorydate,
  (numberofarchives.attr_value #>> '{}')::bigint AS numberofarchives,
  (sizeinbytes.attr_value #>> '{}')::bigint AS sizeinbytes,
  policy.attr_value::jsonb AS policy,
  tags.attr_value::jsonb AS tags,
  _tags.attr_value::jsonb AS _tags,
  _policy.attr_value::jsonb AS _policy,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS vaultarn
    ON vaultarn.resource_id = R.id
    AND vaultarn.type = 'provider'
    AND lower(vaultarn.attr_name) = 'vaultarn'
  LEFT JOIN resource_attribute AS vaultname
    ON vaultname.resource_id = R.id
    AND vaultname.type = 'provider'
    AND lower(vaultname.attr_name) = 'vaultname'
  LEFT JOIN resource_attribute AS creationdate
    ON creationdate.resource_id = R.id
    AND creationdate.type = 'provider'
    AND lower(creationdate.attr_name) = 'creationdate'
  LEFT JOIN resource_attribute AS lastinventorydate
    ON lastinventorydate.resource_id = R.id
    AND lastinventorydate.type = 'provider'
    AND lower(lastinventorydate.attr_name) = 'lastinventorydate'
  LEFT JOIN resource_attribute AS numberofarchives
    ON numberofarchives.resource_id = R.id
    AND numberofarchives.type = 'provider'
    AND lower(numberofarchives.attr_name) = 'numberofarchives'
  LEFT JOIN resource_attribute AS sizeinbytes
    ON sizeinbytes.resource_id = R.id
    AND sizeinbytes.type = 'provider'
    AND lower(sizeinbytes.attr_name) = 'sizeinbytes'
  LEFT JOIN resource_attribute AS policy
    ON policy.resource_id = R.id
    AND policy.type = 'provider'
    AND lower(policy.attr_name) = 'policy'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS _policy
    ON _policy.resource_id = R.id
    AND _policy.type = 'Metadata'
    AND lower(_policy.attr_name) = 'policy'
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
  AND R.provider_type = 'Vault'
  AND R.service = 'glacier'
ON CONFLICT (_id) DO UPDATE
SET
    vaultarn = EXCLUDED.vaultarn,
    vaultname = EXCLUDED.vaultname,
    creationdate = EXCLUDED.creationdate,
    lastinventorydate = EXCLUDED.lastinventorydate,
    numberofarchives = EXCLUDED.numberofarchives,
    sizeinbytes = EXCLUDED.sizeinbytes,
    policy = EXCLUDED.policy,
    tags = EXCLUDED.tags,
    _tags = EXCLUDED._tags,
    _policy = EXCLUDED._policy,
    _account_id = EXCLUDED._account_id
  ;

