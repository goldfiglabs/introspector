INSERT INTO aws_dynamodb_table (
  _id,
  uri,
  provider_account_id,
  attributedefinitions,
  tablename,
  keyschema,
  tablestatus,
  creationdatetime,
  provisionedthroughput,
  tablesizebytes,
  itemcount,
  tablearn,
  tableid,
  billingmodesummary,
  localsecondaryindexes,
  globalsecondaryindexes,
  streamspecification,
  lateststreamlabel,
  lateststreamarn,
  globaltableversion,
  replicas,
  restoresummary,
  ssedescription,
  archivalsummary,
  continuousbackupsstatus,
  pointintimerecoverydescription,
  tags,
  _tags,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  attributedefinitions.attr_value::jsonb AS attributedefinitions,
  tablename.attr_value #>> '{}' AS tablename,
  keyschema.attr_value::jsonb AS keyschema,
  tablestatus.attr_value #>> '{}' AS tablestatus,
  (TO_TIMESTAMP(creationdatetime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS creationdatetime,
  provisionedthroughput.attr_value::jsonb AS provisionedthroughput,
  (tablesizebytes.attr_value #>> '{}')::bigint AS tablesizebytes,
  (itemcount.attr_value #>> '{}')::bigint AS itemcount,
  tablearn.attr_value #>> '{}' AS tablearn,
  tableid.attr_value #>> '{}' AS tableid,
  billingmodesummary.attr_value::jsonb AS billingmodesummary,
  localsecondaryindexes.attr_value::jsonb AS localsecondaryindexes,
  globalsecondaryindexes.attr_value::jsonb AS globalsecondaryindexes,
  streamspecification.attr_value::jsonb AS streamspecification,
  lateststreamlabel.attr_value #>> '{}' AS lateststreamlabel,
  lateststreamarn.attr_value #>> '{}' AS lateststreamarn,
  globaltableversion.attr_value #>> '{}' AS globaltableversion,
  replicas.attr_value::jsonb AS replicas,
  restoresummary.attr_value::jsonb AS restoresummary,
  ssedescription.attr_value::jsonb AS ssedescription,
  archivalsummary.attr_value::jsonb AS archivalsummary,
  continuousbackupsstatus.attr_value #>> '{}' AS continuousbackupsstatus,
  pointintimerecoverydescription.attr_value::jsonb AS pointintimerecoverydescription,
  tags.attr_value::jsonb AS tags,
  _tags.attr_value::jsonb AS _tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS attributedefinitions
    ON attributedefinitions.resource_id = R.id
    AND attributedefinitions.type = 'provider'
    AND lower(attributedefinitions.attr_name) = 'attributedefinitions'
    AND attributedefinitions.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tablename
    ON tablename.resource_id = R.id
    AND tablename.type = 'provider'
    AND lower(tablename.attr_name) = 'tablename'
    AND tablename.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS keyschema
    ON keyschema.resource_id = R.id
    AND keyschema.type = 'provider'
    AND lower(keyschema.attr_name) = 'keyschema'
    AND keyschema.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tablestatus
    ON tablestatus.resource_id = R.id
    AND tablestatus.type = 'provider'
    AND lower(tablestatus.attr_name) = 'tablestatus'
    AND tablestatus.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS creationdatetime
    ON creationdatetime.resource_id = R.id
    AND creationdatetime.type = 'provider'
    AND lower(creationdatetime.attr_name) = 'creationdatetime'
    AND creationdatetime.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS provisionedthroughput
    ON provisionedthroughput.resource_id = R.id
    AND provisionedthroughput.type = 'provider'
    AND lower(provisionedthroughput.attr_name) = 'provisionedthroughput'
    AND provisionedthroughput.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tablesizebytes
    ON tablesizebytes.resource_id = R.id
    AND tablesizebytes.type = 'provider'
    AND lower(tablesizebytes.attr_name) = 'tablesizebytes'
    AND tablesizebytes.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS itemcount
    ON itemcount.resource_id = R.id
    AND itemcount.type = 'provider'
    AND lower(itemcount.attr_name) = 'itemcount'
    AND itemcount.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tablearn
    ON tablearn.resource_id = R.id
    AND tablearn.type = 'provider'
    AND lower(tablearn.attr_name) = 'tablearn'
    AND tablearn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tableid
    ON tableid.resource_id = R.id
    AND tableid.type = 'provider'
    AND lower(tableid.attr_name) = 'tableid'
    AND tableid.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS billingmodesummary
    ON billingmodesummary.resource_id = R.id
    AND billingmodesummary.type = 'provider'
    AND lower(billingmodesummary.attr_name) = 'billingmodesummary'
    AND billingmodesummary.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS localsecondaryindexes
    ON localsecondaryindexes.resource_id = R.id
    AND localsecondaryindexes.type = 'provider'
    AND lower(localsecondaryindexes.attr_name) = 'localsecondaryindexes'
    AND localsecondaryindexes.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS globalsecondaryindexes
    ON globalsecondaryindexes.resource_id = R.id
    AND globalsecondaryindexes.type = 'provider'
    AND lower(globalsecondaryindexes.attr_name) = 'globalsecondaryindexes'
    AND globalsecondaryindexes.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS streamspecification
    ON streamspecification.resource_id = R.id
    AND streamspecification.type = 'provider'
    AND lower(streamspecification.attr_name) = 'streamspecification'
    AND streamspecification.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS lateststreamlabel
    ON lateststreamlabel.resource_id = R.id
    AND lateststreamlabel.type = 'provider'
    AND lower(lateststreamlabel.attr_name) = 'lateststreamlabel'
    AND lateststreamlabel.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS lateststreamarn
    ON lateststreamarn.resource_id = R.id
    AND lateststreamarn.type = 'provider'
    AND lower(lateststreamarn.attr_name) = 'lateststreamarn'
    AND lateststreamarn.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS globaltableversion
    ON globaltableversion.resource_id = R.id
    AND globaltableversion.type = 'provider'
    AND lower(globaltableversion.attr_name) = 'globaltableversion'
    AND globaltableversion.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS replicas
    ON replicas.resource_id = R.id
    AND replicas.type = 'provider'
    AND lower(replicas.attr_name) = 'replicas'
    AND replicas.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS restoresummary
    ON restoresummary.resource_id = R.id
    AND restoresummary.type = 'provider'
    AND lower(restoresummary.attr_name) = 'restoresummary'
    AND restoresummary.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS ssedescription
    ON ssedescription.resource_id = R.id
    AND ssedescription.type = 'provider'
    AND lower(ssedescription.attr_name) = 'ssedescription'
    AND ssedescription.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS archivalsummary
    ON archivalsummary.resource_id = R.id
    AND archivalsummary.type = 'provider'
    AND lower(archivalsummary.attr_name) = 'archivalsummary'
    AND archivalsummary.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS continuousbackupsstatus
    ON continuousbackupsstatus.resource_id = R.id
    AND continuousbackupsstatus.type = 'provider'
    AND lower(continuousbackupsstatus.attr_name) = 'continuousbackupsstatus'
    AND continuousbackupsstatus.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS pointintimerecoverydescription
    ON pointintimerecoverydescription.resource_id = R.id
    AND pointintimerecoverydescription.type = 'provider'
    AND lower(pointintimerecoverydescription.attr_name) = 'pointintimerecoverydescription'
    AND pointintimerecoverydescription.provider_account_id = R.provider_account_id
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
    AND tags.provider_account_id = R.provider_account_id
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
  AND R.provider_type = 'Table'
  AND R.service = 'dynamodb'
ON CONFLICT (_id) DO UPDATE
SET
    attributedefinitions = EXCLUDED.attributedefinitions,
    tablename = EXCLUDED.tablename,
    keyschema = EXCLUDED.keyschema,
    tablestatus = EXCLUDED.tablestatus,
    creationdatetime = EXCLUDED.creationdatetime,
    provisionedthroughput = EXCLUDED.provisionedthroughput,
    tablesizebytes = EXCLUDED.tablesizebytes,
    itemcount = EXCLUDED.itemcount,
    tablearn = EXCLUDED.tablearn,
    tableid = EXCLUDED.tableid,
    billingmodesummary = EXCLUDED.billingmodesummary,
    localsecondaryindexes = EXCLUDED.localsecondaryindexes,
    globalsecondaryindexes = EXCLUDED.globalsecondaryindexes,
    streamspecification = EXCLUDED.streamspecification,
    lateststreamlabel = EXCLUDED.lateststreamlabel,
    lateststreamarn = EXCLUDED.lateststreamarn,
    globaltableversion = EXCLUDED.globaltableversion,
    replicas = EXCLUDED.replicas,
    restoresummary = EXCLUDED.restoresummary,
    ssedescription = EXCLUDED.ssedescription,
    archivalsummary = EXCLUDED.archivalsummary,
    continuousbackupsstatus = EXCLUDED.continuousbackupsstatus,
    pointintimerecoverydescription = EXCLUDED.pointintimerecoverydescription,
    tags = EXCLUDED.tags,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;

