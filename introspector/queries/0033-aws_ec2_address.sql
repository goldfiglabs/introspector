INSERT INTO aws_ec2_address
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  instanceid.attr_value #>> '{}' AS instanceid,
  publicip.attr_value #>> '{}' AS publicip,
  allocationid.attr_value #>> '{}' AS allocationid,
  associationid.attr_value #>> '{}' AS associationid,
  domain.attr_value #>> '{}' AS domain,
  networkinterfaceid.attr_value #>> '{}' AS networkinterfaceid,
  networkinterfaceownerid.attr_value #>> '{}' AS networkinterfaceownerid,
  privateipaddress.attr_value #>> '{}' AS privateipaddress,
  tags.attr_value::jsonb AS tags,
  publicipv4pool.attr_value #>> '{}' AS publicipv4pool,
  networkbordergroup.attr_value #>> '{}' AS networkbordergroup,
  customerownedip.attr_value #>> '{}' AS customerownedip,
  customerownedipv4pool.attr_value #>> '{}' AS customerownedipv4pool,
  carrierip.attr_value #>> '{}' AS carrierip,
  
    _networkinterface_id.target_id AS _networkinterface_id,
    _instance_id.target_id AS _instance_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS instanceid
    ON instanceid.resource_id = R.id
    AND instanceid.type = 'provider'
    AND lower(instanceid.attr_name) = 'instanceid'
  LEFT JOIN resource_attribute AS publicip
    ON publicip.resource_id = R.id
    AND publicip.type = 'provider'
    AND lower(publicip.attr_name) = 'publicip'
  LEFT JOIN resource_attribute AS allocationid
    ON allocationid.resource_id = R.id
    AND allocationid.type = 'provider'
    AND lower(allocationid.attr_name) = 'allocationid'
  LEFT JOIN resource_attribute AS associationid
    ON associationid.resource_id = R.id
    AND associationid.type = 'provider'
    AND lower(associationid.attr_name) = 'associationid'
  LEFT JOIN resource_attribute AS domain
    ON domain.resource_id = R.id
    AND domain.type = 'provider'
    AND lower(domain.attr_name) = 'domain'
  LEFT JOIN resource_attribute AS networkinterfaceid
    ON networkinterfaceid.resource_id = R.id
    AND networkinterfaceid.type = 'provider'
    AND lower(networkinterfaceid.attr_name) = 'networkinterfaceid'
  LEFT JOIN resource_attribute AS networkinterfaceownerid
    ON networkinterfaceownerid.resource_id = R.id
    AND networkinterfaceownerid.type = 'provider'
    AND lower(networkinterfaceownerid.attr_name) = 'networkinterfaceownerid'
  LEFT JOIN resource_attribute AS privateipaddress
    ON privateipaddress.resource_id = R.id
    AND privateipaddress.type = 'provider'
    AND lower(privateipaddress.attr_name) = 'privateipaddress'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS publicipv4pool
    ON publicipv4pool.resource_id = R.id
    AND publicipv4pool.type = 'provider'
    AND lower(publicipv4pool.attr_name) = 'publicipv4pool'
  LEFT JOIN resource_attribute AS networkbordergroup
    ON networkbordergroup.resource_id = R.id
    AND networkbordergroup.type = 'provider'
    AND lower(networkbordergroup.attr_name) = 'networkbordergroup'
  LEFT JOIN resource_attribute AS customerownedip
    ON customerownedip.resource_id = R.id
    AND customerownedip.type = 'provider'
    AND lower(customerownedip.attr_name) = 'customerownedip'
  LEFT JOIN resource_attribute AS customerownedipv4pool
    ON customerownedipv4pool.resource_id = R.id
    AND customerownedipv4pool.type = 'provider'
    AND lower(customerownedipv4pool.attr_name) = 'customerownedipv4pool'
  LEFT JOIN resource_attribute AS carrierip
    ON carrierip.resource_id = R.id
    AND carrierip.type = 'provider'
    AND lower(carrierip.attr_name) = 'carrierip'
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
    WHERE
      _aws_ec2_networkinterface_relation.relation = 'assigned-to'
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
    WHERE
      _aws_ec2_instance_relation.relation = 'assigned-to'
  ) AS _instance_id ON _instance_id.resource_id = R.id
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
  AND R.provider_type = 'Address'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    instanceid = EXCLUDED.instanceid,
    publicip = EXCLUDED.publicip,
    allocationid = EXCLUDED.allocationid,
    associationid = EXCLUDED.associationid,
    domain = EXCLUDED.domain,
    networkinterfaceid = EXCLUDED.networkinterfaceid,
    networkinterfaceownerid = EXCLUDED.networkinterfaceownerid,
    privateipaddress = EXCLUDED.privateipaddress,
    tags = EXCLUDED.tags,
    publicipv4pool = EXCLUDED.publicipv4pool,
    networkbordergroup = EXCLUDED.networkbordergroup,
    customerownedip = EXCLUDED.customerownedip,
    customerownedipv4pool = EXCLUDED.customerownedipv4pool,
    carrierip = EXCLUDED.carrierip,
    _networkinterface_id = EXCLUDED._networkinterface_id,
    _instance_id = EXCLUDED._instance_id,
    _account_id = EXCLUDED._account_id
  ;

