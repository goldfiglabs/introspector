DROP MATERIALIZED VIEW IF EXISTS aws_ecs_cluster CASCADE;

CREATE MATERIALIZED VIEW aws_ecs_cluster AS
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
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS clusterarn
    ON clusterarn.id = R.id
    AND clusterarn.attr_name = 'clusterarn'
  LEFT JOIN attrs AS clustername
    ON clustername.id = R.id
    AND clustername.attr_name = 'clustername'
  LEFT JOIN attrs AS status
    ON status.id = R.id
    AND status.attr_name = 'status'
  LEFT JOIN attrs AS registeredcontainerinstancescount
    ON registeredcontainerinstancescount.id = R.id
    AND registeredcontainerinstancescount.attr_name = 'registeredcontainerinstancescount'
  LEFT JOIN attrs AS runningtaskscount
    ON runningtaskscount.id = R.id
    AND runningtaskscount.attr_name = 'runningtaskscount'
  LEFT JOIN attrs AS pendingtaskscount
    ON pendingtaskscount.id = R.id
    AND pendingtaskscount.attr_name = 'pendingtaskscount'
  LEFT JOIN attrs AS activeservicescount
    ON activeservicescount.id = R.id
    AND activeservicescount.attr_name = 'activeservicescount'
  LEFT JOIN attrs AS statistics
    ON statistics.id = R.id
    AND statistics.attr_name = 'statistics'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS settings
    ON settings.id = R.id
    AND settings.attr_name = 'settings'
  LEFT JOIN attrs AS capacityproviders
    ON capacityproviders.id = R.id
    AND capacityproviders.attr_name = 'capacityproviders'
  LEFT JOIN attrs AS defaultcapacityproviderstrategy
    ON defaultcapacityproviderstrategy.id = R.id
    AND defaultcapacityproviderstrategy.attr_name = 'defaultcapacityproviderstrategy'
  LEFT JOIN attrs AS attachments
    ON attachments.id = R.id
    AND attachments.attr_name = 'attachments'
  LEFT JOIN attrs AS attachmentsstatus
    ON attachmentsstatus.id = R.id
    AND attachmentsstatus.attr_name = 'attachmentsstatus'
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
  AND LOWER(R.provider_type) = 'cluster'
  AND R.service = 'ecs'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_ecs_cluster;

COMMENT ON MATERIALIZED VIEW aws_ecs_cluster IS 'ecs cluster resources and their associated attributes.';

