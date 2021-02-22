INSERT INTO aws_cloudfront_distribution (
  _id,
  uri,
  provider_account_id,
  id,
  arn,
  status,
  lastmodifiedtime,
  inprogressinvalidationbatches,
  domainname,
  activetrustedsigners,
  activetrustedkeygroups,
  aliasicprecordals,
  tags,
  callerreference,
  aliases,
  defaultrootobject,
  origins,
  origingroups,
  defaultcachebehavior,
  cachebehaviors,
  customerrorresponses,
  comment,
  logging,
  priceclass,
  enabled,
  viewercertificate,
  restrictions,
  webaclid,
  httpversion,
  isipv6enabled,
  _tags,
  _account_id
)
SELECT
  R.id AS _id,
  R.uri,
  R.provider_account_id,
  id.attr_value #>> '{}' AS id,
  arn.attr_value #>> '{}' AS arn,
  status.attr_value #>> '{}' AS status,
  (TO_TIMESTAMP(lastmodifiedtime.attr_value #>> '{}', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS lastmodifiedtime,
  (inprogressinvalidationbatches.attr_value #>> '{}')::integer AS inprogressinvalidationbatches,
  domainname.attr_value #>> '{}' AS domainname,
  activetrustedsigners.attr_value::jsonb AS activetrustedsigners,
  activetrustedkeygroups.attr_value::jsonb AS activetrustedkeygroups,
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
  _tags.attr_value::jsonb AS _tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  INNER JOIN provider_account AS PA
    ON PA.id = R.provider_account_id
  LEFT JOIN resource_attribute AS id
    ON id.resource_id = R.id
    AND id.type = 'provider'
    AND lower(id.attr_name) = 'id'
  LEFT JOIN resource_attribute AS arn
    ON arn.resource_id = R.id
    AND arn.type = 'provider'
    AND lower(arn.attr_name) = 'arn'
  LEFT JOIN resource_attribute AS status
    ON status.resource_id = R.id
    AND status.type = 'provider'
    AND lower(status.attr_name) = 'status'
  LEFT JOIN resource_attribute AS lastmodifiedtime
    ON lastmodifiedtime.resource_id = R.id
    AND lastmodifiedtime.type = 'provider'
    AND lower(lastmodifiedtime.attr_name) = 'lastmodifiedtime'
  LEFT JOIN resource_attribute AS inprogressinvalidationbatches
    ON inprogressinvalidationbatches.resource_id = R.id
    AND inprogressinvalidationbatches.type = 'provider'
    AND lower(inprogressinvalidationbatches.attr_name) = 'inprogressinvalidationbatches'
  LEFT JOIN resource_attribute AS domainname
    ON domainname.resource_id = R.id
    AND domainname.type = 'provider'
    AND lower(domainname.attr_name) = 'domainname'
  LEFT JOIN resource_attribute AS activetrustedsigners
    ON activetrustedsigners.resource_id = R.id
    AND activetrustedsigners.type = 'provider'
    AND lower(activetrustedsigners.attr_name) = 'activetrustedsigners'
  LEFT JOIN resource_attribute AS activetrustedkeygroups
    ON activetrustedkeygroups.resource_id = R.id
    AND activetrustedkeygroups.type = 'provider'
    AND lower(activetrustedkeygroups.attr_name) = 'activetrustedkeygroups'
  LEFT JOIN resource_attribute AS aliasicprecordals
    ON aliasicprecordals.resource_id = R.id
    AND aliasicprecordals.type = 'provider'
    AND lower(aliasicprecordals.attr_name) = 'aliasicprecordals'
  LEFT JOIN resource_attribute AS tags
    ON tags.resource_id = R.id
    AND tags.type = 'provider'
    AND lower(tags.attr_name) = 'tags'
  LEFT JOIN resource_attribute AS callerreference
    ON callerreference.resource_id = R.id
    AND callerreference.type = 'provider'
    AND lower(callerreference.attr_name) = 'callerreference'
  LEFT JOIN resource_attribute AS aliases
    ON aliases.resource_id = R.id
    AND aliases.type = 'provider'
    AND lower(aliases.attr_name) = 'aliases'
  LEFT JOIN resource_attribute AS defaultrootobject
    ON defaultrootobject.resource_id = R.id
    AND defaultrootobject.type = 'provider'
    AND lower(defaultrootobject.attr_name) = 'defaultrootobject'
  LEFT JOIN resource_attribute AS origins
    ON origins.resource_id = R.id
    AND origins.type = 'provider'
    AND lower(origins.attr_name) = 'origins'
  LEFT JOIN resource_attribute AS origingroups
    ON origingroups.resource_id = R.id
    AND origingroups.type = 'provider'
    AND lower(origingroups.attr_name) = 'origingroups'
  LEFT JOIN resource_attribute AS defaultcachebehavior
    ON defaultcachebehavior.resource_id = R.id
    AND defaultcachebehavior.type = 'provider'
    AND lower(defaultcachebehavior.attr_name) = 'defaultcachebehavior'
  LEFT JOIN resource_attribute AS cachebehaviors
    ON cachebehaviors.resource_id = R.id
    AND cachebehaviors.type = 'provider'
    AND lower(cachebehaviors.attr_name) = 'cachebehaviors'
  LEFT JOIN resource_attribute AS customerrorresponses
    ON customerrorresponses.resource_id = R.id
    AND customerrorresponses.type = 'provider'
    AND lower(customerrorresponses.attr_name) = 'customerrorresponses'
  LEFT JOIN resource_attribute AS comment
    ON comment.resource_id = R.id
    AND comment.type = 'provider'
    AND lower(comment.attr_name) = 'comment'
  LEFT JOIN resource_attribute AS logging
    ON logging.resource_id = R.id
    AND logging.type = 'provider'
    AND lower(logging.attr_name) = 'logging'
  LEFT JOIN resource_attribute AS priceclass
    ON priceclass.resource_id = R.id
    AND priceclass.type = 'provider'
    AND lower(priceclass.attr_name) = 'priceclass'
  LEFT JOIN resource_attribute AS enabled
    ON enabled.resource_id = R.id
    AND enabled.type = 'provider'
    AND lower(enabled.attr_name) = 'enabled'
  LEFT JOIN resource_attribute AS viewercertificate
    ON viewercertificate.resource_id = R.id
    AND viewercertificate.type = 'provider'
    AND lower(viewercertificate.attr_name) = 'viewercertificate'
  LEFT JOIN resource_attribute AS restrictions
    ON restrictions.resource_id = R.id
    AND restrictions.type = 'provider'
    AND lower(restrictions.attr_name) = 'restrictions'
  LEFT JOIN resource_attribute AS webaclid
    ON webaclid.resource_id = R.id
    AND webaclid.type = 'provider'
    AND lower(webaclid.attr_name) = 'webaclid'
  LEFT JOIN resource_attribute AS httpversion
    ON httpversion.resource_id = R.id
    AND httpversion.type = 'provider'
    AND lower(httpversion.attr_name) = 'httpversion'
  LEFT JOIN resource_attribute AS isipv6enabled
    ON isipv6enabled.resource_id = R.id
    AND isipv6enabled.type = 'provider'
    AND lower(isipv6enabled.attr_name) = 'isipv6enabled'
  LEFT JOIN resource_attribute AS _tags
    ON _tags.resource_id = R.id
    AND _tags.type = 'Metadata'
    AND lower(_tags.attr_name) = '_tags'
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
  AND R.provider_type = 'Distribution'
  AND R.service = 'cloudfront'
ON CONFLICT (_id) DO UPDATE
SET
    id = EXCLUDED.id,
    arn = EXCLUDED.arn,
    status = EXCLUDED.status,
    lastmodifiedtime = EXCLUDED.lastmodifiedtime,
    inprogressinvalidationbatches = EXCLUDED.inprogressinvalidationbatches,
    domainname = EXCLUDED.domainname,
    activetrustedsigners = EXCLUDED.activetrustedsigners,
    activetrustedkeygroups = EXCLUDED.activetrustedkeygroups,
    aliasicprecordals = EXCLUDED.aliasicprecordals,
    tags = EXCLUDED.tags,
    callerreference = EXCLUDED.callerreference,
    aliases = EXCLUDED.aliases,
    defaultrootobject = EXCLUDED.defaultrootobject,
    origins = EXCLUDED.origins,
    origingroups = EXCLUDED.origingroups,
    defaultcachebehavior = EXCLUDED.defaultcachebehavior,
    cachebehaviors = EXCLUDED.cachebehaviors,
    customerrorresponses = EXCLUDED.customerrorresponses,
    comment = EXCLUDED.comment,
    logging = EXCLUDED.logging,
    priceclass = EXCLUDED.priceclass,
    enabled = EXCLUDED.enabled,
    viewercertificate = EXCLUDED.viewercertificate,
    restrictions = EXCLUDED.restrictions,
    webaclid = EXCLUDED.webaclid,
    httpversion = EXCLUDED.httpversion,
    isipv6enabled = EXCLUDED.isipv6enabled,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;

