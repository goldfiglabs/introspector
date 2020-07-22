DROP MATERIALIZED VIEW IF EXISTS gcp_compute_image CASCADE;

CREATE MATERIALIZED VIEW gcp_compute_image AS
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
        resource.category = 'Image'
        AND provider_account.provider = 'gcp'
        AND resource_attribute.type = 'provider'
)
SELECT DISTINCT
    _key.resource_id,
    _key.uri,
    _key.provider_account_id,
    (_clsc_1.attr_value #>> '{}')::bigint AS "archivesizebytes",
    (TO_TIMESTAMP(_clsc_2.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS "creationtimestamp",
    (_clsc_3.attr_value::jsonb) AS "deprecated",
    (_clsc_4.attr_value #>> '{}') AS "description",
    (_clsc_5.attr_value #>> '{}')::bigint AS "disksizegb",
    (_clsc_6.attr_value #>> '{}') AS "family",
    (_clsc_7.attr_value::jsonb) AS "guestosfeatures",
    (_clsc_8.attr_value #>> '{}')::bigint AS "id",
    (_clsc_9.attr_value::jsonb) AS "imageencryptionkey",
    (_clsc_11.attr_value #>> '{}') AS "kind",
    (_clsc_12.attr_value #>> '{}') AS "labelfingerprint",
    (_clsc_13.attr_value::jsonb) AS "labels",
    (_clsc_14.attr_value::jsonb) AS "licensecodes",
    (_clsc_15.attr_value::jsonb) AS "licenses",
    (_clsc_16.attr_value #>> '{}') AS "name",
    (_clsc_17.attr_value::jsonb) AS "rawdisk",
    (_clsc_18.attr_value #>> '{}') AS "selflink",
    (_clsc_19.attr_value #>> '{}') AS "sourcedisk",
    (_clsc_20.attr_value::jsonb) AS "sourcediskencryptionkey",
    (_clsc_21.attr_value #>> '{}') AS "sourcediskid",
    (_clsc_22.attr_value #>> '{}') AS "sourceimage",
    (_clsc_23.attr_value::jsonb) AS "sourceimageencryptionkey",
    (_clsc_24.attr_value #>> '{}') AS "sourceimageid",
    (_clsc_25.attr_value #>> '{}') AS "sourcesnapshot",
    (_clsc_26.attr_value::jsonb) AS "sourcesnapshotencryptionkey",
    (_clsc_27.attr_value #>> '{}') AS "sourcesnapshotid",
    (_clsc_28.attr_value #>> '{}') AS "sourcetype",
    (_clsc_29.attr_value #>> '{}') AS "status",
    (_clsc_30.attr_value::jsonb) AS "storagelocations"
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
        AND _clsc_1.attr_name = 'archivesizebytes'
    LEFT JOIN cte_resourceattrs AS _clsc_2 ON _clsc_2.uri = _key.uri
        AND _clsc_2.resource_id = _key.resource_id
        AND _clsc_2.id = _key.id
        AND _clsc_2.attr_name = 'creationtimestamp'
    LEFT JOIN cte_resourceattrs AS _clsc_3 ON _clsc_3.uri = _key.uri
        AND _clsc_3.resource_id = _key.resource_id
        AND _clsc_3.id = _key.id
        AND _clsc_3.attr_name = 'deprecated'
    LEFT JOIN cte_resourceattrs AS _clsc_4 ON _clsc_4.uri = _key.uri
        AND _clsc_4.resource_id = _key.resource_id
        AND _clsc_4.id = _key.id
        AND _clsc_4.attr_name = 'description'
    LEFT JOIN cte_resourceattrs AS _clsc_5 ON _clsc_5.uri = _key.uri
        AND _clsc_5.resource_id = _key.resource_id
        AND _clsc_5.id = _key.id
        AND _clsc_5.attr_name = 'disksizegb'
    LEFT JOIN cte_resourceattrs AS _clsc_6 ON _clsc_6.uri = _key.uri
        AND _clsc_6.resource_id = _key.resource_id
        AND _clsc_6.id = _key.id
        AND _clsc_6.attr_name = 'family'
    LEFT JOIN cte_resourceattrs AS _clsc_7 ON _clsc_7.uri = _key.uri
        AND _clsc_7.resource_id = _key.resource_id
        AND _clsc_7.id = _key.id
        AND _clsc_7.attr_name = 'guestosfeatures'
    LEFT JOIN cte_resourceattrs AS _clsc_8 ON _clsc_8.uri = _key.uri
        AND _clsc_8.resource_id = _key.resource_id
        AND _clsc_8.id = _key.id
        AND _clsc_8.attr_name = 'id'
    LEFT JOIN cte_resourceattrs AS _clsc_9 ON _clsc_9.uri = _key.uri
        AND _clsc_9.resource_id = _key.resource_id
        AND _clsc_9.id = _key.id
        AND _clsc_9.attr_name = 'imageencryptionkey'
    LEFT JOIN cte_resourceattrs AS _clsc_10 ON _clsc_10.uri = _key.uri
        AND _clsc_10.resource_id = _key.resource_id
        AND _clsc_10.id = _key.id
        AND _clsc_10.attr_name = 'isthirdparty'
    LEFT JOIN cte_resourceattrs AS _clsc_11 ON _clsc_11.uri = _key.uri
        AND _clsc_11.resource_id = _key.resource_id
        AND _clsc_11.id = _key.id
        AND _clsc_11.attr_name = 'kind'
    LEFT JOIN cte_resourceattrs AS _clsc_12 ON _clsc_12.uri = _key.uri
        AND _clsc_12.resource_id = _key.resource_id
        AND _clsc_12.id = _key.id
        AND _clsc_12.attr_name = 'labelfingerprint'
    LEFT JOIN cte_resourceattrs AS _clsc_13 ON _clsc_13.uri = _key.uri
        AND _clsc_13.resource_id = _key.resource_id
        AND _clsc_13.id = _key.id
        AND _clsc_13.attr_name = 'labels'
    LEFT JOIN cte_resourceattrs AS _clsc_14 ON _clsc_14.uri = _key.uri
        AND _clsc_14.resource_id = _key.resource_id
        AND _clsc_14.id = _key.id
        AND _clsc_14.attr_name = 'licensecodes'
    LEFT JOIN cte_resourceattrs AS _clsc_15 ON _clsc_15.uri = _key.uri
        AND _clsc_15.resource_id = _key.resource_id
        AND _clsc_15.id = _key.id
        AND _clsc_15.attr_name = 'licenses'
    LEFT JOIN cte_resourceattrs AS _clsc_16 ON _clsc_16.uri = _key.uri
        AND _clsc_16.resource_id = _key.resource_id
        AND _clsc_16.id = _key.id
        AND _clsc_16.attr_name = 'name'
    LEFT JOIN cte_resourceattrs AS _clsc_17 ON _clsc_17.uri = _key.uri
        AND _clsc_17.resource_id = _key.resource_id
        AND _clsc_17.id = _key.id
        AND _clsc_17.attr_name = 'rawdisk'
    LEFT JOIN cte_resourceattrs AS _clsc_18 ON _clsc_18.uri = _key.uri
        AND _clsc_18.resource_id = _key.resource_id
        AND _clsc_18.id = _key.id
        AND _clsc_18.attr_name = 'selflink'
    LEFT JOIN cte_resourceattrs AS _clsc_19 ON _clsc_19.uri = _key.uri
        AND _clsc_19.resource_id = _key.resource_id
        AND _clsc_19.id = _key.id
        AND _clsc_19.attr_name = 'sourcedisk'
    LEFT JOIN cte_resourceattrs AS _clsc_20 ON _clsc_20.uri = _key.uri
        AND _clsc_20.resource_id = _key.resource_id
        AND _clsc_20.id = _key.id
        AND _clsc_20.attr_name = 'sourcediskencryptionkey'
    LEFT JOIN cte_resourceattrs AS _clsc_21 ON _clsc_21.uri = _key.uri
        AND _clsc_21.resource_id = _key.resource_id
        AND _clsc_21.id = _key.id
        AND _clsc_21.attr_name = 'sourcediskid'
    LEFT JOIN cte_resourceattrs AS _clsc_22 ON _clsc_22.uri = _key.uri
        AND _clsc_22.resource_id = _key.resource_id
        AND _clsc_22.id = _key.id
        AND _clsc_22.attr_name = 'sourceimage'
    LEFT JOIN cte_resourceattrs AS _clsc_23 ON _clsc_23.uri = _key.uri
        AND _clsc_23.resource_id = _key.resource_id
        AND _clsc_23.id = _key.id
        AND _clsc_23.attr_name = 'sourceimageencryptionkey'
    LEFT JOIN cte_resourceattrs AS _clsc_24 ON _clsc_24.uri = _key.uri
        AND _clsc_24.resource_id = _key.resource_id
        AND _clsc_24.id = _key.id
        AND _clsc_24.attr_name = 'sourceimageid'
    LEFT JOIN cte_resourceattrs AS _clsc_25 ON _clsc_25.uri = _key.uri
        AND _clsc_25.resource_id = _key.resource_id
        AND _clsc_25.id = _key.id
        AND _clsc_25.attr_name = 'sourcesnapshot'
    LEFT JOIN cte_resourceattrs AS _clsc_26 ON _clsc_26.uri = _key.uri
        AND _clsc_26.resource_id = _key.resource_id
        AND _clsc_26.id = _key.id
        AND _clsc_26.attr_name = 'sourcesnapshotencryptionkey'
    LEFT JOIN cte_resourceattrs AS _clsc_27 ON _clsc_27.uri = _key.uri
        AND _clsc_27.resource_id = _key.resource_id
        AND _clsc_27.id = _key.id
        AND _clsc_27.attr_name = 'sourcesnapshotid'
    LEFT JOIN cte_resourceattrs AS _clsc_28 ON _clsc_28.uri = _key.uri
        AND _clsc_28.resource_id = _key.resource_id
        AND _clsc_28.id = _key.id
        AND _clsc_28.attr_name = 'sourcetype'
    LEFT JOIN cte_resourceattrs AS _clsc_29 ON _clsc_29.uri = _key.uri
        AND _clsc_29.resource_id = _key.resource_id
        AND _clsc_29.id = _key.id
        AND _clsc_29.attr_name = 'status'
    LEFT JOIN cte_resourceattrs AS _clsc_30 ON _clsc_30.uri = _key.uri
        AND _clsc_30.resource_id = _key.resource_id
        AND _clsc_30.id = _key.id
        AND _clsc_30.attr_name = 'storagelocations'
    LEFT JOIN cte_resourceattrs AS _clsc_31 ON _clsc_31.uri = _key.uri
        AND _clsc_31.resource_id = _key.resource_id
        AND _clsc_31.id = _key.id
        AND _clsc_31.attr_name = 'tags' WITH NO DATA;

REFRESH MATERIALIZED VIEW gcp_compute_image;

COMMENT ON MATERIALIZED VIEW gcp_compute_image IS 'GCP compute images and their associated attributes.'
