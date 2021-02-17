SELECT
  name,
  uri,
  requestpayment->>'Payer' AS Payer
FROM
  aws_s3_bucket
WHERE
  requestpayment->>'Payer' = 'BucketOwner'