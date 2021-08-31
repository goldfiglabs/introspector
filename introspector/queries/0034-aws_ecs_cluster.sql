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
INSERT INTO aws_ecs_cluster (
  _id,
  uri,
  provider_account_id,
  clusterarn,
  clustername,
  status,
  registeredcontainerinstancescount,
  runningtaskscount,
  pendingtaskscount,
  activeservicescount,
  statistics,
  tags,
  settings,
  capacityproviders,
  defaultcapacityproviderstrategy,
  attachments,
  attachmentsstatus,
  _tags,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attrs.provider ->> 'clusterArn' AS clusterarn,
  attrs.provider ->> 'clusterName' AS clustername,
  attrs.provider ->> 'status' AS status,
  (attrs.provider ->> 'registeredContainerInstancesCount')::integer AS registeredcontainerinstancescount,
  (attrs.provider ->> 'runningTasksCount')::integer AS runningtaskscount,
  (attrs.provider ->> 'pendingTasksCount')::integer AS pendingtaskscount,
  (attrs.provider ->> 'activeServicesCount')::integer AS activeservicescount,
  attrs.provider -> 'statistics' AS statistics,
  attrs.provider -> 'tags' AS tags,
  attrs.provider -> 'settings' AS settings,
  attrs.provider -> 'capacityProviders' AS capacityproviders,
  attrs.provider -> 'defaultCapacityProviderStrategy' AS defaultcapacityproviderstrategy,
  attrs.provider -> 'attachments' AS attachments,
  attrs.provider ->> 'attachmentsStatus' AS attachmentsstatus,
  attrs.metadata -> 'Tags' AS tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
  AND R.provider_type = 'Cluster'
  AND R.service = 'ecs'
ON CONFLICT (_id) DO UPDATE
SET
    clusterArn = EXCLUDED.clusterArn,
    clusterName = EXCLUDED.clusterName,
    status = EXCLUDED.status,
    registeredContainerInstancesCount = EXCLUDED.registeredContainerInstancesCount,
    runningTasksCount = EXCLUDED.runningTasksCount,
    pendingTasksCount = EXCLUDED.pendingTasksCount,
    activeServicesCount = EXCLUDED.activeServicesCount,
    statistics = EXCLUDED.statistics,
    tags = EXCLUDED.tags,
    settings = EXCLUDED.settings,
    capacityProviders = EXCLUDED.capacityProviders,
    defaultCapacityProviderStrategy = EXCLUDED.defaultCapacityProviderStrategy,
    attachments = EXCLUDED.attachments,
    attachmentsStatus = EXCLUDED.attachmentsStatus,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;

