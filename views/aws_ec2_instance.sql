DROP MATERIALIZED VIEW IF EXISTS aws_ec2_instance CASCADE;

CREATE MATERIALIZED VIEW aws_ec2_instance AS
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
        resource.provider_type = 'Instance'
        AND provider_account.provider = 'aws'
        AND resource_attribute.type = 'provider'
)
SELECT DISTINCT
    _key.resource_id,
    _key.uri,
    _key.provider_account_id,
    (_clsc_1.attr_value::integer) AS "amilaunchindex",
    (_clsc_2.attr_value #>> '{}') AS "architecture",
    (_clsc_3.attr_value #>> '{}') AS "capacityreservationid",
    (_clsc_4.attr_value::jsonb) AS "capacityreservationspecification",
    (_clsc_5.attr_value #>> '{}') AS "clienttoken",
    (_clsc_6.attr_value::jsonb) AS "cpuoptions",
    (_clsc_7.attr_value::boolean) AS "ebsoptimized",
    (_clsc_8.attr_value::boolean) AS "enasupport",
    (_clsc_9.attr_value::jsonb) AS "hibernationoptions",
    (_clsc_10.attr_value #>> '{}') AS "hypervisor",
    (_clsc_11.attr_value::jsonb) AS "iaminstanceprofile",
    (_clsc_12.attr_value #>> '{}') AS "imageid",
    (_clsc_13.attr_value #>> '{}') AS "instanceid",
    (_clsc_14.attr_value #>> '{}') AS "instancelifecycle",
    (_clsc_15.attr_value #>> '{}') AS "instancetype",
    (_clsc_16.attr_value #>> '{}') AS "kernelid",
    (_clsc_17.attr_value #>> '{}') AS "keyname",
    (TO_TIMESTAMP(_clsc_18.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS "launchtime",
    (_clsc_19.attr_value::jsonb) AS "licenses",
    (_clsc_20.attr_value::jsonb) AS "metadataoptionszone",
    (_clsc_21.attr_value::jsonb) AS "monitoring",
    (_clsc_22.attr_value #>> '{}') AS "outpostarn",
    (_clsc_23.attr_value::jsonb) AS "placement",
    (_clsc_24.attr_value #>> '{}') AS "platform",
    (_clsc_25.attr_value #>> '{}') AS "privatednsname",
    ((_clsc_26.attr_value #>> '{}')::inet) AS "privateipaddress",
    (_clsc_27.attr_value::jsonb) AS "productcodes",
    (_clsc_28.attr_value #>> '{}') AS "publicdnsname",
    ((_clsc_29.attr_value #>> '{}')::inet) AS "publicipaddress",
    (_clsc_30.attr_value #>> '{}') AS "ramdiskid",
    (_clsc_31.attr_value #>> '{}') AS "region",
    (_clsc_32.attr_value #>> '{}') AS "rootdevicename",
    (_clsc_33.attr_value #>> '{}') AS "rootdevicetype",
    (_clsc_34.attr_value::boolean) AS "sourcedestcheck",
    (_clsc_35.attr_value #>> '{}') AS "spotinstancerequestid",
    (_clsc_36.attr_value #>> '{}') AS "sriovnetsupport",
    (_clsc_37.attr_value::jsonb) AS "state",
    (_clsc_38.attr_value::jsonb) AS "statereason",
    (_clsc_39.attr_value::jsonb) AS "statetransitionreason",
    (_clsc_40.attr_value #>> '{}') AS "subnetid",
    (_clsc_41.attr_value::jsonb) AS "tags",
    (_clsc_42.attr_value #>> '{}') AS "virtualizationtype",
    (_clsc_43.attr_value #>> '{}') AS "vpcid"
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
        AND _clsc_1.attr_name = 'amilaunchindex'
    LEFT JOIN cte_resourceattrs AS _clsc_2 ON _clsc_2.uri = _key.uri
        AND _clsc_2.resource_id = _key.resource_id
        AND _clsc_2.id = _key.id
        AND _clsc_2.attr_name = 'architecture'
    LEFT JOIN cte_resourceattrs AS _clsc_3 ON _clsc_3.uri = _key.uri
        AND _clsc_3.resource_id = _key.resource_id
        AND _clsc_3.id = _key.id
        AND _clsc_3.attr_name = 'capacityreservationid'
    LEFT JOIN cte_resourceattrs AS _clsc_4 ON _clsc_4.uri = _key.uri
        AND _clsc_4.resource_id = _key.resource_id
        AND _clsc_4.id = _key.id
        AND _clsc_4.attr_name = 'capacityreservationspecification'
    LEFT JOIN cte_resourceattrs AS _clsc_5 ON _clsc_5.uri = _key.uri
        AND _clsc_5.resource_id = _key.resource_id
        AND _clsc_5.id = _key.id
        AND _clsc_5.attr_name = 'clienttoken'
    LEFT JOIN cte_resourceattrs AS _clsc_6 ON _clsc_6.uri = _key.uri
        AND _clsc_6.resource_id = _key.resource_id
        AND _clsc_6.id = _key.id
        AND _clsc_6.attr_name = 'cpuoptions'
    LEFT JOIN cte_resourceattrs AS _clsc_7 ON _clsc_7.uri = _key.uri
        AND _clsc_7.resource_id = _key.resource_id
        AND _clsc_7.id = _key.id
        AND _clsc_7.attr_name = 'ebsoptimized'
    LEFT JOIN cte_resourceattrs AS _clsc_8 ON _clsc_8.uri = _key.uri
        AND _clsc_8.resource_id = _key.resource_id
        AND _clsc_8.id = _key.id
        AND _clsc_8.attr_name = 'enasupport'
    LEFT JOIN cte_resourceattrs AS _clsc_9 ON _clsc_9.uri = _key.uri
        AND _clsc_9.resource_id = _key.resource_id
        AND _clsc_9.id = _key.id
        AND _clsc_9.attr_name = 'hibernationoptions'
    LEFT JOIN cte_resourceattrs AS _clsc_10 ON _clsc_10.uri = _key.uri
        AND _clsc_10.resource_id = _key.resource_id
        AND _clsc_10.id = _key.id
        AND _clsc_10.attr_name = 'hypervisor'
    LEFT JOIN cte_resourceattrs AS _clsc_11 ON _clsc_11.uri = _key.uri
        AND _clsc_11.resource_id = _key.resource_id
        AND _clsc_11.id = _key.id
        AND _clsc_11.attr_name = 'iaminstanceprofile'
    LEFT JOIN cte_resourceattrs AS _clsc_12 ON _clsc_12.uri = _key.uri
        AND _clsc_12.resource_id = _key.resource_id
        AND _clsc_12.id = _key.id
        AND _clsc_12.attr_name = 'imageid'
    LEFT JOIN cte_resourceattrs AS _clsc_13 ON _clsc_13.uri = _key.uri
        AND _clsc_13.resource_id = _key.resource_id
        AND _clsc_13.id = _key.id
        AND _clsc_13.attr_name = 'instanceid'
    LEFT JOIN cte_resourceattrs AS _clsc_14 ON _clsc_14.uri = _key.uri
        AND _clsc_14.resource_id = _key.resource_id
        AND _clsc_14.id = _key.id
        AND _clsc_14.attr_name = 'instancelifecycle'
    LEFT JOIN cte_resourceattrs AS _clsc_15 ON _clsc_15.uri = _key.uri
        AND _clsc_15.resource_id = _key.resource_id
        AND _clsc_15.id = _key.id
        AND _clsc_15.attr_name = 'instancetype'
    LEFT JOIN cte_resourceattrs AS _clsc_16 ON _clsc_16.uri = _key.uri
        AND _clsc_16.resource_id = _key.resource_id
        AND _clsc_16.id = _key.id
        AND _clsc_16.attr_name = 'kernelid'
    LEFT JOIN cte_resourceattrs AS _clsc_17 ON _clsc_17.uri = _key.uri
        AND _clsc_17.resource_id = _key.resource_id
        AND _clsc_17.id = _key.id
        AND _clsc_17.attr_name = 'keyname'
    LEFT JOIN cte_resourceattrs AS _clsc_18 ON _clsc_18.uri = _key.uri
        AND _clsc_18.resource_id = _key.resource_id
        AND _clsc_18.id = _key.id
        AND _clsc_18.attr_name = 'launchtime'
    LEFT JOIN cte_resourceattrs AS _clsc_19 ON _clsc_19.uri = _key.uri
        AND _clsc_19.resource_id = _key.resource_id
        AND _clsc_19.id = _key.id
        AND _clsc_19.attr_name = 'licenses'
    LEFT JOIN cte_resourceattrs AS _clsc_20 ON _clsc_20.uri = _key.uri
        AND _clsc_20.resource_id = _key.resource_id
        AND _clsc_20.id = _key.id
        AND _clsc_20.attr_name = 'metadataoptionszone'
    LEFT JOIN cte_resourceattrs AS _clsc_21 ON _clsc_21.uri = _key.uri
        AND _clsc_21.resource_id = _key.resource_id
        AND _clsc_21.id = _key.id
        AND _clsc_21.attr_name = 'monitoring'
    LEFT JOIN cte_resourceattrs AS _clsc_22 ON _clsc_22.uri = _key.uri
        AND _clsc_22.resource_id = _key.resource_id
        AND _clsc_22.id = _key.id
        AND _clsc_22.attr_name = 'outpostarn'
    LEFT JOIN cte_resourceattrs AS _clsc_23 ON _clsc_23.uri = _key.uri
        AND _clsc_23.resource_id = _key.resource_id
        AND _clsc_23.id = _key.id
        AND _clsc_23.attr_name = 'placement'
    LEFT JOIN cte_resourceattrs AS _clsc_24 ON _clsc_24.uri = _key.uri
        AND _clsc_24.resource_id = _key.resource_id
        AND _clsc_24.id = _key.id
        AND _clsc_24.attr_name = 'platform'
    LEFT JOIN cte_resourceattrs AS _clsc_25 ON _clsc_25.uri = _key.uri
        AND _clsc_25.resource_id = _key.resource_id
        AND _clsc_25.id = _key.id
        AND _clsc_25.attr_name = 'privatednsname'
    LEFT JOIN cte_resourceattrs AS _clsc_26 ON _clsc_26.uri = _key.uri
        AND _clsc_26.resource_id = _key.resource_id
        AND _clsc_26.id = _key.id
        AND _clsc_26.attr_name = 'privateipaddress'
    LEFT JOIN cte_resourceattrs AS _clsc_27 ON _clsc_27.uri = _key.uri
        AND _clsc_27.resource_id = _key.resource_id
        AND _clsc_27.id = _key.id
        AND _clsc_27.attr_name = 'productcodes'
    LEFT JOIN cte_resourceattrs AS _clsc_28 ON _clsc_28.uri = _key.uri
        AND _clsc_28.resource_id = _key.resource_id
        AND _clsc_28.id = _key.id
        AND _clsc_28.attr_name = 'publicdnsname'
    LEFT JOIN cte_resourceattrs AS _clsc_29 ON _clsc_29.uri = _key.uri
        AND _clsc_29.resource_id = _key.resource_id
        AND _clsc_29.id = _key.id
        AND _clsc_29.attr_name = 'publicipaddress'
    LEFT JOIN cte_resourceattrs AS _clsc_30 ON _clsc_30.uri = _key.uri
        AND _clsc_30.resource_id = _key.resource_id
        AND _clsc_30.id = _key.id
        AND _clsc_30.attr_name = 'ramdiskid'
    LEFT JOIN cte_resourceattrs AS _clsc_31 ON _clsc_31.uri = _key.uri
        AND _clsc_31.resource_id = _key.resource_id
        AND _clsc_31.id = _key.id
        AND _clsc_31.attr_name = 'region'
    LEFT JOIN cte_resourceattrs AS _clsc_32 ON _clsc_32.uri = _key.uri
        AND _clsc_32.resource_id = _key.resource_id
        AND _clsc_32.id = _key.id
        AND _clsc_32.attr_name = 'rootdevicename'
    LEFT JOIN cte_resourceattrs AS _clsc_33 ON _clsc_33.uri = _key.uri
        AND _clsc_33.resource_id = _key.resource_id
        AND _clsc_33.id = _key.id
        AND _clsc_33.attr_name = 'rootdevicetype'
    LEFT JOIN cte_resourceattrs AS _clsc_34 ON _clsc_34.uri = _key.uri
        AND _clsc_34.resource_id = _key.resource_id
        AND _clsc_34.id = _key.id
        AND _clsc_34.attr_name = 'sourcedestcheck'
    LEFT JOIN cte_resourceattrs AS _clsc_35 ON _clsc_35.uri = _key.uri
        AND _clsc_35.resource_id = _key.resource_id
        AND _clsc_35.id = _key.id
        AND _clsc_35.attr_name = 'spotinstancerequestid'
    LEFT JOIN cte_resourceattrs AS _clsc_36 ON _clsc_36.uri = _key.uri
        AND _clsc_36.resource_id = _key.resource_id
        AND _clsc_36.id = _key.id
        AND _clsc_36.attr_name = 'sriovnetsupport'
    LEFT JOIN cte_resourceattrs AS _clsc_37 ON _clsc_37.uri = _key.uri
        AND _clsc_37.resource_id = _key.resource_id
        AND _clsc_37.id = _key.id
        AND _clsc_37.attr_name = 'state'
    LEFT JOIN cte_resourceattrs AS _clsc_38 ON _clsc_38.uri = _key.uri
        AND _clsc_38.resource_id = _key.resource_id
        AND _clsc_38.id = _key.id
        AND _clsc_38.attr_name = 'statereason'
    LEFT JOIN cte_resourceattrs AS _clsc_39 ON _clsc_39.uri = _key.uri
        AND _clsc_39.resource_id = _key.resource_id
        AND _clsc_39.id = _key.id
        AND _clsc_39.attr_name = 'statetransitionreason'
    LEFT JOIN cte_resourceattrs AS _clsc_40 ON _clsc_40.uri = _key.uri
        AND _clsc_40.resource_id = _key.resource_id
        AND _clsc_40.id = _key.id
        AND _clsc_40.attr_name = 'subnetid'
    LEFT JOIN cte_resourceattrs AS _clsc_41 ON _clsc_41.uri = _key.uri
        AND _clsc_41.resource_id = _key.resource_id
        AND _clsc_41.id = _key.id
        AND _clsc_41.attr_name = 'tags'
    LEFT JOIN cte_resourceattrs AS _clsc_42 ON _clsc_42.uri = _key.uri
        AND _clsc_42.resource_id = _key.resource_id
        AND _clsc_42.id = _key.id
        AND _clsc_42.attr_name = 'virtualizationtype'
    LEFT JOIN cte_resourceattrs AS _clsc_43 ON _clsc_43.uri = _key.uri
        AND _clsc_43.resource_id = _key.resource_id
        AND _clsc_43.id = _key.id
        AND _clsc_43.attr_name = 'vpcid' WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_ec2_instance;

COMMENT ON MATERIALIZED VIEW aws_ec2_instance IS 'AWS EC2 instances and their associated attributes.'
