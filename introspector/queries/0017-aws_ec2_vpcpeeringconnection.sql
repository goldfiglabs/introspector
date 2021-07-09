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
  attrs.provider -> 'AccepterVpcInfo' AS acceptervpcinfo,
  (TO_TIMESTAMP(attrs.provider ->> 'ExpirationTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS expirationtime,
  attrs.provider -> 'RequesterVpcInfo' AS requestervpcinfo,
  attrs.provider -> 'Status' AS status,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider ->> 'VpcPeeringConnectionId' AS vpcpeeringconnectionid,
  attrs.metadata -> 'Tags' AS tags,
  
    _acceptervpc_id.target_id AS _acceptervpc_id,
    _requestervpc_id.target_id AS _requestervpc_id,
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
      _aws_ec2_vpc_relation.relation = 'peers-to'
      AND _aws_ec2_vpc_relation.provider_account_id = :provider_account_id
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
        AND _aws_ec2_vpc.provider_account_id = :provider_account_id
    WHERE
      _aws_ec2_vpc_relation.relation = 'peers-from'
      AND _aws_ec2_vpc_relation.provider_account_id = :provider_account_id
  ) AS _requestervpc_id ON _requestervpc_id.resource_id = R.id
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
  AND R.provider_type = 'VpcPeeringConnection'
  AND R.service = 'ec2'
ON CONFLICT (_id) DO UPDATE
SET
    AccepterVpcInfo = EXCLUDED.AccepterVpcInfo,
    ExpirationTime = EXCLUDED.ExpirationTime,
    RequesterVpcInfo = EXCLUDED.RequesterVpcInfo,
    Status = EXCLUDED.Status,
    Tags = EXCLUDED.Tags,
    VpcPeeringConnectionId = EXCLUDED.VpcPeeringConnectionId,
    _tags = EXCLUDED._tags,
    _acceptervpc_id = EXCLUDED._acceptervpc_id,
    _requestervpc_id = EXCLUDED._requestervpc_id,
    _account_id = EXCLUDED._account_id
  ;

