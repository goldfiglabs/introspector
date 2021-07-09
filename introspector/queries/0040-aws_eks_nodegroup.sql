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
INSERT INTO aws_eks_nodegroup (
  _id,
  uri,
  provider_account_id,
  nodegroupname,
  nodegrouparn,
  clustername,
  version,
  releaseversion,
  createdat,
  modifiedat,
  status,
  capacitytype,
  scalingconfig,
  instancetypes,
  subnets,
  remoteaccess,
  amitype,
  noderole,
  labels,
  resources,
  disksize,
  health,
  launchtemplate,
  tags,
  _tags,
  _cluster_id,_iam_role_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'nodegroupName' AS nodegroupname,
  attrs.provider ->> 'nodegroupArn' AS nodegrouparn,
  attrs.provider ->> 'clusterName' AS clustername,
  attrs.provider ->> 'version' AS version,
  attrs.provider ->> 'releaseVersion' AS releaseversion,
  (TO_TIMESTAMP(attrs.provider ->> 'createdAt', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdat,
  (TO_TIMESTAMP(attrs.provider ->> 'modifiedAt', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS modifiedat,
  attrs.provider ->> 'status' AS status,
  attrs.provider ->> 'capacityType' AS capacitytype,
  attrs.provider -> 'scalingConfig' AS scalingconfig,
  attrs.provider -> 'instanceTypes' AS instancetypes,
  attrs.provider -> 'subnets' AS subnets,
  attrs.provider -> 'remoteAccess' AS remoteaccess,
  attrs.provider ->> 'amiType' AS amitype,
  attrs.provider ->> 'nodeRole' AS noderole,
  attrs.provider -> 'labels' AS labels,
  attrs.provider -> 'resources' AS resources,
  (attrs.provider ->> 'diskSize')::integer AS disksize,
  attrs.provider -> 'health' AS health,
  attrs.provider -> 'launchTemplate' AS launchtemplate,
  attrs.provider -> 'tags' AS tags,
  attrs.metadata -> 'Tags' AS tags,
  
    _cluster_id.target_id AS _cluster_id,
    _iam_role_id.target_id AS _iam_role_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_eks_cluster_relation.resource_id AS resource_id,
      _aws_eks_cluster.id AS target_id
    FROM
      resource_relation AS _aws_eks_cluster_relation
      INNER JOIN resource AS _aws_eks_cluster
        ON _aws_eks_cluster_relation.target_id = _aws_eks_cluster.id
        AND _aws_eks_cluster.provider_type = 'Cluster'
        AND _aws_eks_cluster.service = 'eks'
        AND _aws_eks_cluster.provider_account_id = :provider_account_id
    WHERE
      _aws_eks_cluster_relation.relation = 'in'
      AND _aws_eks_cluster_relation.provider_account_id = :provider_account_id
  ) AS _cluster_id ON _cluster_id.resource_id = R.id
  LEFT JOIN (
    SELECT
      _aws_iam_role_relation.resource_id AS resource_id,
      _aws_iam_role.id AS target_id
    FROM
      resource_relation AS _aws_iam_role_relation
      INNER JOIN resource AS _aws_iam_role
        ON _aws_iam_role_relation.target_id = _aws_iam_role.id
        AND _aws_iam_role.provider_type = 'Role'
        AND _aws_iam_role.service = 'iam'
        AND _aws_iam_role.provider_account_id = :provider_account_id
    WHERE
      _aws_iam_role_relation.relation = 'acts-as'
      AND _aws_iam_role_relation.provider_account_id = :provider_account_id
  ) AS _iam_role_id ON _iam_role_id.resource_id = R.id
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
  AND R.provider_type = 'Nodegroup'
  AND R.service = 'eks'
ON CONFLICT (_id) DO UPDATE
SET
    nodegroupName = EXCLUDED.nodegroupName,
    nodegroupArn = EXCLUDED.nodegroupArn,
    clusterName = EXCLUDED.clusterName,
    version = EXCLUDED.version,
    releaseVersion = EXCLUDED.releaseVersion,
    createdAt = EXCLUDED.createdAt,
    modifiedAt = EXCLUDED.modifiedAt,
    status = EXCLUDED.status,
    capacityType = EXCLUDED.capacityType,
    scalingConfig = EXCLUDED.scalingConfig,
    instanceTypes = EXCLUDED.instanceTypes,
    subnets = EXCLUDED.subnets,
    remoteAccess = EXCLUDED.remoteAccess,
    amiType = EXCLUDED.amiType,
    nodeRole = EXCLUDED.nodeRole,
    labels = EXCLUDED.labels,
    resources = EXCLUDED.resources,
    diskSize = EXCLUDED.diskSize,
    health = EXCLUDED.health,
    launchTemplate = EXCLUDED.launchTemplate,
    tags = EXCLUDED.tags,
    _tags = EXCLUDED._tags,
    _cluster_id = EXCLUDED._cluster_id,
    _iam_role_id = EXCLUDED._iam_role_id,
    _account_id = EXCLUDED._account_id
  ;



INSERT INTO aws_eks_nodegroup_ec2_subnet
SELECT
  aws_eks_nodegroup.id AS nodegroup_id,
  aws_ec2_subnet.id AS subnet_id,
  aws_eks_nodegroup.provider_account_id AS provider_account_id
FROM
  resource AS aws_eks_nodegroup
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_eks_nodegroup.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_subnet
    ON aws_ec2_subnet.id = RR.target_id
    AND aws_ec2_subnet.provider_type = 'Subnet'
    AND aws_ec2_subnet.service = 'ec2'
    AND aws_ec2_subnet.provider_account_id = :provider_account_id
  WHERE
    aws_eks_nodegroup.provider_account_id = :provider_account_id
    AND aws_eks_nodegroup.provider_type = 'Nodegroup'
    AND aws_eks_nodegroup.service = 'eks'
ON CONFLICT (nodegroup_id, subnet_id)
DO NOTHING
;
