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
INSERT INTO aws_ec2_vpcendpoint (
  _id,
  uri,
  provider_account_id,
  vpcendpointid,
  vpcendpointtype,
  vpcid,
  servicename,
  state,
  policydocument,
  routetableids,
  subnetids,
  groups,
  privatednsenabled,
  requestermanaged,
  networkinterfaceids,
  dnsentries,
  creationtimestamp,
  tags,
  ownerid,
  lasterror,
  _tags,
  _policy,
  _vpc_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'VpcEndpointId' AS vpcendpointid,
  attrs.provider ->> 'VpcEndpointType' AS vpcendpointtype,
  attrs.provider ->> 'VpcId' AS vpcid,
  attrs.provider ->> 'ServiceName' AS servicename,
  attrs.provider ->> 'State' AS state,
  attrs.provider ->> 'PolicyDocument' AS policydocument,
  attrs.provider -> 'RouteTableIds' AS routetableids,
  attrs.provider -> 'SubnetIds' AS subnetids,
  attrs.provider -> 'Groups' AS groups,
  (attrs.provider ->> 'PrivateDnsEnabled')::boolean AS privatednsenabled,
  (attrs.provider ->> 'RequesterManaged')::boolean AS requestermanaged,
  attrs.provider -> 'NetworkInterfaceIds' AS networkinterfaceids,
  attrs.provider -> 'DnsEntries' AS dnsentries,
  (TO_TIMESTAMP(attrs.provider ->> 'CreationTimestamp', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS creationtimestamp,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider ->> 'OwnerId' AS ownerid,
  attrs.provider -> 'LastError' AS lasterror,
  attrs.metadata -> 'Tags' AS tags,
  attrs.metadata -> 'Policy' AS policy,
  
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
          AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'VpcEndpoint'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    VpcEndpointId = EXCLUDED.VpcEndpointId,
    VpcEndpointType = EXCLUDED.VpcEndpointType,
    VpcId = EXCLUDED.VpcId,
    ServiceName = EXCLUDED.ServiceName,
    State = EXCLUDED.State,
    PolicyDocument = EXCLUDED.PolicyDocument,
    RouteTableIds = EXCLUDED.RouteTableIds,
    SubnetIds = EXCLUDED.SubnetIds,
    Groups = EXCLUDED.Groups,
    PrivateDnsEnabled = EXCLUDED.PrivateDnsEnabled,
    RequesterManaged = EXCLUDED.RequesterManaged,
    NetworkInterfaceIds = EXCLUDED.NetworkInterfaceIds,
    DnsEntries = EXCLUDED.DnsEntries,
    CreationTimestamp = EXCLUDED.CreationTimestamp,
    Tags = EXCLUDED.Tags,
    OwnerId = EXCLUDED.OwnerId,
    LastError = EXCLUDED.LastError,
    _tags = EXCLUDED._tags,
    _policy = EXCLUDED._policy,
    _vpc_id = EXCLUDED._vpc_id,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_ec2_vpcendpoint_subnet
SELECT
  aws_ec2_vpcendpoint.id AS vpcendpoint_id,
  aws_ec2_subnet.id AS subnet_id,
  aws_ec2_vpcendpoint.provider_account_id AS provider_account_id
FROM
  resource AS aws_ec2_vpcendpoint
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_ec2_vpcendpoint.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_subnet
    ON aws_ec2_subnet.id = RR.target_id
    AND aws_ec2_subnet.provider_type = 'Subnet'
    AND aws_ec2_subnet.service = 'ec2'
    AND aws_ec2_subnet.provider_account_id = :provider_account_id
  WHERE
    aws_ec2_vpcendpoint.provider_account_id = :provider_account_id
    AND aws_ec2_vpcendpoint.provider_type = 'VpcEndpoint'
    AND aws_ec2_vpcendpoint.service = 'ec2'
ON CONFLICT (vpcendpoint_id, subnet_id)
DO NOTHING
;


INSERT INTO aws_ec2_vpcendpoint_securitygroup
SELECT
  aws_ec2_vpcendpoint.id AS vpcendpoint_id,
  aws_ec2_securitygroup.id AS securitygroup_id,
  aws_ec2_vpcendpoint.provider_account_id AS provider_account_id
FROM
  resource AS aws_ec2_vpcendpoint
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_ec2_vpcendpoint.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_securitygroup
    ON aws_ec2_securitygroup.id = RR.target_id
    AND aws_ec2_securitygroup.provider_type = 'SecurityGroup'
    AND aws_ec2_securitygroup.service = 'ec2'
    AND aws_ec2_securitygroup.provider_account_id = :provider_account_id
  WHERE
    aws_ec2_vpcendpoint.provider_account_id = :provider_account_id
    AND aws_ec2_vpcendpoint.provider_type = 'VpcEndpoint'
    AND aws_ec2_vpcendpoint.service = 'ec2'
ON CONFLICT (vpcendpoint_id, securitygroup_id)
DO NOTHING
;
