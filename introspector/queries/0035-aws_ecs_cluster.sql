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
  clusterarn.attr_value #>> '{}' AS clusterarn,
  clustername.attr_value #>> '{}' AS clustername,
  status.attr_value #>> '{}' AS status,
  (registeredcontainerinstancescount.attr_value #>> '{}')::integer AS registeredcontainerinstancescount,
  (runningtaskscount.attr_value #>> '{}')::integer AS runningtaskscount,
  (pendingtaskscount.attr_value #>> '{}')::integer AS pendingtaskscount,
  (activeservicescount.attr_value #>> '{}')::integer AS activeservicescount,
  statistics.attr_value::jsonb AS statistics,
  tags.attr_value::jsonb AS tags,
  settings.attr_value::jsonb AS settings,
  capacityproviders.attr_value::jsonb AS capacityproviders,
  defaultcapacityproviderstrategy.attr_value::jsonb AS defaultcapacityproviderstrategy,
  attachments.attr_value::jsonb AS attachments,
  attachmentsstatus.attr_value #>> '{}' AS attachmentsstatus,
  _tags.attr_value::jsonb AS _tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS clusterarn
    ON clusterarn.resource_id = R.id
    AND clusterarn.type = 'provider'
    AND lower(clusterarn.attr_name) = 'clusterarn'
    AND clusterarn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS clustername
    ON clustername.resource_id = R.id
    AND clustername.type = 'provider'
    AND lower(clustername.attr_name) = 'clustername'
    AND clustername.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS status
    ON status.resource_id = R.id
    AND status.type = 'provider'
    AND lower(status.attr_name) = 'status'
    AND status.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS registeredcontainerinstancescount
    ON registeredcontainerinstancescount.resource_id = R.id
    AND registeredcontainerinstancescount.type = 'provider'
    AND lower(registeredcontainerinstancescount.attr_name) = 'registeredcontainerinstancescount'
    AND registeredcontainerinstancescount.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS runningtaskscount
    ON runningtaskscount.resource_id = R.id
    AND runningtaskscount.type = 'provider'
    AND lower(runningtaskscount.attr_name) = 'runningtaskscount'
    AND runningtaskscount.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS pendingtaskscount
    ON pendingtaskscount.resource_id = R.id
    AND pendingtaskscount.type = 'provider'
    AND lower(pendingtaskscount.attr_name) = 'pendingtaskscount'
    AND pendingtaskscount.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS activeservicescount
    ON activeservicescount.resource_id = R.id
    AND activeservicescount.type = 'provider'
    AND lower(activeservicescount.attr_name) = 'activeservicescount'
    AND activeservicescount.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS statistics
    ON statistics.resource_id = R.id
    AND statistics.type = 'provider'
    AND lower(statistics.attr_name) = 'statistics'
    AND statistics.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
    AND tags.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS settings
    ON settings.resource_id = R.id
    AND settings.type = 'provider'
    AND lower(settings.attr_name) = 'settings'
    AND settings.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS capacityproviders
    ON capacityproviders.resource_id = R.id
    AND capacityproviders.type = 'provider'
    AND lower(capacityproviders.attr_name) = 'capacityproviders'
    AND capacityproviders.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS defaultcapacityproviderstrategy
    ON defaultcapacityproviderstrategy.resource_id = R.id
    AND defaultcapacityproviderstrategy.type = 'provider'
    AND lower(defaultcapacityproviderstrategy.attr_name) = 'defaultcapacityproviderstrategy'
    AND defaultcapacityproviderstrategy.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS attachments
    ON attachments.resource_id = R.id
    AND attachments.type = 'provider'
    AND lower(attachments.attr_name) = 'attachments'
    AND attachments.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS attachmentsstatus
    ON attachmentsstatus.resource_id = R.id
    AND attachmentsstatus.type = 'provider'
    AND lower(attachmentsstatus.attr_name) = 'attachmentsstatus'
    AND attachmentsstatus.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = 'tags'
    AND _tags.provider_account_id = R.provider_account_id
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
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
      GROUP BY _aws_organizations_account_relation.resource_id
      HAVING COUNT(*) = 1
    ) AS unique_account_mapping
    INNER JOIN resource_relation AS _aws_organizations_account_relation
      ON _aws_organizations_account_relation.resource_id = unique_account_mapping.resource_id
    INNER JOIN resource AS _aws_organizations_account
      ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
      AND _aws_organizations_account.provider_type = 'Account'
      AND _aws_organizations_account.service = 'organizations'
      AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
    WHERE
        _aws_organizations_account_relation.relation = 'in'
        AND _aws_organizations_account_relation.provider_account_id = :provider_account_id
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND PA.provider = 'aws'
  AND R.provider_type = 'Cluster'
  AND R.service = 'ecs'
ON CONFLICT (_id) DO UPDATE
SET
    clusterarn = EXCLUDED.clusterarn,
    clustername = EXCLUDED.clustername,
    status = EXCLUDED.status,
    registeredcontainerinstancescount = EXCLUDED.registeredcontainerinstancescount,
    runningtaskscount = EXCLUDED.runningtaskscount,
    pendingtaskscount = EXCLUDED.pendingtaskscount,
    activeservicescount = EXCLUDED.activeservicescount,
    statistics = EXCLUDED.statistics,
    tags = EXCLUDED.tags,
    settings = EXCLUDED.settings,
    capacityproviders = EXCLUDED.capacityproviders,
    defaultcapacityproviderstrategy = EXCLUDED.defaultcapacityproviderstrategy,
    attachments = EXCLUDED.attachments,
    attachmentsstatus = EXCLUDED.attachmentsstatus,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;

