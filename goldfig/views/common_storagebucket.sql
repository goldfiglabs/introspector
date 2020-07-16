DROP MATERIALIZED VIEW IF EXISTS common_storagebucket CASCADE;

CREATE MATERIALIZED VIEW common_storagebucket AS
WITH cte_resourceattrs AS (
    SELECT
        resource.uri,
        resource.id,
        resource.provider_account_id,
        resource_attribute.resource_id,
        LOWER(resource_attribute.attr_name) AS attr_name,
        resource_attribute.attr_value
    FROM
        RESOURCE
        INNER JOIN resource_attribute ON resource.id = resource_attribute.resource_id
    WHERE
        resource.category = 'StorageBucket'
        AND resource_attribute.type = 'Metadata'
)
SELECT DISTINCT
    _key.resource_id,
    _key.uri,
    _key.provider_account_id,
    (_clsc_1.attr_value) AS "created",
    (_clsc_2.attr_value) AS "owner",
    (_clsc_3.attr_value) AS "region",
    (_clsc_4.attr_value) AS "tags"
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
        AND _clsc_1.attr_name = 'created'
    LEFT JOIN cte_resourceattrs AS _clsc_2 ON _clsc_2.uri = _key.uri
        AND _clsc_2.resource_id = _key.resource_id
        AND _clsc_2.id = _key.id
        AND _clsc_2.attr_name = 'owner'
    LEFT JOIN cte_resourceattrs AS _clsc_3 ON _clsc_3.uri = _key.uri
        AND _clsc_3.resource_id = _key.resource_id
        AND _clsc_3.id = _key.id
        AND _clsc_3.attr_name = 'region'
    LEFT JOIN cte_resourceattrs AS _clsc_4 ON _clsc_4.uri = _key.uri
        AND _clsc_4.resource_id = _key.resource_id
        AND _clsc_4.id = _key.id
        AND _clsc_4.attr_name = 'tags' WITH NO DATA;

REFRESH MATERIALIZED VIEW common_storagebucket;

COMMENT ON MATERIALIZED VIEW common_storagebucket IS 'Common attributes across all provider storage buckets.';

