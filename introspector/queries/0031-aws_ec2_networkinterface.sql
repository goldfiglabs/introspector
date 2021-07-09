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
INSERT INTO aws_ec2_networkinterface (
  _id,
  uri,
  provider_account_id,
  association,
  attachment,
  availabilityzone,
  description,
  groups,
  interfacetype,
  ipv6addresses,
  macaddress,
  networkinterfaceid,
  outpostarn,
  ownerid,
  privatednsname,
  privateipaddress,
  privateipaddresses,
  requesterid,
  requestermanaged,
  sourcedestcheck,
  status,
  subnetid,
  tagset,
  vpcid,
  _tags,
  _instance_id,_vpc_id,_subnet_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider -> 'Association' AS association,
  attrs.provider -> 'Attachment' AS attachment,
  attrs.provider ->> 'AvailabilityZone' AS availabilityzone,
  attrs.provider ->> 'Description' AS description,
  attrs.provider -> 'Groups' AS groups,
  attrs.provider ->> 'InterfaceType' AS interfacetype,
  attrs.provider -> 'Ipv6Addresses' AS ipv6addresses,
  attrs.provider ->> 'MacAddress' AS macaddress,
  attrs.provider ->> 'NetworkInterfaceId' AS networkinterfaceid,
  attrs.provider ->> 'OutpostArn' AS outpostarn,
  attrs.provider ->> 'OwnerId' AS ownerid,
  attrs.provider ->> 'PrivateDnsName' AS privatednsname,
  attrs.provider ->> 'PrivateIpAddress' AS privateipaddress,
  attrs.provider -> 'PrivateIpAddresses' AS privateipaddresses,
  attrs.provider ->> 'RequesterId' AS requesterid,
  (attrs.provider ->> 'RequesterManaged')::boolean AS requestermanaged,
  (attrs.provider ->> 'SourceDestCheck')::boolean AS sourcedestcheck,
  attrs.provider ->> 'Status' AS status,
  attrs.provider ->> 'SubnetId' AS subnetid,
  attrs.provider -> 'TagSet' AS tagset,
  attrs.provider ->> 'VpcId' AS vpcid,
  attrs.metadata -> 'Tags' AS tags,
  
    _instance_id.target_id AS _instance_id,
    _vpc_id.target_id AS _vpc_id,
    _subnet_id.target_id AS _subnet_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_ec2_instance_relation.resource_id AS resource_id,
      _aws_ec2_instance.id AS target_id
    FROM
      resource_relation AS _aws_ec2_instance_relation
      INNER JOIN resource AS _aws_ec2_instance
        ON _aws_ec2_instance_relation.target_id = _aws_ec2_instance.id
        AND _aws_ec2_instance.provider_type = 'Instance'
        AND _aws_ec2_instance.service = 'ec2'
        AND _aws_ec2_instance.provider_account_id = :provider_account_id
    WHERE
      _aws_ec2_instance_relation.relation = 'attached-to'
      AND _aws_ec2_instance_relation.provider_account_id = :provider_account_id
  ) AS _instance_id ON _instance_id.resource_id = R.id
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
      _aws_ec2_subnet_relation.resource_id AS resource_id,
      _aws_ec2_subnet.id AS target_id
    FROM
      resource_relation AS _aws_ec2_subnet_relation
      INNER JOIN resource AS _aws_ec2_subnet
        ON _aws_ec2_subnet_relation.target_id = _aws_ec2_subnet.id
        AND _aws_ec2_subnet.provider_type = 'Subnet'
        AND _aws_ec2_subnet.service = 'ec2'
        AND _aws_ec2_subnet.provider_account_id = :provider_account_id
    WHERE
      _aws_ec2_subnet_relation.relation = 'in'
      AND _aws_ec2_subnet_relation.provider_account_id = :provider_account_id
  ) AS _subnet_id ON _subnet_id.resource_id = R.id
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
  AND R.provider_type = 'NetworkInterface'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    Association = EXCLUDED.Association,
    Attachment = EXCLUDED.Attachment,
    AvailabilityZone = EXCLUDED.AvailabilityZone,
    Description = EXCLUDED.Description,
    Groups = EXCLUDED.Groups,
    InterfaceType = EXCLUDED.InterfaceType,
    Ipv6Addresses = EXCLUDED.Ipv6Addresses,
    MacAddress = EXCLUDED.MacAddress,
    NetworkInterfaceId = EXCLUDED.NetworkInterfaceId,
    OutpostArn = EXCLUDED.OutpostArn,
    OwnerId = EXCLUDED.OwnerId,
    PrivateDnsName = EXCLUDED.PrivateDnsName,
    PrivateIpAddress = EXCLUDED.PrivateIpAddress,
    PrivateIpAddresses = EXCLUDED.PrivateIpAddresses,
    RequesterId = EXCLUDED.RequesterId,
    RequesterManaged = EXCLUDED.RequesterManaged,
    SourceDestCheck = EXCLUDED.SourceDestCheck,
    Status = EXCLUDED.Status,
    SubnetId = EXCLUDED.SubnetId,
    TagSet = EXCLUDED.TagSet,
    VpcId = EXCLUDED.VpcId,
    _tags = EXCLUDED._tags,
    _instance_id = EXCLUDED._instance_id,
    _vpc_id = EXCLUDED._vpc_id,
    _subnet_id = EXCLUDED._subnet_id,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_ec2_networkinterface_securitygroup
SELECT
  aws_ec2_networkinterface.id AS networkinterface_id,
  aws_ec2_securitygroup.id AS securitygroup_id,
  aws_ec2_networkinterface.provider_account_id AS provider_account_id
FROM
  resource AS aws_ec2_networkinterface
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_ec2_networkinterface.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_securitygroup
    ON aws_ec2_securitygroup.id = RR.target_id
    AND aws_ec2_securitygroup.provider_type = 'SecurityGroup'
    AND aws_ec2_securitygroup.service = 'ec2'
    AND aws_ec2_securitygroup.provider_account_id = :provider_account_id
  WHERE
    aws_ec2_networkinterface.provider_account_id = :provider_account_id
    AND aws_ec2_networkinterface.provider_type = 'NetworkInterface'
    AND aws_ec2_networkinterface.service = 'ec2'
ON CONFLICT (networkinterface_id, securitygroup_id)
DO NOTHING
;
