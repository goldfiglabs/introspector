DROP MATERIALIZED VIEW IF EXISTS gcp_compute_instance_networks CASCADE;

CREATE MATERIALIZED VIEW gcp_compute_instance_networks AS SELECT DISTINCT
    gcp_compute_instance.resource_id,
    gcp_compute_instance.uri,
    gcp_compute_instance.provider_account_id,
    gcp_compute_instance_networkinterface.name,
    subnetwork,
    networkip,
    natip
FROM
    gcp_compute_instance
    INNER JOIN gcp_compute_instance_networkinterface USING (resource_id)
    INNER JOIN gcp_compute_instance_networkinterface_accessconfig USING (resource_id
)
    WITH NO DATA;

REFRESH MATERIALIZED VIEW gcp_compute_instance_networks;

COMMENT ON MATERIALIZED VIEW gcp_compute_instance_networks IS 'GCP compute network interface and config view for NICs and IP addresses.'
