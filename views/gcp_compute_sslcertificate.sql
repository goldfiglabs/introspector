DROP MATERIALIZED VIEW IF EXISTS gcp_compute_sslcertificate CASCADE;

CREATE MATERIALIZED VIEW gcp_compute_sslcertificate AS
WITH cte_resourceattrs AS (
    SELECT
        resource.id,
        resource.uri,
        resource.provider_account_id,
        resource_attribute.resource_id,
        LOWER(resource_attribute.attr_name) AS attr_name,
        resource_attribute.attr_value
    FROM
        RESOURCE
        INNER JOIN provider_account ON resource.provider_account_id = provider_account.id
        INNER JOIN resource_attribute ON resource.id = resource_attribute.resource_id
    WHERE
        resource.provider_type = 'sslCertificate'
        AND provider_account.provider = 'gcp'
        AND resource_attribute.type = 'provider'
)
SELECT DISTINCT
    _key.resource_id,
    _key.uri,
    _key.provider_account_id,
    (_clsc_1.attr_value  #>> '{}') AS "certificate",
    (TO_TIMESTAMP(_clsc_2.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS "creationtimestamp",
    (_clsc_3.attr_value #>> '{}') AS "description",
    (TO_TIMESTAMP(_clsc_4.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS "expiretime",
    (_clsc_5.attr_value #>> '{}') AS "id",
    (_clsc_6.attr_value #>> '{}') AS "kind",
    (_clsc_7.attr_value::jsonb) AS "managed",
    (_clsc_8.attr_value #>> '{}') AS "name",
    (_clsc_9.attr_value #>> '{}') AS "privatekey",
    (_clsc_11.attr_value #>> '{}') AS "selflink",
    (_clsc_12.attr_value::jsonb) AS "selfmanaged",
    (_clsc_13.attr_value::jsonb) AS "subjectalternativenames",
    (_clsc_14.attr_value #>> '{}') AS "type"
FROM ( SELECT DISTINCT
        uri,
        resource_id,
        id,
        provider_account_id
    FROM
        cte_resourceattrs) _key
    LEFT JOIN cte_resourceattrs AS _clsc_1 ON _clsc_1.uri = _key.uri
        AND _clsc_1.resource_id = _key.resource_id
        AND _clsc_1.id = _key.id
        AND _clsc_1.attr_name = 'certificate'
    LEFT JOIN cte_resourceattrs AS _clsc_2 ON _clsc_2.uri = _key.uri
        AND _clsc_2.resource_id = _key.resource_id
        AND _clsc_2.id = _key.id
        AND _clsc_2.attr_name = 'creationtimestamp'
    LEFT JOIN cte_resourceattrs AS _clsc_3 ON _clsc_3.uri = _key.uri
        AND _clsc_3.resource_id = _key.resource_id
        AND _clsc_3.id = _key.id
        AND _clsc_3.attr_name = 'description'
    LEFT JOIN cte_resourceattrs AS _clsc_4 ON _clsc_4.uri = _key.uri
        AND _clsc_4.resource_id = _key.resource_id
        AND _clsc_4.id = _key.id
        AND _clsc_4.attr_name = 'expiretime'
    LEFT JOIN cte_resourceattrs AS _clsc_5 ON _clsc_5.uri = _key.uri
        AND _clsc_5.resource_id = _key.resource_id
        AND _clsc_5.id = _key.id
        AND _clsc_5.attr_name = 'id'
    LEFT JOIN cte_resourceattrs AS _clsc_6 ON _clsc_6.uri = _key.uri
        AND _clsc_6.resource_id = _key.resource_id
        AND _clsc_6.id = _key.id
        AND _clsc_6.attr_name = 'kind'
    LEFT JOIN cte_resourceattrs AS _clsc_7 ON _clsc_7.uri = _key.uri
        AND _clsc_7.resource_id = _key.resource_id
        AND _clsc_7.id = _key.id
        AND _clsc_7.attr_name = 'managed'
    LEFT JOIN cte_resourceattrs AS _clsc_8 ON _clsc_8.uri = _key.uri
        AND _clsc_8.resource_id = _key.resource_id
        AND _clsc_8.id = _key.id
        AND _clsc_8.attr_name = 'name'
    LEFT JOIN cte_resourceattrs AS _clsc_9 ON _clsc_9.uri = _key.uri
        AND _clsc_9.resource_id = _key.resource_id
        AND _clsc_9.id = _key.id
        AND _clsc_9.attr_name = 'privatekey'
    LEFT JOIN cte_resourceattrs AS _clsc_10 ON _clsc_10.uri = _key.uri
        AND _clsc_10.resource_id = _key.resource_id
        AND _clsc_10.id = _key.id
        AND _clsc_10.attr_name = 'region'
    LEFT JOIN cte_resourceattrs AS _clsc_11 ON _clsc_11.uri = _key.uri
        AND _clsc_11.resource_id = _key.resource_id
        AND _clsc_11.id = _key.id
        AND _clsc_11.attr_name = 'selflink'
    LEFT JOIN cte_resourceattrs AS _clsc_12 ON _clsc_12.uri = _key.uri
        AND _clsc_12.resource_id = _key.resource_id
        AND _clsc_12.id = _key.id
        AND _clsc_12.attr_name = 'selfmanaged'
    LEFT JOIN cte_resourceattrs AS _clsc_13 ON _clsc_13.uri = _key.uri
        AND _clsc_13.resource_id = _key.resource_id
        AND _clsc_13.id = _key.id
        AND _clsc_13.attr_name = 'subjectalternativenames'
    LEFT JOIN cte_resourceattrs AS _clsc_14 ON _clsc_14.uri = _key.uri
        AND _clsc_14.resource_id = _key.resource_id
        AND _clsc_14.id = _key.id
        AND _clsc_14.attr_name = 'type' WITH NO DATA;

REFRESH MATERIALIZED VIEW gcp_compute_sslcertificate;

COMMENT ON MATERIALIZED VIEW gcp_compute_sslcertificate IS 'GCP compute SSL certificates and their associated attributes.'
