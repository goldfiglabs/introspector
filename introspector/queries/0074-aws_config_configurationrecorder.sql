INSERT INTO aws_config_configurationrecorder (
  _id,
  uri,
  provider_account_id,
  rolearn,
  allsupported,
  includeglobalresourcetypes,
  resourcetypes,
  name,
  laststarttime,
  laststoptime,
  recording,
  laststatus,
  lasterrorcode,
  lasterrormessage,
  laststatuschangetime,
  _iam_role_id,_account_id
)
SELECT
  R.id AS _id,
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
  LEFT JOIN resource_attribute AS rolearn
    ON rolearn.resource_id = R.id
    AND rolearn.type = 'provider'
    AND lower(rolearn.attr_name) = 'rolearn'
    AND rolearn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS allsupported
    ON allsupported.resource_id = R.id
    AND allsupported.type = 'provider'
    AND lower(allsupported.attr_name) = 'allsupported'
    AND allsupported.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS includeglobalresourcetypes
    ON includeglobalresourcetypes.resource_id = R.id
    AND includeglobalresourcetypes.type = 'provider'
    AND lower(includeglobalresourcetypes.attr_name) = 'includeglobalresourcetypes'
    AND includeglobalresourcetypes.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS resourcetypes
    ON resourcetypes.resource_id = R.id
    AND resourcetypes.type = 'provider'
    AND lower(resourcetypes.attr_name) = 'resourcetypes'
    AND resourcetypes.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS name
    ON name.resource_id = R.id
    AND name.type = 'provider'
    AND lower(name.attr_name) = 'name'
    AND name.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS laststarttime
    ON laststarttime.resource_id = R.id
    AND laststarttime.type = 'provider'
    AND lower(laststarttime.attr_name) = 'laststarttime'
    AND laststarttime.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS laststoptime
    ON laststoptime.resource_id = R.id
    AND laststoptime.type = 'provider'
    AND lower(laststoptime.attr_name) = 'laststoptime'
    AND laststoptime.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS recording
    ON recording.resource_id = R.id
    AND recording.type = 'provider'
    AND lower(recording.attr_name) = 'recording'
    AND recording.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS laststatus
    ON laststatus.resource_id = R.id
    AND laststatus.type = 'provider'
    AND lower(laststatus.attr_name) = 'laststatus'
    AND laststatus.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS lasterrorcode
    ON lasterrorcode.resource_id = R.id
    AND lasterrorcode.type = 'provider'
    AND lower(lasterrorcode.attr_name) = 'lasterrorcode'
    AND lasterrorcode.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS lasterrormessage
    ON lasterrormessage.resource_id = R.id
    AND lasterrormessage.type = 'provider'
    AND lower(lasterrormessage.attr_name) = 'lasterrormessage'
    AND lasterrormessage.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS laststatuschangetime
    ON laststatuschangetime.resource_id = R.id
    AND laststatuschangetime.type = 'provider'
    AND lower(laststatuschangetime.attr_name) = 'laststatuschangetime'
    AND laststatuschangetime.provider_account_id = R.provider_account_id
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
  AND R.provider_type = 'ConfigurationRecorder'
  AND R.service = 'config'
ON CONFLICT (_id) DO UPDATE
SET
    rolearn = EXCLUDED.rolearn,
    allsupported = EXCLUDED.allsupported,
    includeglobalresourcetypes = EXCLUDED.includeglobalresourcetypes,
    resourcetypes = EXCLUDED.resourcetypes,
    name = EXCLUDED.name,
    laststarttime = EXCLUDED.laststarttime,
    laststoptime = EXCLUDED.laststoptime,
    recording = EXCLUDED.recording,
    laststatus = EXCLUDED.laststatus,
    lasterrorcode = EXCLUDED.lasterrorcode,
    lasterrormessage = EXCLUDED.lasterrormessage,
    laststatuschangetime = EXCLUDED.laststatuschangetime,
    _iam_role_id = EXCLUDED._iam_role_id,
    _account_id = EXCLUDED._account_id
  ;

