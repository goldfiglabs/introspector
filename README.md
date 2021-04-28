# Introspector CLI & SQL Database Schema

![kiddopaint-1614728453761](https://user-images.githubusercontent.com/291215/109745547-e6083b80-7b88-11eb-85c1-a64bb935a841.png)

Introspector is a tool and schema for importing cloud infrastructure configuration.
The goal is to unlock the expressive power of SQL and relational databases to ask questions about your infrastructure's security, compliance, and governance posture.

## Why?

We (@ [Gold Fig Labs](https://goldfiglabs.com)) were inspired by `osquery` to bring the same level of structure and consistency to the data backing our cloud deployments. All of this information is available from the underlying platform but is in disparate places and relationships can be difficult to find. Additionally, the expressivity of SQL far outstrips the querying functionality built into the existing CLI tools (`aws`, `gcloud`, etc.). At the cost of needing to import the data, Introspector allows you to issue more specific or complex queries, or even join against internal data sources (like an org chart) to produce customized reports. Introspector is not intended to replace provider tools, but instead standardize the process of analyzing your infrastructure.

## Introspector Components

1. Import - Run an import job against a cloud platform (currently AWS is supported) to retrieve your deployment details. This takes a snapshot of your current deployment's configuration, settings, and policies. Your database is updated to match the status of your infrastructure, and observed deltas from the previous snapshot are logged.

1. Analyze - Introspector comes with some [tools](#prepackaged-tools) out of the box to start analyzing your cloud infrastructure. But, these tools are mostly just wrappers around SQL queries. You can extend these tools or implement your own by writing SQL. See [Example Queries](#example-queries) below.

## Pre-requisites

- [Docker](https://docs.docker.com/get-docker/)

  ```
  $ docker --version
  Docker version 19.03.8, build afacb8b
  $ docker-compose --version
  docker-compose version 1.25.5, build 8a1c60f6
  ```

- [AWS command line interface](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)

  ```
  aws configure list
  ```

## Getting started

1. Download the latest Introspector [release](https://github.com/goldfiglabs/introspector/releases):

  Linux:
   ```
    curl -LO https://github.com/goldfiglabs/introspector/releases/latest/download/introspector_linux.zip
    unzip introspector_linux.zip
   ```

  OSX:
   ```
    curl -LO https://github.com/goldfiglabs/introspector/releases/latest/download/introspector_osx.zip
    unzip introspector_osx.zip
   ```

1. Start Introspector containers:
   ```
    docker-compose up -d
   ```

## Usage

Initialize Introspector system and schemas:

```
./introspector init
```

Import data from provider:

```
./introspector account aws import
```

Note that this may take a couple of minutes.

At this stage the underlying data is ready for querying, analysis, or alerting. You can get a summary of the import using:

```
./introspector status
```

## Prepackaged Tools

Find all untagged resources:

```
./introspector tags find-untagged
```

Get a report on all tags used across every resource:

```
./introspector tags report
```

Run several queries demonstrating a sample of the [CIS](https://www.cisecurity.org/)

AWS Foundation Benchmark:

```
./introspector cis foundation
```

Run an arbitrary SQL query against your data:

```
./introspector run "SELECT COUNT(*) FROM aws_ec2_instance"
```

## Example Queries

Get every S3 bucket:

```
cat sample_queries/aws_storage_buckets.sql
SELECT
  name,
  uri,
  creationdate
FROM
  aws_s3_bucket
./introspector run sample_queries/all_storage_buckets.sql
```

Get all public IP addresses across all AWS instances:

```
cat sample_queries/aws_ec2_instance_ips.sql
SELECT
  uri,
  instanceid,
  publicipaddress
FROM
  aws_ec2_instance
./introspector run sample_queries/aws_ec2_instance_ips.sql
```

Get every AWS S3 bucket where payer is the bucket owner:

```
cat sample_queries/aws_owner_pays_buckets.sql
SELECT
  name,
  uri,
  requestpayment->>'Payer' AS Payer
FROM
  aws_s3_bucket
WHERE
  requestpayment->>'Payer' = 'BucketOwner'
./introspector run sample_queries/aws_owner_pays_buckets.sql
```

Get total size for all disks:

```
cat sample_queries/aws_total_disk_size.sql
SELECT
  SUM(size)
FROM
  aws_ec2_volume
./introspector run sample_queries/aws_total_disk_size.sql
```

After running an import job multiple times, you can also query for resource that have been flagged as 'update' or 'delete':

```
./introspector run "SELECT * FROM resource_delta WHERE change_type = 'delete'"
```

See more in the `sample_queries/` folder.

## FAQ

1. What's currently supported?

   Introspector is being released with support for most common AWS services, including IAM, EC2, and S3, as well as higher level services such as Lambda, ECS, and plumbing such as SNS and SQS. Please check out the [schema docs](https://www.goldfiglabs.com/introspector-schema-docs/) to see all of the currently supported resources.

1. What's the set of permissions needed to run an import?

   Introspector uses read-only API calls, will not make any changes to your infrastructure, and does not require any write permissions for any API.

   - AWS: the available credentials when running the import must have at least permissions in the following policies:

     - arn:aws:iam::aws:policy/SecurityAudit
     - arn:aws:iam::aws:policy/job-function/ViewOnlyAccess

     The following commands can create the read-only account credentials which should be saved to ~/.aws/credentials:

   ```
   export ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account'  | awk -F '"' '{print $2}')
   aws iam create-group --group-name Introspector
   aws iam create-policy --policy-name Introspector-Ro-Additions --policy-document file://$(pwd)/permission-policies/aws-introspector-ro.json
   aws iam attach-group-policy --group-name Introspector --policy-arn arn:aws:iam::aws:policy/SecurityAudit
   aws iam attach-group-policy --group-name Introspector --policy-arn arn:aws:iam::aws:policy/job-function/ViewOnlyAccess
   aws iam attach-group-policy --group-name Introspector --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/Introspector-Ro-Additions
   aws iam create-user --user-name introspector
   aws iam add-user-to-group --user-name introspector --group-name Introspector
   aws iam create-access-key --user-name introspector
   ```

1. How does Introspector compare Terraform, Deployment Manager, Cloudformation, etc?

   Infrastructure-as-code tools (which are great!) impose structure and assert how portions of your infrastructure _should_ be. Introspector is focused on surveying what your infrastructure _actually is_ and makes no changes to your deployment. This is a complementary tool to IAC, and indeed one use case could be aiding in migrating to and enforcing the usage of IAC.

1. What's next on the Roadmap?

   Increasing the breadth of services supported and normalization of data that appears in different forms throughout a provider's data. See something missing? File an issue—we'd love your contributions!

## Schema Documentation

Schema documentation can be found online:

- [https://www.goldfiglabs.com/introspector-schema-docs/](https://www.goldfiglabs.com/introspector-schema-docs/)

Alternatively, your running Docker instance will have the docs for your build:

- [http://localhost:5000/](http://localhost:5000/)

## License

Copyright (c) 2019-2021 [Gold Fig Labs Inc.](https://www.goldfiglabs.com/)

This Source Code Form is subject to the terms of the Mozilla Public License, v.2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

[Mozilla Public License v2.0](./LICENSE)
