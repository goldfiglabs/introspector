DROP MATERIALIZED VIEW IF EXISTS aws_cloudfront_distribution CASCADE;

CREATE MATERIALIZED VIEW aws_cloudfront_distribution AS
WITH attrs AS (
  SELECT
    R.id,
    LOWER(RA.attr_name) AS attr_name,
    RA.attr_value
  FROM
    resource AS R
    INNER JOIN resource_attribute AS RA
      ON RA.resource_id = R.id
  WHERE
    RA.type = 'provider'
)
SELECT
  R.id AS resource_id,
  R.uri,
  R.provider_account_id,
  id.attr_value #>> '{}' AS id,
  arn.attr_value #>> '{}' AS arn,
  status.attr_value #>> '{}' AS status,
  (TO_TIMESTAMP(lastmodifiedtime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS lastmodifiedtime,
  (inprogressinvalidationbatches.attr_value #>> '{}')::integer AS inprogressinvalidationbatches,
  domainname.attr_value #>> '{}' AS domainname,
  activetrustedsigners.attr_value::jsonb AS activetrustedsigners,
  aliasicprecordals.attr_value::jsonb AS aliasicprecordals,
  tags.attr_value::jsonb AS tags,
  callerreference.attr_value #>> '{}' AS callerreference,
  aliases.attr_value::jsonb AS aliases,
  defaultrootobject.attr_value #>> '{}' AS defaultrootobject,
  origins.attr_value::jsonb AS origins,
  origingroups.attr_value::jsonb AS origingroups,
  defaultcachebehavior.attr_value::jsonb AS defaultcachebehavior,
  cachebehaviors.attr_value::jsonb AS cachebehaviors,
  customerrorresponses.attr_value::jsonb AS customerrorresponses,
  comment.attr_value #>> '{}' AS comment,
  logging.attr_value::jsonb AS logging,
  priceclass.attr_value #>> '{}' AS priceclass,
  (enabled.attr_value #>> '{}')::boolean AS enabled,
  viewercertificate.attr_value::jsonb AS viewercertificate,
  restrictions.attr_value::jsonb AS restrictions,
  webaclid.attr_value #>> '{}' AS webaclid,
  httpversion.attr_value #>> '{}' AS httpversion,
  (isipv6enabled.attr_value #>> '{}')::boolean AS isipv6enabled,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN attrs AS id
    ON id.id = R.id
    AND id.attr_name = 'id'
  LEFT JOIN attrs AS arn
    ON arn.id = R.id
    AND arn.attr_name = 'arn'
  LEFT JOIN attrs AS status
    ON status.id = R.id
    AND status.attr_name = 'status'
  LEFT JOIN attrs AS lastmodifiedtime
    ON lastmodifiedtime.id = R.id
    AND lastmodifiedtime.attr_name = 'lastmodifiedtime'
  LEFT JOIN attrs AS inprogressinvalidationbatches
    ON inprogressinvalidationbatches.id = R.id
    AND inprogressinvalidationbatches.attr_name = 'inprogressinvalidationbatches'
  LEFT JOIN attrs AS domainname
    ON domainname.id = R.id
    AND domainname.attr_name = 'domainname'
  LEFT JOIN attrs AS activetrustedsigners
    ON activetrustedsigners.id = R.id
    AND activetrustedsigners.attr_name = 'activetrustedsigners'
  LEFT JOIN attrs AS aliasicprecordals
    ON aliasicprecordals.id = R.id
    AND aliasicprecordals.attr_name = 'aliasicprecordals'
  LEFT JOIN attrs AS tags
    ON tags.id = R.id
    AND tags.attr_name = 'tags'
  LEFT JOIN attrs AS callerreference
    ON callerreference.id = R.id
    AND callerreference.attr_name = 'callerreference'
  LEFT JOIN attrs AS aliases
    ON aliases.id = R.id
    AND aliases.attr_name = 'aliases'
  LEFT JOIN attrs AS defaultrootobject
    ON defaultrootobject.id = R.id
    AND defaultrootobject.attr_name = 'defaultrootobject'
  LEFT JOIN attrs AS origins
    ON origins.id = R.id
    AND origins.attr_name = 'origins'
  LEFT JOIN attrs AS origingroups
    ON origingroups.id = R.id
    AND origingroups.attr_name = 'origingroups'
  LEFT JOIN attrs AS defaultcachebehavior
    ON defaultcachebehavior.id = R.id
    AND defaultcachebehavior.attr_name = 'defaultcachebehavior'
  LEFT JOIN attrs AS cachebehaviors
    ON cachebehaviors.id = R.id
    AND cachebehaviors.attr_name = 'cachebehaviors'
  LEFT JOIN attrs AS customerrorresponses
    ON customerrorresponses.id = R.id
    AND customerrorresponses.attr_name = 'customerrorresponses'
  LEFT JOIN attrs AS comment
    ON comment.id = R.id
    AND comment.attr_name = 'comment'
  LEFT JOIN attrs AS logging
    ON logging.id = R.id
    AND logging.attr_name = 'logging'
  LEFT JOIN attrs AS priceclass
    ON priceclass.id = R.id
    AND priceclass.attr_name = 'priceclass'
  LEFT JOIN attrs AS enabled
    ON enabled.id = R.id
    AND enabled.attr_name = 'enabled'
  LEFT JOIN attrs AS viewercertificate
    ON viewercertificate.id = R.id
    AND viewercertificate.attr_name = 'viewercertificate'
  LEFT JOIN attrs AS restrictions
    ON restrictions.id = R.id
    AND restrictions.attr_name = 'restrictions'
  LEFT JOIN attrs AS webaclid
    ON webaclid.id = R.id
    AND webaclid.attr_name = 'webaclid'
  LEFT JOIN attrs AS httpversion
    ON httpversion.id = R.id
    AND httpversion.attr_name = 'httpversion'
  LEFT JOIN attrs AS isipv6enabled
    ON isipv6enabled.id = R.id
    AND isipv6enabled.attr_name = 'isipv6enabled'
  LEFT JOIN (
    SELECT
      _aws_organizations_account_relation.resource_id AS resource_id,
      _aws_organizations_account.id AS target_id
    FROM
      resource_relation AS _aws_organizations_account_relation
      INNER JOIN resource AS _aws_organizations_account
        ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
        AND _aws_organizations_account.provider_type = 'Account'
        AND _aws_organizations_account.service = 'organizations'
    WHERE
      _aws_organizations_account_relation.relation = 'in'
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  PA.provider = 'aws'
  AND LOWER(R.provider_type) = 'distribution'
WITH NO DATA;

REFRESH MATERIALIZED VIEW aws_cloudfront_distribution;

COMMENT ON MATERIALIZED VIEW aws_cloudfront_distribution IS 'cloudfront distribution resources and their associated attributes.';

