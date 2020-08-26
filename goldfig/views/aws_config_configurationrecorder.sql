DROP MATERIALIZED VIEW IF EXISTS aws_config_configurationrecorder CASCADE;

CREATE MATERIALIZED VIEW aws_config_configurationrecorder AS
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
  rolearn.attr_value #>> '{}' AS rolearn,
  (allsupported.attr_value #>> '{}')::boolean AS allsupported,
  (includeglobalresourcetypes.attr_value #>> '{}')::boolean AS includeglobalresourcetypes,
  resourcetypes.attr_value::jsonb AS resourcetypes,
  name.attr_value #>> '{}' AS name,
  (TO_TIMESTAMP(laststarttime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS laststarttime,
  (TO_TIMESTAMP(laststoptime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS laststoptime,
  (recording.attr_value #>> '{}')::boolean AS recording,
  laststatus.attr_value #>> '{}' AS laststatus,
  lasterrorcode.attr_value #>> '{}' AS lasterrorcode,
  lasterrormessage.attr_value #>> '{}' AS lasterrormessage,
  (TO_TIMESTAMP(laststatuschangetime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS laststatuschangetime,
  
    _iam_role_id.target_id AS _iam_role_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS rolearn
    ON rolearn.id = R.id
    AND rolearn.attr_name = 'rolearn'
  LEFT JOIN attrs AS allsupported
    ON allsupported.id = R.id
    AND allsupported.attr_name = 'allsupported'
  LEFT JOIN attrs AS includeglobalresourcetypes
    ON includeglobalresourcetypes.id = R.id
    AND includeglobalresourcetypes.attr_name = 'includeglobalresourcetypes'
  LEFT JOIN attrs AS resourcetypes
    ON resourcetypes.id = R.id
    AND resourcetypes.attr_name = 'resourcetypes'
  LEFT JOIN attrs AS name
    ON name.id = R.id
    AND name.attr_name = 'name'
  LEFT JOIN attrs AS laststarttime
    ON laststarttime.id = R.id
    AND laststarttime.attr_name = 'laststarttime'
  LEFT JOIN attrs AS laststoptime
    ON laststoptime.id = R.id
    AND laststoptime.attr_name = 'laststoptime'
  LEFT JOIN attrs AS recording
    ON recording.id = R.id
    AND recording.attr_name = 'recording'
  LEFT JOIN attrs AS laststatus
    ON laststatus.id = R.id
    AND laststatus.attr_name = 'laststatus'
  LEFT JOIN attrs AS lasterrorcode
    ON lasterrorcode.id = R.id
    AND lasterrorcode.attr_name = 'lasterrorcode'
  LEFT JOIN attrs AS lasterrormessage
    ON lasterrormessage.id = R.id
    AND lasterrormessage.attr_name = 'lasterrormessage'
  LEFT JOIN attrs AS laststatuschangetime
    ON laststatuschangetime.id = R.id
    AND laststatuschangetime.attr_name = 'laststatuschangetime'
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
  AND LOWER(R.provider_type) = 'configurationrecorder'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_config_configurationrecorder;

COMMENT ON MATERIALIZED VIEW aws_config_configurationrecorder IS 'config configurationrecorder resources and their associated attributes.';

