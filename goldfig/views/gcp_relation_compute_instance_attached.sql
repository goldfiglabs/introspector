DROP MATERIALIZED VIEW IF EXISTS gcp_relation_compute_instance_attached CASCADE;

CREATE MATERIALIZED VIEW gcp_relation_compute_instance_attached AS
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
        AND resource.provider_type = 'instance'
        AND resource.service = 'compute'
        AND provider_account.provider = 'gcp'
)
SELECT DISTINCT
    cte_resourceattrs.resource_id,
    cte_resourceattrs.target_id,
    (_clsc_1.value::boolean) AS "autodelete",
    (_clsc_2.value::boolean) AS "boot",
    (_clsc_3.value #>> '{}') AS "devicename",
    (_clsc_4.value::integer) AS "index",
    (_clsc_5.value #>> '{}') AS "interface",
    (_clsc_6.value #>> '{}') AS "mode",
    (_clsc_7.value #>> '{}') AS "type"
FROM
    cte_resourceattrs
    LEFT JOIN cte_resourceattrs AS _clsc_1 ON _clsc_1.uri = cte_resourceattrs.uri
        AND _clsc_1.resource_id = cte_resourceattrs.resource_id
        AND _clsc_1.name = 'autoDelete'
    LEFT JOIN cte_resourceattrs AS _clsc_2 ON _clsc_2.uri = cte_resourceattrs.uri
        AND _clsc_2.resource_id = cte_resourceattrs.resource_id
        AND _clsc_2.name = 'boot'
    LEFT JOIN cte_resourceattrs AS _clsc_3 ON _clsc_3.uri = cte_resourceattrs.uri
        AND _clsc_3.resource_id = cte_resourceattrs.resource_id
        AND _clsc_3.name = 'deviceName'
    LEFT JOIN cte_resourceattrs AS _clsc_4 ON _clsc_4.uri = cte_resourceattrs.uri
        AND _clsc_4.resource_id = cte_resourceattrs.resource_id
        AND _clsc_4.name = 'index'
    LEFT JOIN cte_resourceattrs AS _clsc_5 ON _clsc_5.uri = cte_resourceattrs.uri
        AND _clsc_5.resource_id = cte_resourceattrs.resource_id
        AND _clsc_5.name = 'interface'
    LEFT JOIN cte_resourceattrs AS _clsc_6 ON _clsc_6.uri = cte_resourceattrs.uri
        AND _clsc_6.resource_id = cte_resourceattrs.resource_id
        AND _clsc_6.name = 'mode'
    LEFT JOIN cte_resourceattrs AS _clsc_7 ON _clsc_7.uri = cte_resourceattrs.uri
        AND _clsc_7.resource_id = cte_resourceattrs.resource_id
        AND _clsc_7.name = 'type' WITH NO data;

REFRESH MATERIALIZED VIEW gcp_relation_compute_instance_attached;

COMMENT ON MATERIALIZED VIEW gcp_relation_compute_instance_attached IS 'GCP compute instance attached relationships.'
