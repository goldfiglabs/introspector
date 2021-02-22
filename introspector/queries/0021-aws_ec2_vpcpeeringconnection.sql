INSERT INTO aws_ec2_vpcpeeringconnection (
  _id,
  uri,
  provider_account_id,
  acceptervpcinfo,
  expirationtime,
  requestervpcinfo,
  status,
  tags,
  vpcpeeringconnectionid,
  _tags,
  _acceptervpc_id,_requestervpc_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  acceptervpcinfo.attr_value::jsonb AS acceptervpcinfo,
  (TO_TIMESTAMP(expirationtime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS expirationtime,
  requestervpcinfo.attr_value::jsonb AS requestervpcinfo,
  status.attr_value::jsonb AS status,
  tags.attr_value::jsonb AS tags,
  vpcpeeringconnectionid.attr_value #>> '{}' AS vpcpeeringconnectionid,
  _tags.attr_value::jsonb AS _tags,
  
    _acceptervpc_id.target_id AS _acceptervpc_id,
    _requestervpc_id.target_id AS _requestervpc_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS acceptervpcinfo
    ON acceptervpcinfo.resource_id = R.id
    AND acceptervpcinfo.type = 'provider'
    AND lower(acceptervpcinfo.attr_name) = 'acceptervpcinfo'
  LEFT JOIN resource_attribute AS expirationtime
    ON expirationtime.resource_id = R.id
    AND expirationtime.type = 'provider'
    AND lower(expirationtime.attr_name) = 'expirationtime'
  LEFT JOIN resource_attribute AS requestervpcinfo
    ON requestervpcinfo.resource_id = R.id
    AND requestervpcinfo.type = 'provider'
    AND lower(requestervpcinfo.attr_name) = 'requestervpcinfo'
  LEFT JOIN resource_attribute AS status
    ON status.resource_id = R.id
    AND status.type = 'provider'
    AND lower(status.attr_name) = 'status'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS vpcpeeringconnectionid
    ON vpcpeeringconnectionid.resource_id = R.id
    AND vpcpeeringconnectionid.type = 'provider'
    AND lower(vpcpeeringconnectionid.attr_name) = 'vpcpeeringconnectionid'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = '_tags'
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
      _aws_ec2_vpc_relation.relation = 'peers-to'
  ) AS _acceptervpc_id ON _acceptervpc_id.resource_id = R.id
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
      _aws_ec2_vpc_relation.relation = 'peers-from'
  ) AS _requestervpc_id ON _requestervpc_id.resource_id = R.id
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
  AND R.provider_type = 'VpcPeeringConnection'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    acceptervpcinfo = EXCLUDED.acceptervpcinfo,
    expirationtime = EXCLUDED.expirationtime,
    requestervpcinfo = EXCLUDED.requestervpcinfo,
    status = EXCLUDED.status,
    tags = EXCLUDED.tags,
    vpcpeeringconnectionid = EXCLUDED.vpcpeeringconnectionid,
    _tags = EXCLUDED._tags,
    _acceptervpc_id = EXCLUDED._acceptervpc_id,
    _requestervpc_id = EXCLUDED._requestervpc_id,
    _account_id = EXCLUDED._account_id
  ;

