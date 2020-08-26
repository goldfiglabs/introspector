DROP MATERIALIZED VIEW IF EXISTS aws_ec2_volume CASCADE;

CREATE MATERIALIZED VIEW aws_ec2_volume AS
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
  attachments.attr_value::jsonb AS attachments,
  availabilityzone.attr_value #>> '{}' AS availabilityzone,
  (TO_TIMESTAMP(createtime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS createtime,
  (encrypted.attr_value #>> '{}')::boolean AS encrypted,
  kmskeyid.attr_value #>> '{}' AS kmskeyid,
  outpostarn.attr_value #>> '{}' AS outpostarn,
  (size.attr_value #>> '{}')::integer AS size,
  snapshotid.attr_value #>> '{}' AS snapshotid,
  state.attr_value #>> '{}' AS state,
  volumeid.attr_value #>> '{}' AS volumeid,
  (iops.attr_value #>> '{}')::integer AS iops,
  tags.attr_value::jsonb AS tags,
  volumetype.attr_value #>> '{}' AS volumetype,
  (fastrestored.attr_value #>> '{}')::boolean AS fastrestored,
  (multiattachenabled.attr_value #>> '{}')::boolean AS multiattachenabled,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS attachments
    ON attachments.id = R.id
    AND attachments.attr_name = 'attachments'
  LEFT JOIN attrs AS availabilityzone
    ON availabilityzone.id = R.id
    AND availabilityzone.attr_name = 'availabilityzone'
  LEFT JOIN attrs AS createtime
    ON createtime.id = R.id
    AND createtime.attr_name = 'createtime'
  LEFT JOIN attrs AS encrypted
    ON encrypted.id = R.id
    AND encrypted.attr_name = 'encrypted'
  LEFT JOIN attrs AS kmskeyid
    ON kmskeyid.id = R.id
    AND kmskeyid.attr_name = 'kmskeyid'
  LEFT JOIN attrs AS outpostarn
    ON outpostarn.id = R.id
    AND outpostarn.attr_name = 'outpostarn'
  LEFT JOIN attrs AS size
    ON size.id = R.id
    AND size.attr_name = 'size'
  LEFT JOIN attrs AS snapshotid
    ON snapshotid.id = R.id
    AND snapshotid.attr_name = 'snapshotid'
  LEFT JOIN attrs AS state
    ON state.id = R.id
    AND state.attr_name = 'state'
  LEFT JOIN attrs AS volumeid
    ON volumeid.id = R.id
    AND volumeid.attr_name = 'volumeid'
  LEFT JOIN attrs AS iops
    ON iops.id = R.id
    AND iops.attr_name = 'iops'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS volumetype
    ON volumetype.id = R.id
    AND volumetype.attr_name = 'volumetype'
  LEFT JOIN attrs AS fastrestored
    ON fastrestored.id = R.id
    AND fastrestored.attr_name = 'fastrestored'
  LEFT JOIN attrs AS multiattachenabled
    ON multiattachenabled.id = R.id
    AND multiattachenabled.attr_name = 'multiattachenabled'
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
  AND LOWER(R.provider_type) = 'volume'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_ec2_volume;

COMMENT ON MATERIALIZED VIEW aws_ec2_volume IS 'ec2 volume resources and their associated attributes.';

