DROP MATERIALIZED VIEW IF EXISTS gcp_compute_instance_networkinterface_accessconfig CASCADE;

CREATE MATERIALIZED VIEW gcp_compute_instance_networkinterface_accessconfig AS
WITH cte_elements AS (
    WITH cte_ni AS (
        SELECT
            resource_id,
            uri,
            provider_account_id,
            accessconfigs
        FROM
            gcp_compute_instance_networkinterface
)
        SELECT
            resource_id,
            uri,
            provider_account_id,
            ea_element.*
        FROM
            cte_ni
        CROSS JOIN LATERAL JSONB_ARRAY_ELEMENTS(accessconfigs) AS element
        CROSS JOIN LATERAL JSONB_EACH(element) AS ea_element
)
SELECT DISTINCT
    _key.resource_id,
    _key.uri,
    _key.provider_account_id,
    (_clsc_1.value #>> '{}') AS "kind",
    (_clsc_2.value #>> '{}') AS "name",
    (_clsc_3.value #>> '{}') AS "type",
    (_clsc_4.value #>> '{}') AS "natip",
    (_clsc_5.value #>> '{}') AS "networktier"
FROM ( SELECT DISTINCT
        resource_id,
        uri,
        provider_account_id
    FROM
        cte_elements) _key
    LEFT JOIN cte_elements AS _clsc_1 ON _clsc_1.uri = _key.uri
        AND _clsc_1.resource_id = _key.resource_id
        AND _clsc_1.key = 'kind'
    LEFT JOIN cte_elements AS _clsc_2 ON _clsc_2.uri = _key.uri
        AND _clsc_2.resource_id = _key.resource_id
        AND _clsc_2.key = 'name'
    LEFT JOIN cte_elements AS _clsc_3 ON _clsc_3.uri = _key.uri
        AND _clsc_3.resource_id = _key.resource_id
        AND _clsc_3.key = 'type'
    LEFT JOIN cte_elements AS _clsc_4 ON _clsc_4.uri = _key.uri
        AND _clsc_4.resource_id = _key.resource_id
        AND _clsc_4.key = 'natIP'
    LEFT JOIN cte_elements AS _clsc_5 ON _clsc_5.uri = _key.uri
        AND _clsc_5.resource_id = _key.resource_id
        AND _clsc_5.key = 'networkTier' WITH NO DATA;

REFRESH MATERIALIZED VIEW gcp_compute_instance_networkinterface_accessconfig;

COMMENT ON MATERIALIZED VIEW gcp_compute_instance_networkinterface_accessconfig IS 'GCP compute network access configs and their associated attributes.'
