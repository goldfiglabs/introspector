INSERT INTO aws_dynamodb_backup (
  _id,
  uri,
  provider_account_id,
  tablename,
  tableid,
  tablearn,
  backuparn,
  backupname,
  backupcreationdatetime,
  backupexpirydatetime,
  backupstatus,
  backuptype,
  backupsizebytes,
  _table_id,_account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  tablename.attr_value #>> '{}' AS tablename,
  tableid.attr_value #>> '{}' AS tableid,
  tablearn.attr_value #>> '{}' AS tablearn,
  backuparn.attr_value #>> '{}' AS backuparn,
  backupname.attr_value #>> '{}' AS backupname,
  (TO_TIMESTAMP(backupcreationdatetime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS backupcreationdatetime,
  (TO_TIMESTAMP(backupexpirydatetime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS backupexpirydatetime,
  backupstatus.attr_value #>> '{}' AS backupstatus,
  backuptype.attr_value #>> '{}' AS backuptype,
  (backupsizebytes.attr_value #>> '{}')::bigint AS backupsizebytes,
  
    _table_id.target_id AS _table_id,
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS tablename
    ON tablename.resource_id = R.id
    AND tablename.type = 'provider'
    AND lower(tablename.attr_name) = 'tablename'
  LEFT JOIN resource_attribute AS tableid
    ON tableid.resource_id = R.id
    AND tableid.type = 'provider'
    AND lower(tableid.attr_name) = 'tableid'
  LEFT JOIN resource_attribute AS tablearn
    ON tablearn.resource_id = R.id
    AND tablearn.type = 'provider'
    AND lower(tablearn.attr_name) = 'tablearn'
  LEFT JOIN resource_attribute AS backuparn
    ON backuparn.resource_id = R.id
    AND backuparn.type = 'provider'
    AND lower(backuparn.attr_name) = 'backuparn'
  LEFT JOIN resource_attribute AS backupname
    ON backupname.resource_id = R.id
    AND backupname.type = 'provider'
    AND lower(backupname.attr_name) = 'backupname'
  LEFT JOIN resource_attribute AS backupcreationdatetime
    ON backupcreationdatetime.resource_id = R.id
    AND backupcreationdatetime.type = 'provider'
    AND lower(backupcreationdatetime.attr_name) = 'backupcreationdatetime'
  LEFT JOIN resource_attribute AS backupexpirydatetime
    ON backupexpirydatetime.resource_id = R.id
    AND backupexpirydatetime.type = 'provider'
    AND lower(backupexpirydatetime.attr_name) = 'backupexpirydatetime'
  LEFT JOIN resource_attribute AS backupstatus
    ON backupstatus.resource_id = R.id
    AND backupstatus.type = 'provider'
    AND lower(backupstatus.attr_name) = 'backupstatus'
  LEFT JOIN resource_attribute AS backuptype
    ON backuptype.resource_id = R.id
    AND backuptype.type = 'provider'
    AND lower(backuptype.attr_name) = 'backuptype'
  LEFT JOIN resource_attribute AS backupsizebytes
    ON backupsizebytes.resource_id = R.id
    AND backupsizebytes.type = 'provider'
    AND lower(backupsizebytes.attr_name) = 'backupsizebytes'
  LEFT JOIN (
    SELECT
      _aws_dynamodb_table_relation.resource_id AS resource_id,
      _aws_dynamodb_table.id AS target_id
    FROM
      resource_relation AS _aws_dynamodb_table_relation
      INNER JOIN resource AS _aws_dynamodb_table
        ON _aws_dynamodb_table_relation.target_id = _aws_dynamodb_table.id
        AND _aws_dynamodb_table.provider_type = 'Table'
        AND _aws_dynamodb_table.service = 'dynamodb'
    WHERE
      _aws_dynamodb_table_relation.relation = 'backup-of'
  ) AS _table_id ON _table_id.resource_id = R.id
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
      GROUP BY _aws_organizations_account_relation.resource_id
      HAVING COUNT(*) = 1
    ) AS unique_account_mapping
    INNER JOIN resource_relation AS _aws_organizations_account_relation
      ON _aws_organizations_account_relation.resource_id = unique_account_mapping.resource_id
    INNER JOIN resource AS _aws_organizations_account
      ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
      AND _aws_organizations_account.provider_type = 'Account'
      AND _aws_organizations_account.service = 'organizations'
    WHERE
        _aws_organizations_account_relation.relation = 'in'
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  PA.provider = 'aws'
  AND R.provider_type = 'Backup'
  AND R.service = 'dynamodb'
ON CONFLICT (_id) DO UPDATE
SET
    tablename = EXCLUDED.tablename,
    tableid = EXCLUDED.tableid,
    tablearn = EXCLUDED.tablearn,
    backuparn = EXCLUDED.backuparn,
    backupname = EXCLUDED.backupname,
    backupcreationdatetime = EXCLUDED.backupcreationdatetime,
    backupexpirydatetime = EXCLUDED.backupexpirydatetime,
    backupstatus = EXCLUDED.backupstatus,
    backuptype = EXCLUDED.backuptype,
    backupsizebytes = EXCLUDED.backupsizebytes,
    _table_id = EXCLUDED._table_id,
    _account_id = EXCLUDED._account_id
  ;

