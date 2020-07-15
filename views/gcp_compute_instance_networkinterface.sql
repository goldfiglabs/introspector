DROP MATERIALIZED VIEW IF EXISTS gcp_compute_instance_networkinterface CASCADE;

CREATE MATERIALIZED VIEW gcp_compute_instance_networkinterface AS
WITH cte_compute_networks AS (
    WITH cte_elements AS (
        WITH cte_ni AS (
            SELECT
                resource_id,
                uri,
                provider_account_id,
                networkinterfaces
            FROM
                gcp_compute_instance
)
            SELECT
                resource_id,
                uri,
                provider_account_id,
                ni_ea_element.*
            FROM
                cte_ni
            CROSS JOIN LATERAL JSONB_ARRAY_ELEMENTS(networkinterfaces) AS ni_element
            CROSS JOIN LATERAL JSONB_EACH(ni_element) AS ni_ea_element
)
        SELECT DISTINCT
            _key.resource_id,
            _key.uri,
            _key.provider_account_id,
            (_clsc_1.value #>> '{}') AS "kind",
            (_clsc_2.value #>> '{}') AS "name",
            (_clsc_3.value #>> '{}') AS "network",
            (_clsc_4.value #>> '{}') AS "networkip",
            (_clsc_5.value #>> '{}') AS "subnetwork",
            (_clsc_6.value #>> '{}') AS "fingerprint",
            (_clsc_7.value::jsonb) AS "accessconfigs"
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
            AND _clsc_3.key = 'network'
        LEFT JOIN cte_elements AS _clsc_4 ON _clsc_4.uri = _key.uri
            AND _clsc_4.resource_id = _key.resource_id
            AND _clsc_4.key = 'networkIP'
        LEFT JOIN cte_elements AS _clsc_5 ON _clsc_5.uri = _key.uri
            AND _clsc_5.resource_id = _key.resource_id
            AND _clsc_5.key = 'subnetwork'
        LEFT JOIN cte_elements AS _clsc_6 ON _clsc_6.uri = _key.uri
            AND _clsc_6.resource_id = _key.resource_id
            AND _clsc_6.key = 'fingerprint'
        LEFT JOIN cte_elements AS _clsc_7 ON _clsc_7.uri = _key.uri
            AND _clsc_7.resource_id = _key.resource_id
            AND _clsc_7.key = 'accessConfigs'
)
SELECT
    cte_compute_networks.*
FROM
    cte_compute_networks WITH NO DATA;

REFRESH MATERIALIZED VIEW gcp_compute_instance_networkinterface;

COMMENT ON MATERIALIZED VIEW gcp_compute_instance_networkinterface IS 'GCP compute instance network interfaces and their associated attributes.';

