DROP MATERIALIZED VIEW IF EXISTS gcp_relation_compute_instance_acts_as CASCADE;

CREATE MATERIALIZED VIEW gcp_relation_compute_instance_acts_as AS
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
        resource_relation.relation = 'acts-as'
        AND resource.provider_type = 'instance'
        AND resource.service = 'compute'
        AND provider_account.provider = 'gcp'
)
SELECT DISTINCT
    cte_resourceattrs.resource_id,
    cte_resourceattrs.target_id,
    (_clsc_1.value::jsonb) AS "scopes"
FROM
    cte_resourceattrs
    LEFT JOIN cte_resourceattrs AS _clsc_1 ON _clsc_1.uri = cte_resourceattrs.uri
        AND _clsc_1.resource_id = cte_resourceattrs.resource_id
        AND _clsc_1.name = 'scopes' WITH NO data;

REFRESH MATERIALIZED VIEW gcp_relation_compute_instance_acts_as;

COMMENT ON MATERIALIZED VIEW gcp_relation_compute_instance_acts_as IS 'GCP compute instance acts-as relationships.'
