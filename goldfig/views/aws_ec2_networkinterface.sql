DROP MATERIALIZED VIEW IF EXISTS aws_ec2_networkinterface CASCADE;

CREATE MATERIALIZED VIEW aws_ec2_networkinterface AS
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
  
    _instance_id.target_id AS _instance_id,
    _vpc_id.target_id AS _vpc_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS association
    ON association.id = R.id
    AND association.attr_name = 'association'
  LEFT JOIN attrs AS attachment
    ON attachment.id = R.id
    AND attachment.attr_name = 'attachment'
  LEFT JOIN attrs AS availabilityzone
    ON availabilityzone.id = R.id
    AND availabilityzone.attr_name = 'availabilityzone'
  LEFT JOIN attrs AS description
    ON description.id = R.id
    AND description.attr_name = 'description'
  LEFT JOIN attrs AS groups
    ON groups.id = R.id
    AND groups.attr_name = 'groups'
  LEFT JOIN attrs AS interfacetype
    ON interfacetype.id = R.id
    AND interfacetype.attr_name = 'interfacetype'
  LEFT JOIN attrs AS ipv6addresses
    ON ipv6addresses.id = R.id
    AND ipv6addresses.attr_name = 'ipv6addresses'
  LEFT JOIN attrs AS macaddress
    ON macaddress.id = R.id
    AND macaddress.attr_name = 'macaddress'
  LEFT JOIN attrs AS networkinterfaceid
    ON networkinterfaceid.id = R.id
    AND networkinterfaceid.attr_name = 'networkinterfaceid'
  LEFT JOIN attrs AS outpostarn
    ON outpostarn.id = R.id
    AND outpostarn.attr_name = 'outpostarn'
  LEFT JOIN attrs AS ownerid
    ON ownerid.id = R.id
    AND ownerid.attr_name = 'ownerid'
  LEFT JOIN attrs AS privatednsname
    ON privatednsname.id = R.id
    AND privatednsname.attr_name = 'privatednsname'
  LEFT JOIN attrs AS privateipaddress
    ON privateipaddress.id = R.id
    AND privateipaddress.attr_name = 'privateipaddress'
  LEFT JOIN attrs AS privateipaddresses
    ON privateipaddresses.id = R.id
    AND privateipaddresses.attr_name = 'privateipaddresses'
  LEFT JOIN attrs AS requesterid
    ON requesterid.id = R.id
    AND requesterid.attr_name = 'requesterid'
  LEFT JOIN attrs AS requestermanaged
    ON requestermanaged.id = R.id
    AND requestermanaged.attr_name = 'requestermanaged'
  LEFT JOIN attrs AS sourcedestcheck
    ON sourcedestcheck.id = R.id
    AND sourcedestcheck.attr_name = 'sourcedestcheck'
  LEFT JOIN attrs AS status
    ON status.id = R.id
    AND status.attr_name = 'status'
  LEFT JOIN attrs AS subnetid
    ON subnetid.id = R.id
    AND subnetid.attr_name = 'subnetid'
  LEFT JOIN attrs AS tagset
    ON tagset.id = R.id
    AND tagset.attr_name = 'tagset'
  LEFT JOIN attrs AS vpcid
    ON vpcid.id = R.id
    AND vpcid.attr_name = 'vpcid'
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
  AND LOWER(R.provider_type) = 'networkinterface'
  AND R.service = 'ec2'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_ec2_networkinterface;

COMMENT ON MATERIALIZED VIEW aws_ec2_networkinterface IS 'ec2 networkinterface resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_ec2_networkinterface_securitygroup CASCADE;

CREATE MATERIALIZED VIEW aws_ec2_networkinterface_securitygroup AS
SELECT
  aws_ec2_networkinterface.id AS networkinterface_id,
  aws_ec2_securitygroup.id AS securitygroup_id
FROM
  resource AS aws_ec2_networkinterface
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_ec2_networkinterface.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_securitygroup
    ON aws_ec2_securitygroup.id = RR.target_id
    AND aws_ec2_securitygroup.provider_type = 'SecurityGroup'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_ec2_networkinterface_securitygroup;
