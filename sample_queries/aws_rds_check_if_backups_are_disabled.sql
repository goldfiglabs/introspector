SELECT
    uri,
    dbinstanceidentifier,
    backupretentionperiod
FROM
    aws_rds_dbinstance
WHERE
    backupretentionperiod = 0
