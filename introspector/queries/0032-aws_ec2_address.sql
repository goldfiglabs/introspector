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
INSERT INTO aws_ec2_address (
  _id,
  uri,
  provider_account_id,
  instanceid,
  publicip,
  allocationid,
  associationid,
  domain,
  networkinterfaceid,
  networkinterfaceownerid,
  privateipaddress,
  tags,
  publicipv4pool,
  networkbordergroup,
  customerownedip,
  customerownedipv4pool,
  carrierip,
  _tags,
  _networkinterface_id,_instance_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'InstanceId' AS instanceid,
  attrs.provider ->> 'PublicIp' AS publicip,
  attrs.provider ->> 'AllocationId' AS allocationid,
  attrs.provider ->> 'AssociationId' AS associationid,
  attrs.provider ->> 'Domain' AS domain,
  attrs.provider ->> 'NetworkInterfaceId' AS networkinterfaceid,
  attrs.provider ->> 'NetworkInterfaceOwnerId' AS networkinterfaceownerid,
  attrs.provider ->> 'PrivateIpAddress' AS privateipaddress,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider ->> 'PublicIpv4Pool' AS publicipv4pool,
  attrs.provider ->> 'NetworkBorderGroup' AS networkbordergroup,
  attrs.provider ->> 'CustomerOwnedIp' AS customerownedip,
  attrs.provider ->> 'CustomerOwnedIpv4Pool' AS customerownedipv4pool,
  attrs.provider ->> 'CarrierIp' AS carrierip,
  attrs.metadata -> 'Tags' AS tags,
  
    _networkinterface_id.target_id AS _networkinterface_id,
    _instance_id.target_id AS _instance_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_ec2_networkinterface_relation.resource_id AS resource_id,
      _aws_ec2_networkinterface.id AS target_id
    FROM
      resource_relation AS _aws_ec2_networkinterface_relation
      INNER JOIN resource AS _aws_ec2_networkinterface
        ON _aws_ec2_networkinterface_relation.target_id = _aws_ec2_networkinterface.id
        AND _aws_ec2_networkinterface.provider_type = 'NetworkInterface'
        AND _aws_ec2_networkinterface.service = 'ec2'
        AND _aws_ec2_networkinterface.provider_account_id = :provider_account_id
    WHERE
      _aws_ec2_networkinterface_relation.relation = 'assigned-to'
      AND _aws_ec2_networkinterface_relation.provider_account_id = :provider_account_id
  ) AS _networkinterface_id ON _networkinterface_id.resource_id = R.id
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
      _aws_ec2_instance_relation.relation = 'assigned-to'
      AND _aws_ec2_instance_relation.provider_account_id = :provider_account_id
  ) AS _instance_id ON _instance_id.resource_id = R.id
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
  AND R.provider_type = 'Address'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    InstanceId = EXCLUDED.InstanceId,
    PublicIp = EXCLUDED.PublicIp,
    AllocationId = EXCLUDED.AllocationId,
    AssociationId = EXCLUDED.AssociationId,
    Domain = EXCLUDED.Domain,
    NetworkInterfaceId = EXCLUDED.NetworkInterfaceId,
    NetworkInterfaceOwnerId = EXCLUDED.NetworkInterfaceOwnerId,
    PrivateIpAddress = EXCLUDED.PrivateIpAddress,
    Tags = EXCLUDED.Tags,
    PublicIpv4Pool = EXCLUDED.PublicIpv4Pool,
    NetworkBorderGroup = EXCLUDED.NetworkBorderGroup,
    CustomerOwnedIp = EXCLUDED.CustomerOwnedIp,
    CustomerOwnedIpv4Pool = EXCLUDED.CustomerOwnedIpv4Pool,
    CarrierIp = EXCLUDED.CarrierIp,
    _tags = EXCLUDED._tags,
    _networkinterface_id = EXCLUDED._networkinterface_id,
    _instance_id = EXCLUDED._instance_id,
    _account_id = EXCLUDED._account_id
  ;

