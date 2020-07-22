DROP MATERIALIZED VIEW IF EXISTS gcp_iam_serviceaccount CASCADE;

CREATE MATERIALIZED VIEW gcp_iam_serviceaccount AS
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
        resource.provider_type = 'serviceAccount'
        AND provider_account.provider = 'gcp'
        AND resource_attribute.type = 'provider'
)
SELECT DISTINCT
    _key.resource_id,
    _key.uri,
    _key.provider_account_id,
    (_clsc_1.attr_value #>> '{}') AS "displayname",
    (_clsc_2.attr_value #>> '{}') AS "email",
    (_clsc_4.attr_value #>> '{}') AS "name",
    (_clsc_5.attr_value #>> '{}') AS "oauth2clientid",
    (_clsc_6.attr_value #>> '{}') AS "projectid",
    (_clsc_9.attr_value #>> '{}') AS "uniqueid"
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
        AND _clsc_1.attr_name = 'displayname'
    LEFT JOIN cte_resourceattrs AS _clsc_2 ON _clsc_2.uri = _key.uri
        AND _clsc_2.resource_id = _key.resource_id
        AND _clsc_2.id = _key.id
        AND _clsc_2.attr_name = 'email'
    LEFT JOIN cte_resourceattrs AS _clsc_3 ON _clsc_3.uri = _key.uri
        AND _clsc_3.resource_id = _key.resource_id
        AND _clsc_3.id = _key.id
        AND _clsc_3.attr_name = 'identity'
    LEFT JOIN cte_resourceattrs AS _clsc_4 ON _clsc_4.uri = _key.uri
        AND _clsc_4.resource_id = _key.resource_id
        AND _clsc_4.id = _key.id
        AND _clsc_4.attr_name = 'name'
    LEFT JOIN cte_resourceattrs AS _clsc_5 ON _clsc_5.uri = _key.uri
        AND _clsc_5.resource_id = _key.resource_id
        AND _clsc_5.id = _key.id
        AND _clsc_5.attr_name = 'oauth2clientid'
    LEFT JOIN cte_resourceattrs AS _clsc_6 ON _clsc_6.uri = _key.uri
        AND _clsc_6.resource_id = _key.resource_id
        AND _clsc_6.id = _key.id
        AND _clsc_6.attr_name = 'projectid'
    LEFT JOIN cte_resourceattrs AS _clsc_7 ON _clsc_7.uri = _key.uri
        AND _clsc_7.resource_id = _key.resource_id
        AND _clsc_7.id = _key.id
        AND _clsc_7.attr_name = 'scoped'
    LEFT JOIN cte_resourceattrs AS _clsc_8 ON _clsc_8.uri = _key.uri
        AND _clsc_8.resource_id = _key.resource_id
        AND _clsc_8.id = _key.id
        AND _clsc_8.attr_name = 'type'
    LEFT JOIN cte_resourceattrs AS _clsc_9 ON _clsc_9.uri = _key.uri
        AND _clsc_9.resource_id = _key.resource_id
        AND _clsc_9.id = _key.id
        AND _clsc_9.attr_name = 'uniqueid' WITH NO DATA;

REFRESH MATERIALIZED VIEW gcp_iam_serviceaccount;

COMMENT ON MATERIALIZED VIEW gcp_iam_serviceaccount IS 'GCP IAM service accounts and their associated attributes.'
