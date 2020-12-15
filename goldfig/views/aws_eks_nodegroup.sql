DROP MATERIALIZED VIEW IF EXISTS aws_eks_nodegroup CASCADE;

CREATE MATERIALIZED VIEW aws_eks_nodegroup AS
SELECT
  R.id AS resource_id,
  R.uri,
  R.provider_account_id,
  nodegroupname.attr_value #>> '{}' AS nodegroupname,
  nodegrouparn.attr_value #>> '{}' AS nodegrouparn,
  clustername.attr_value #>> '{}' AS clustername,
  version.attr_value #>> '{}' AS version,
  releaseversion.attr_value #>> '{}' AS releaseversion,
  (TO_TIMESTAMP(createdat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createdat,
  (TO_TIMESTAMP(modifiedat.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS modifiedat,
  status.attr_value #>> '{}' AS status,
  scalingconfig.attr_value::jsonb AS scalingconfig,
  instancetypes.attr_value::jsonb AS instancetypes,
  subnets.attr_value::jsonb AS subnets,
  remoteaccess.attr_value::jsonb AS remoteaccess,
  amitype.attr_value #>> '{}' AS amitype,
  noderole.attr_value #>> '{}' AS noderole,
  labels.attr_value::jsonb AS labels,
  resources.attr_value::jsonb AS resources,
  (disksize.attr_value #>> '{}')::integer AS disksize,
  health.attr_value::jsonb AS health,
  tags.attr_value::jsonb AS tags,
  
    _cluster_id.target_id AS _cluster_id,
    _iam_role_id.target_id AS _iam_role_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS nodegroupname
    ON nodegroupname.resource_id = R.id
    AND nodegroupname.type = 'provider'
    AND lower(nodegroupname.attr_name) = 'nodegroupname'
  LEFT JOIN resource_attribute AS nodegrouparn
    ON nodegrouparn.resource_id = R.id
    AND nodegrouparn.type = 'provider'
    AND lower(nodegrouparn.attr_name) = 'nodegrouparn'
  LEFT JOIN resource_attribute AS clustername
    ON clustername.resource_id = R.id
    AND clustername.type = 'provider'
    AND lower(clustername.attr_name) = 'clustername'
  LEFT JOIN resource_attribute AS version
    ON version.resource_id = R.id
    AND version.type = 'provider'
    AND lower(version.attr_name) = 'version'
  LEFT JOIN resource_attribute AS releaseversion
    ON releaseversion.resource_id = R.id
    AND releaseversion.type = 'provider'
    AND lower(releaseversion.attr_name) = 'releaseversion'
  LEFT JOIN resource_attribute AS createdat
    ON createdat.resource_id = R.id
    AND createdat.type = 'provider'
    AND lower(createdat.attr_name) = 'createdat'
  LEFT JOIN resource_attribute AS modifiedat
    ON modifiedat.resource_id = R.id
    AND modifiedat.type = 'provider'
    AND lower(modifiedat.attr_name) = 'modifiedat'
  LEFT JOIN resource_attribute AS status
    ON status.resource_id = R.id
    AND status.type = 'provider'
    AND lower(status.attr_name) = 'status'
  LEFT JOIN resource_attribute AS scalingconfig
    ON scalingconfig.resource_id = R.id
    AND scalingconfig.type = 'provider'
    AND lower(scalingconfig.attr_name) = 'scalingconfig'
  LEFT JOIN resource_attribute AS instancetypes
    ON instancetypes.resource_id = R.id
    AND instancetypes.type = 'provider'
    AND lower(instancetypes.attr_name) = 'instancetypes'
  LEFT JOIN resource_attribute AS subnets
    ON subnets.resource_id = R.id
    AND subnets.type = 'provider'
    AND lower(subnets.attr_name) = 'subnets'
  LEFT JOIN resource_attribute AS remoteaccess
    ON remoteaccess.resource_id = R.id
    AND remoteaccess.type = 'provider'
    AND lower(remoteaccess.attr_name) = 'remoteaccess'
  LEFT JOIN resource_attribute AS amitype
    ON amitype.resource_id = R.id
    AND amitype.type = 'provider'
    AND lower(amitype.attr_name) = 'amitype'
  LEFT JOIN resource_attribute AS noderole
    ON noderole.resource_id = R.id
    AND noderole.type = 'provider'
    AND lower(noderole.attr_name) = 'noderole'
  LEFT JOIN resource_attribute AS labels
    ON labels.resource_id = R.id
    AND labels.type = 'provider'
    AND lower(labels.attr_name) = 'labels'
  LEFT JOIN resource_attribute AS resources
    ON resources.resource_id = R.id
    AND resources.type = 'provider'
    AND lower(resources.attr_name) = 'resources'
  LEFT JOIN resource_attribute AS disksize
    ON disksize.resource_id = R.id
    AND disksize.type = 'provider'
    AND lower(disksize.attr_name) = 'disksize'
  LEFT JOIN resource_attribute AS health
    ON health.resource_id = R.id
    AND health.type = 'provider'
    AND lower(health.attr_name) = 'health'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
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
    WHERE
      _aws_eks_cluster_relation.relation = 'in'
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
    WHERE
      _aws_iam_role_relation.relation = 'acts-as'
  ) AS _iam_role_id ON _iam_role_id.resource_id = R.id
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
  AND R.provider_type = 'Nodegroup'
  AND R.service = 'eks'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_eks_nodegroup;

COMMENT ON MATERIALIZED VIEW aws_eks_nodegroup IS 'eks Nodegroup resources and their associated attributes.';



DROP MATERIALIZED VIEW IF EXISTS aws_eks_nodegroup_ec2_subnet CASCADE;

CREATE MATERIALIZED VIEW aws_eks_nodegroup_ec2_subnet AS
SELECT
  aws_eks_nodegroup.id AS nodegroup_id,
  aws_ec2_subnet.id AS subnet_id
FROM
  resource AS aws_eks_nodegroup
  INNER JOIN resource_relation AS RR
    ON RR.resource_id = aws_eks_nodegroup.id
    AND RR.relation = 'in'
  INNER JOIN resource AS aws_ec2_subnet
    ON aws_ec2_subnet.id = RR.target_id
    AND aws_ec2_subnet.provider_type = 'Subnet'
    AND aws_ec2_subnet.service = 'ec2'
  WHERE
    aws_eks_nodegroup.provider_type = 'Nodegroup'
    AND aws_eks_nodegroup.service = 'eks'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_eks_nodegroup_ec2_subnet;
