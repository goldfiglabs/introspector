INSERT INTO aws_ec2_vpc (
  _id,
  uri,
  provider_account_id,
  cidrblock,
  dhcpoptionsid,
  state,
  vpcid,
  ownerid,
  instancetenancy,
  ipv6cidrblockassociationset,
  cidrblockassociationset,
  isdefault,
  tags,
  _tags,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  cidrblock.attr_value #>> '{}' AS cidrblock,
  dhcpoptionsid.attr_value #>> '{}' AS dhcpoptionsid,
  state.attr_value #>> '{}' AS state,
  vpcid.attr_value #>> '{}' AS vpcid,
  ownerid.attr_value #>> '{}' AS ownerid,
  instancetenancy.attr_value #>> '{}' AS instancetenancy,
  ipv6cidrblockassociationset.attr_value::jsonb AS ipv6cidrblockassociationset,
  cidrblockassociationset.attr_value::jsonb AS cidrblockassociationset,
  (isdefault.attr_value #>> '{}')::boolean AS isdefault,
  tags.attr_value::jsonb AS tags,
  _tags.attr_value::jsonb AS _tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS cidrblock
    ON cidrblock.resource_id = R.id
    AND cidrblock.type = 'provider'
    AND lower(cidrblock.attr_name) = 'cidrblock'
    AND cidrblock.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS dhcpoptionsid
    ON dhcpoptionsid.resource_id = R.id
    AND dhcpoptionsid.type = 'provider'
    AND lower(dhcpoptionsid.attr_name) = 'dhcpoptionsid'
    AND dhcpoptionsid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS state
    ON state.resource_id = R.id
    AND state.type = 'provider'
    AND lower(state.attr_name) = 'state'
    AND state.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS vpcid
    ON vpcid.resource_id = R.id
    AND vpcid.type = 'provider'
    AND lower(vpcid.attr_name) = 'vpcid'
    AND vpcid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS ownerid
    ON ownerid.resource_id = R.id
    AND ownerid.type = 'provider'
    AND lower(ownerid.attr_name) = 'ownerid'
    AND ownerid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS instancetenancy
    ON instancetenancy.resource_id = R.id
    AND instancetenancy.type = 'provider'
    AND lower(instancetenancy.attr_name) = 'instancetenancy'
    AND instancetenancy.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS ipv6cidrblockassociationset
    ON ipv6cidrblockassociationset.resource_id = R.id
    AND ipv6cidrblockassociationset.type = 'provider'
    AND lower(ipv6cidrblockassociationset.attr_name) = 'ipv6cidrblockassociationset'
    AND ipv6cidrblockassociationset.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS cidrblockassociationset
    ON cidrblockassociationset.resource_id = R.id
    AND cidrblockassociationset.type = 'provider'
    AND lower(cidrblockassociationset.attr_name) = 'cidrblockassociationset'
    AND cidrblockassociationset.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS isdefault
    ON isdefault.resource_id = R.id
    AND isdefault.type = 'provider'
    AND lower(isdefault.attr_name) = 'isdefault'
    AND isdefault.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
    AND tags.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
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
  AND R.provider_type = 'Vpc'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    cidrblock = EXCLUDED.cidrblock,
    dhcpoptionsid = EXCLUDED.dhcpoptionsid,
    state = EXCLUDED.state,
    vpcid = EXCLUDED.vpcid,
    ownerid = EXCLUDED.ownerid,
    instancetenancy = EXCLUDED.instancetenancy,
    ipv6cidrblockassociationset = EXCLUDED.ipv6cidrblockassociationset,
    cidrblockassociationset = EXCLUDED.cidrblockassociationset,
    isdefault = EXCLUDED.isdefault,
    tags = EXCLUDED.tags,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;

