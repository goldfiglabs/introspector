WITH attrs AS (
  SELECT
    resource_id,
    jsonb_object_agg(attr_name, attr_value) FILTER (WHERE type = 'provider') AS provider,
    jsonb_object_agg(attr_name, attr_value) FILTER (WHERE type = 'Metadata') AS metadata
  FROM
    resource_attribute
  WHERE
    provider_account_id = :provider_account_id
  GROUP BY resource_id
)
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
  attrs.provider ->> 'Id' AS id,
  attrs.provider ->> 'ARN' AS arn,
  attrs.provider ->> 'Status' AS status,
  (TO_TIMESTAMP(attrs.provider ->> 'LastModifiedTime', 'YYYY-MM-DD"T"HH24:MI:SS')::timestamp at time zone '00:00') AS lastmodifiedtime,
  (attrs.provider ->> 'InProgressInvalidationBatches')::integer AS inprogressinvalidationbatches,
  attrs.provider ->> 'DomainName' AS domainname,
  attrs.provider -> 'ActiveTrustedSigners' AS activetrustedsigners,
  attrs.provider -> 'ActiveTrustedKeyGroups' AS activetrustedkeygroups,
  attrs.provider -> 'AliasICPRecordals' AS aliasicprecordals,
  attrs.provider -> 'Tags' AS tags,
  attrs.provider ->> 'CallerReference' AS callerreference,
  attrs.provider -> 'Aliases' AS aliases,
  attrs.provider ->> 'DefaultRootObject' AS defaultrootobject,
  attrs.provider -> 'Origins' AS origins,
  attrs.provider -> 'OriginGroups' AS origingroups,
  attrs.provider -> 'DefaultCacheBehavior' AS defaultcachebehavior,
  attrs.provider -> 'CacheBehaviors' AS cachebehaviors,
  attrs.provider -> 'CustomErrorResponses' AS customerrorresponses,
  attrs.provider ->> 'Comment' AS comment,
  attrs.provider -> 'Logging' AS logging,
  attrs.provider ->> 'PriceClass' AS priceclass,
  (attrs.provider ->> 'Enabled')::boolean AS enabled,
  attrs.provider -> 'ViewerCertificate' AS viewercertificate,
  attrs.provider -> 'Restrictions' AS restrictions,
  attrs.provider ->> 'WebACLId' AS webaclid,
  attrs.provider ->> 'HttpVersion' AS httpversion,
  (attrs.provider ->> 'IsIPV6Enabled')::boolean AS isipv6enabled,
  attrs.metadata -> 'Tags' AS tags,
  
    _account_id.target_id AS _account_id
FROM
  resource AS R
  LEFT JOIN attrs ON
    attrs.resource_id = R.id
  LEFT JOIN (
    SELECT
      unique_account_mapping.resource_id,
      unique_account_mapping.target_ids[1] as target_id
    FROM
      (
        SELECT
          ARRAY_AGG(_aws_organizations_account_relation.target_id) AS target_ids,
          _aws_organizations_account_relation.resource_id
        FROM
          resource AS _aws_organizations_account
          INNER JOIN resource_relation AS _aws_organizations_account_relation
            ON _aws_organizations_account_relation.target_id = _aws_organizations_account.id
        WHERE
          _aws_organizations_account.provider_type = 'Account'
          AND _aws_organizations_account.service = 'organizations'
          AND _aws_organizations_account.provider_account_id = :provider_account_id
          AND _aws_organizations_account_relation.relation = 'in'
          AND _aws_organizations_account_relation.provider_account_id = 8
        GROUP BY _aws_organizations_account_relation.resource_id
        HAVING COUNT(*) = 1
      ) AS unique_account_mapping
  ) AS _account_id ON _account_id.resource_id = R.id
  WHERE
  R.provider_account_id = :provider_account_id
  AND R.provider_type = 'Distribution'
  AND R.service = 'cloudfront'
ON CONFLICT (_id) DO UPDATE
SET
    Id = EXCLUDED.Id,
    ARN = EXCLUDED.ARN,
    Status = EXCLUDED.Status,
    LastModifiedTime = EXCLUDED.LastModifiedTime,
    InProgressInvalidationBatches = EXCLUDED.InProgressInvalidationBatches,
    DomainName = EXCLUDED.DomainName,
    ActiveTrustedSigners = EXCLUDED.ActiveTrustedSigners,
    ActiveTrustedKeyGroups = EXCLUDED.ActiveTrustedKeyGroups,
    AliasICPRecordals = EXCLUDED.AliasICPRecordals,
    Tags = EXCLUDED.Tags,
    CallerReference = EXCLUDED.CallerReference,
    Aliases = EXCLUDED.Aliases,
    DefaultRootObject = EXCLUDED.DefaultRootObject,
    Origins = EXCLUDED.Origins,
    OriginGroups = EXCLUDED.OriginGroups,
    DefaultCacheBehavior = EXCLUDED.DefaultCacheBehavior,
    CacheBehaviors = EXCLUDED.CacheBehaviors,
    CustomErrorResponses = EXCLUDED.CustomErrorResponses,
    Comment = EXCLUDED.Comment,
    Logging = EXCLUDED.Logging,
    PriceClass = EXCLUDED.PriceClass,
    Enabled = EXCLUDED.Enabled,
    ViewerCertificate = EXCLUDED.ViewerCertificate,
    Restrictions = EXCLUDED.Restrictions,
    WebACLId = EXCLUDED.WebACLId,
    HttpVersion = EXCLUDED.HttpVersion,
    IsIPV6Enabled = EXCLUDED.IsIPV6Enabled,
    _tags = EXCLUDED._tags,
    _account_id = EXCLUDED._account_id
  ;

