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
  attrs.provider ->> 'roleARN' AS rolearn,
  (attrs.provider ->> 'allSupported')::boolean AS allsupported,
  (attrs.provider ->> 'includeGlobalResourceTypes')::boolean AS includeglobalresourcetypes,
  attrs.provider -> 'resourceTypes' AS resourcetypes,
  attrs.provider ->> 'name' AS name,
  (TO_TIMESTAMP(attrs.provider ->> 'lastStartTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS laststarttime,
  (TO_TIMESTAMP(attrs.provider ->> 'lastStopTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS laststoptime,
  (attrs.provider ->> 'recording')::boolean AS recording,
  attrs.provider ->> 'lastStatus' AS laststatus,
  attrs.provider ->> 'lastErrorCode' AS lasterrorcode,
  attrs.provider ->> 'lastErrorMessage' AS lasterrormessage,
  (TO_TIMESTAMP(attrs.provider ->> 'lastStatusChangeTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS laststatuschangetime,
  
    _iam_role_id.target_id AS _iam_role_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
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
  AND R.provider_type = 'ConfigurationRecorder'
  AND R.service = 'config'
ON CONFLICT (_id) DO UPDATE
SET
    roleARN = EXCLUDED.roleARN,
    allSupported = EXCLUDED.allSupported,
    includeGlobalResourceTypes = EXCLUDED.includeGlobalResourceTypes,
    resourceTypes = EXCLUDED.resourceTypes,
    name = EXCLUDED.name,
    lastStartTime = EXCLUDED.lastStartTime,
    lastStopTime = EXCLUDED.lastStopTime,
    recording = EXCLUDED.recording,
    lastStatus = EXCLUDED.lastStatus,
    lastErrorCode = EXCLUDED.lastErrorCode,
    lastErrorMessage = EXCLUDED.lastErrorMessage,
    lastStatusChangeTime = EXCLUDED.lastStatusChangeTime,
    _iam_role_id = EXCLUDED._iam_role_id,
    _account_id = EXCLUDED._account_id
  ;

