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
INSERT INTO aws_ec2_subnet (
  _id,
  uri,
  provider_account_id,
  availabilityzone,
  availabilityzoneid,
  availableipaddresscount,
  cidrblock,
  defaultforaz,
  mappubliciponlaunch,
  mapcustomerownediponlaunch,
  customerownedipv4pool,
  state,
  subnetid,
  vpcid,
  ownerid,
  assignipv6addressoncreation,
  ipv6cidrblockassociationset,
  tags,
  subnetarn,
  outpostarn,
  _tags,
  _vpc_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'AvailabilityZone' AS availabilityzone,
  attrs.provider ->> 'AvailabilityZoneId' AS availabilityzoneid,
  (attrs.provider ->> 'AvailableIpAddressCount')::integer AS availableipaddresscount,
  attrs.provider ->> 'CidrBlock' AS cidrblock,
  (attrs.provider ->> 'DefaultForAz')::boolean AS defaultforaz,
  (attrs.provider ->> 'MapPublicIpOnLaunch')::boolean AS mappubliciponlaunch,
  (attrs.provider ->> 'MapCustomerOwnedIpOnLaunch')::boolean AS mapcustomerownediponlaunch,
  attrs.provider ->> 'CustomerOwnedIpv4Pool' AS customerownedipv4pool,
  attrs.provider ->> 'State' AS state,
  attrs.provider ->> 'SubnetId' AS subnetid,
  attrs.provider ->> 'VpcId' AS vpcid,
  attrs.provider ->> 'OwnerId' AS ownerid,
  (attrs.provider ->> 'AssignIpv6AddressOnCreation')::boolean AS assignipv6addressoncreation,
  attrs.provider -> 'Ipv6CidrBlockAssociationSet' AS ipv6cidrblockassociationset,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider ->> 'SubnetArn' AS subnetarn,
  attrs.provider ->> 'OutpostArn' AS outpostarn,
  attrs.metadata -> 'Tags' AS tags,
  
    _vpc_id.target_id AS _vpc_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_ec2_vpc_relation.resource_id AS resource_id,
      _aws_ec2_vpc.id AS target_id
    FROM
      resource_relation AS _aws_ec2_vpc_relation
      INNER JOIN resource AS _aws_ec2_vpc
        ON _aws_ec2_vpc_relation.target_id = _aws_ec2_vpc.id
        AND _aws_ec2_vpc.provider_type = 'Vpc'
        AND _aws_ec2_vpc.service = 'ec2'
        AND _aws_ec2_vpc.provider_account_id = :provider_account_id
    WHERE
      _aws_ec2_vpc_relation.relation = 'in'
      AND _aws_ec2_vpc_relation.provider_account_id = :provider_account_id
  ) AS _vpc_id ON _vpc_id.resource_id = R.id
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
          AND _aws_organizations_account_relation.provider_account_id = 8
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'Subnet'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    AvailabilityZone = EXCLUDED.AvailabilityZone,
    AvailabilityZoneId = EXCLUDED.AvailabilityZoneId,
    AvailableIpAddressCount = EXCLUDED.AvailableIpAddressCount,
    CidrBlock = EXCLUDED.CidrBlock,
    DefaultForAz = EXCLUDED.DefaultForAz,
    MapPublicIpOnLaunch = EXCLUDED.MapPublicIpOnLaunch,
    MapCustomerOwnedIpOnLaunch = EXCLUDED.MapCustomerOwnedIpOnLaunch,
    CustomerOwnedIpv4Pool = EXCLUDED.CustomerOwnedIpv4Pool,
    State = EXCLUDED.State,
    SubnetId = EXCLUDED.SubnetId,
    VpcId = EXCLUDED.VpcId,
    OwnerId = EXCLUDED.OwnerId,
    AssignIpv6AddressOnCreation = EXCLUDED.AssignIpv6AddressOnCreation,
    Ipv6CidrBlockAssociationSet = EXCLUDED.Ipv6CidrBlockAssociationSet,
    Tags = EXCLUDED.Tags,
    SubnetArn = EXCLUDED.SubnetArn,
    OutpostArn = EXCLUDED.OutpostArn,
    _tags = EXCLUDED._tags,
    _vpc_id = EXCLUDED._vpc_id,
    _account_id = EXCLUDED._account_id
  ;

