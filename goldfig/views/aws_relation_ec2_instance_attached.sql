DROP MATERIALIZED VIEW IF EXISTS aws_relation_ec2_instance_attached CASCADE;

CREATE MATERIALIZED VIEW aws_relation_ec2_instance_attached AS
WITH cte_resourceattrs AS (
    SELECT
        resource.id AS resource_id,
        resource.uri,
        resource.provider_account_id,
        resource_relation.relation,
        resource_relation.target_id,
        resource_relation_attribute.name,
        resource_relation_attribute.value
    FROM
        resource
        INNER JOIN resource_relation ON resource.id = resource_relation.resource_id
        INNER JOIN resource_relation_attribute ON resource_relation.id = resource_relation_attribute.relation_id
        INNER JOIN provider_account ON resource.provider_account_id = provider_account.id
    WHERE
        resource_relation.relation = 'attached'
        AND resource.provider_type = 'Instance'
        AND resource.service = 'ec2'
        AND provider_account.provider = 'aws'
)
SELECT DISTINCT
    cte_resourceattrs.resource_id,
    cte_resourceattrs.target_id,
    (_clsc_1.value::boolean) AS "deleteontermination",
    (TO_TIMESTAMP(_clsc_2.value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS "attachtime",
    (_clsc_3.value #>> '{}') AS "volumeid",
    (_clsc_4.value #>> '{}') AS "status",
    (_clsc_5.value #>> '{}') AS "devicename"
FROM
    cte_resourceattrs
    LEFT JOIN cte_resourceattrs AS _clsc_1 ON _clsc_1.uri = cte_resourceattrs.uri
        AND _clsc_1.resource_id = cte_resourceattrs.resource_id
        AND _clsc_1.name = 'DeleteOnTermination'
    LEFT JOIN cte_resourceattrs AS _clsc_2 ON _clsc_2.uri = cte_resourceattrs.uri
        AND _clsc_2.resource_id = cte_resourceattrs.resource_id
        AND _clsc_2.name = 'AttachTime'
    LEFT JOIN cte_resourceattrs AS _clsc_3 ON _clsc_3.uri = cte_resourceattrs.uri
        AND _clsc_3.resource_id = cte_resourceattrs.resource_id
        AND _clsc_3.name = 'VolumeId'
    LEFT JOIN cte_resourceattrs AS _clsc_4 ON _clsc_4.uri = cte_resourceattrs.uri
        AND _clsc_4.resource_id = cte_resourceattrs.resource_id
        AND _clsc_4.name = 'Status'
    LEFT JOIN cte_resourceattrs AS _clsc_5 ON _clsc_5.uri = cte_resourceattrs.uri
        AND _clsc_5.resource_id = cte_resourceattrs.resource_id
        AND _clsc_5.name = 'DeviceName' WITH NO data;

REFRESH MATERIALIZED VIEW aws_relation_ec2_instance_attached;

COMMENT ON MATERIALIZED VIEW aws_relation_ec2_instance_attached IS 'AWS EC2 instance attached relationships.'
