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
  association.attr_value::jsonb AS association,
  attachment.attr_value::jsonb AS attachment,
  availabilityzone.attr_value #>> '{}' AS availabilityzone,
  description.attr_value #>> '{}' AS description,
  groups.attr_value::jsonb AS groups,
  interfacetype.attr_value #>> '{}' AS interfacetype,
  ipv6addresses.attr_value::jsonb AS ipv6addresses,
  macaddress.attr_value #>> '{}' AS macaddress,
  networkinterfaceid.attr_value #>> '{}' AS networkinterfaceid,
  outpostarn.attr_value #>> '{}' AS outpostarn,
  ownerid.attr_value #>> '{}' AS ownerid,
  privatednsname.attr_value #>> '{}' AS privatednsname,
  privateipaddress.attr_value #>> '{}' AS privateipaddress,
  privateipaddresses.attr_value::jsonb AS privateipaddresses,
  requesterid.attr_value #>> '{}' AS requesterid,
  (requestermanaged.attr_value #>> '{}')::boolean AS requestermanaged,
  (sourcedestcheck.attr_value #>> '{}')::boolean AS sourcedestcheck,
  status.attr_value #>> '{}' AS status,
  subnetid.attr_value #>> '{}' AS subnetid,
  tagset.attr_value::jsonb AS tagset,
  vpcid.attr_value #>> '{}' AS vpcid,
  _tags.attr_value::jsonb AS _tags,
  
    _instance_id.target_id AS _instance_id,
    _vpc_id.target_id AS _vpc_id,
    _subnet_id.target_id AS _subnet_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS association
    ON association.resource_id = R.id
    AND association.type = 'provider'
    AND lower(association.attr_name) = 'association'
  LEFT JOIN resource_attribute AS attachment
    ON attachment.resource_id = R.id
    AND attachment.type = 'provider'
    AND lower(attachment.attr_name) = 'attachment'
  LEFT JOIN resource_attribute AS availabilityzone
    ON availabilityzone.resource_id = R.id
    AND availabilityzone.type = 'provider'
    AND lower(availabilityzone.attr_name) = 'availabilityzone'
  LEFT JOIN resource_attribute AS description
    ON description.resource_id = R.id
    AND description.type = 'provider'
    AND lower(description.attr_name) = 'description'
  LEFT JOIN resource_attribute AS groups
    ON groups.resource_id = R.id
    AND groups.type = 'provider'
    AND lower(groups.attr_name) = 'groups'
  LEFT JOIN resource_attribute AS interfacetype
    ON interfacetype.resource_id = R.id
    AND interfacetype.type = 'provider'
    AND lower(interfacetype.attr_name) = 'interfacetype'
  LEFT JOIN resource_attribute AS ipv6addresses
    ON ipv6addresses.resource_id = R.id
    AND ipv6addresses.type = 'provider'
    AND lower(ipv6addresses.attr_name) = 'ipv6addresses'
  LEFT JOIN resource_attribute AS macaddress
    ON macaddress.resource_id = R.id
    AND macaddress.type = 'provider'
    AND lower(macaddress.attr_name) = 'macaddress'
  LEFT JOIN resource_attribute AS networkinterfaceid
    ON networkinterfaceid.resource_id = R.id
    AND networkinterfaceid.type = 'provider'
    AND lower(networkinterfaceid.attr_name) = 'networkinterfaceid'
  LEFT JOIN resource_attribute AS outpostarn
    ON outpostarn.resource_id = R.id
    AND outpostarn.type = 'provider'
    AND lower(outpostarn.attr_name) = 'outpostarn'
  LEFT JOIN resource_attribute AS ownerid
    ON ownerid.resource_id = R.id
    AND ownerid.type = 'provider'
    AND lower(ownerid.attr_name) = 'ownerid'
  LEFT JOIN resource_attribute AS privatednsname
    ON privatednsname.resource_id = R.id
    AND privatednsname.type = 'provider'
    AND lower(privatednsname.attr_name) = 'privatednsname'
  LEFT JOIN resource_attribute AS privateipaddress
    ON privateipaddress.resource_id = R.id
    AND privateipaddress.type = 'provider'
    AND lower(privateipaddress.attr_name) = 'privateipaddress'
  LEFT JOIN resource_attribute AS privateipaddresses
    ON privateipaddresses.resource_id = R.id
    AND privateipaddresses.type = 'provider'
    AND lower(privateipaddresses.attr_name) = 'privateipaddresses'
  LEFT JOIN resource_attribute AS requesterid
    ON requesterid.resource_id = R.id
    AND requesterid.type = 'provider'
    AND lower(requesterid.attr_name) = 'requesterid'
  LEFT JOIN resource_attribute AS requestermanaged
    ON requestermanaged.resource_id = R.id
    AND requestermanaged.type = 'provider'
    AND lower(requestermanaged.attr_name) = 'requestermanaged'
  LEFT JOIN resource_attribute AS sourcedestcheck
    ON sourcedestcheck.resource_id = R.id
    AND sourcedestcheck.type = 'provider'
    AND lower(sourcedestcheck.attr_name) = 'sourcedestcheck'
  LEFT JOIN resource_attribute AS status
    ON status.resource_id = R.id
    AND status.type = 'provider'
    AND lower(status.attr_name) = 'status'
  LEFT JOIN resource_attribute AS subnetid
    ON subnetid.resource_id = R.id
    AND subnetid.type = 'provider'
    AND lower(subnetid.attr_name) = 'subnetid'
  LEFT JOIN resource_attribute AS tagset
    ON tagset.resource_id = R.id
    AND tagset.type = 'provider'
    AND lower(tagset.attr_name) = 'tagset'
  LEFT JOIN resource_attribute AS vpcid
    ON vpcid.resource_id = R.id
    AND vpcid.type = 'provider'
    AND lower(vpcid.attr_name) = 'vpcid'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
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
    WHERE
      _aws_ec2_instance_relation.relation = 'attached-to'
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
    WHERE
      _aws_ec2_vpc_relation.relation = 'in'
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
    WHERE
      _aws_ec2_subnet_relation.relation = 'in'
  ) AS _subnet_id ON _subnet_id.resource_id = R.id
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
      GROUP BY _aws_organizations_account_relation.resource_id
      HAVING COUNT(*) = 1
    ) AS unique_account_mapping
    INNER JOIN resource_relation AS _aws_organizations_account_relation
      ON _aws_organizations_account_relation.resource_id = unique_account_mapping.resource_id
    INNER JOIN resource AS _aws_organizations_account
      ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
      AND _aws_organizations_account.provider_type = 'Account'
      AND _aws_organizations_account.service = 'organizations'
    WHERE
        _aws_organizations_account_relation.relation = 'in'
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  PA.provider = 'aws'
  AND R.provider_type = 'NetworkInterface'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    association = EXCLUDED.association,
    attachment = EXCLUDED.attachment,
    availabilityzone = EXCLUDED.availabilityzone,
    description = EXCLUDED.description,
    groups = EXCLUDED.groups,
    interfacetype = EXCLUDED.interfacetype,
    ipv6addresses = EXCLUDED.ipv6addresses,
    macaddress = EXCLUDED.macaddress,
    networkinterfaceid = EXCLUDED.networkinterfaceid,
    outpostarn = EXCLUDED.outpostarn,
    ownerid = EXCLUDED.ownerid,
    privatednsname = EXCLUDED.privatednsname,
    privateipaddress = EXCLUDED.privateipaddress,
    privateipaddresses = EXCLUDED.privateipaddresses,
    requesterid = EXCLUDED.requesterid,
    requestermanaged = EXCLUDED.requestermanaged,
    sourcedestcheck = EXCLUDED.sourcedestcheck,
    status = EXCLUDED.status,
    subnetid = EXCLUDED.subnetid,
    tagset = EXCLUDED.tagset,
    vpcid = EXCLUDED.vpcid,
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
  WHERE
    aws_ec2_networkinterface.provider_type = 'NetworkInterface'
    AND aws_ec2_networkinterface.service = 'ec2'
ON CONFLICT (networkinterface_id, securitygroup_id)
DO NOTHING
;
