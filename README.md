# Gold Fig CLI & SQL Database Schema

Gold Fig is a database schema and a set of command line tools that enable you to ask questions about your cloud infrastructure using SQL. After importing your data, you can write SQL queries to get answers in a consistent and uniform manner across providers, accounts, or environments.

## Why?

We were inspired by `osquery` to bring the same level of structure and consistency to the data backing our cloud deployments. All of this information is available from the underlying platform but is in disparate places and relationships can be difficult to find. Additionally, the expressivity of SQL far outstrips the querying functionality built into the existing CLI tools (`aws`, `gcloud`, etc.). At the cost of needing to import the data, Gold Fig allows you to issue more specific or complex queries. Gold Fig is not intended to replace provider tools, but instead standardize the process of analyzing your infrastructure.

## Gold Fig Components

1. Import - Run an import job against a cloud platform (currently AWS and GCP are supported) to retrieve your deployment details. This takes a snapshot of your current deployment's configuration. Your database is updated to match the status of your infrastructure, and observed deltas from the previous snapshot are logged.

1. Analyze - Gold Fig comes with some [tools](#prepackaged-tools) out of the box to start analyzing your cloud infrastructure. But, these tools are mostly just wrappers around SQL queries. You can extend these tools or implement your own by writing SQL. See [Example Queries](#example-queries) below.

## Pre-requisites

- Tested on MacOS High Sierra 10.13.6+, Ubuntu Linux 18.04
- postgres (PostgreSQL) 12.3, pipenv, AWS, GCP command line interfaces

* [pipenv](https://pypi.org/project/pipenv/)

- [AWS command line interface](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) (Be sure to init and login)
- [GCloud command line interface](https://cloud.google.com/sdk/docs/downloads-interactive)

  - Mac:

    ```
    brew update
    brew doctor
    brew install postgresql
    brew services start postgresql
    brew install pyenv
    brew install pipenv
    aws configure
    gcloud login
    ```

  - Linux:

    ```
    sudo apt-get update
    sudo apt-get install postgresql
    ```

    Follow [pyenv github install](https://github.com/pyenv/pyenv#basic-github-checkout) instructions

    ```
    pip install pipenv
    pyenv install 3.7.7
    aws configure
    gcloud login
    ```

  - AWS EC2 Redhat:

    ```
    sudo yum install postgresql postgresql-server -y
    sudo /usr/bin/postgresql-setup --initdb
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    sudo yum install @development -y
    sudo yum install python38 -y
    pip3 install --user pipenv
    ```

## Getting started

1. Clone repo:

   ```
   git clone https://github.com/goldfig/goldfig.git
   ```

1. Bootstrap in to correct environment. Also be sure to rerun these any time your pull down updates.

   ```
   pipenv install
   pipenv shell
   ```

1. Create database and user on your Postgres instance (e.g. using psql or equivalent):

   ```
   sudo -u postgres psql < db/install.sql
   ```

   For OSX:

   ```
   cat >> /var/lib/pgsql/data/pg_hba.conf
   host    all             goldfig             ::1/128                 password
   systemctl restart postgresql.service
   ```

1. Initialize the CLI and Postgres schemas. Defaults to `postgres://localhost` with above credentials. Update connection strings in `bootstrap_db.py` if required.

   ```
   ./gf init
   ```

Check AWS settings:
aws ec2 describe-iam-instance-profile-associations
aws configure list
aws organizations describe-organization

## Usage

Import data from provider:

```
./gf account aws import
./gf account gcp import

```

Note that currently this may take a couple minutes.

At this stage the underlying data is ready for querying, analysis, or alerting. You can get a summary of what's been imported using:

```
./gf status
```

## Prepackaged Tools

Find all untagged resources:

```
./gf tags find-untagged
```

Get a report on all tags used across every resource:

```
./gf tags report
```

Run several queries demonstrating a sample of the [CIS](https://www.cisecurity.org/) 3-Tier Web Application Benchmark:
Note that the `TAG_SPEC` below is used to identify infrastructure that is part of a specific tier. So it may look like `role=web,role=app` or `tier=frontend,tier=backend` or however you have tagged your resources.

```
./gf cis --tags=<TAG_SPEC>
```

Run an arbitrary SQL query against your data:

```
./gf run "SELECT COUNT(*) FROM aws_ec2_instance"
```

## Example Queries

Get every storage bucket:

```
cat sample_queries/all_storage_buckets.sql
SELECT name,
  uri
FROM resource
WHERE category = 'StorageBucket'
./gf run sample_queries/all_storage_buckets.sql
```

Get all public IP addresses across all AWS instances:

```
cat sample_queries/aws_ec2_instance_ips.sql
SELECT instanceid, publicipaddress
FROM aws_ec2_instance
./gf run sample_queries/aws_ec2_instance_ips.sql
```

Get every AWS storage bucket where payer is the bucket owner:

```
cat sample_queries/aws_owner_pays_buckets.sql
SELECT name,
  uri,
  requestpayment->>'Payer' AS Payer
FROM aws_s3_bucket
WHERE requestpayment->>'Payer' = 'BucketOwner'
./gf run sample_queries/aws_owner_pays_buckets.sql
```

Get total size for all disks:

```
cat sample_queries/gcp_total_disk_size.sql
SELECT SUM(sizegb)
FROM gcp_compute_disk
./gf run sample_queries/gcp_total_disk_size.sql
```

Get all GCP service accounts and their associated project

```
cat sample_queries/gcp_serviceaccounts.sql
select projectid, email from gcp_iam_serviceaccount
./gf run sample_queries/gcp_serviceaccounts.sql
```

After running an import job multiple times, you can also query for resource that have been flagged as 'update' or 'delete':

```
./gf run "SELECT * FROM resource_delta WHERE change_type = 'delete'"
```

## FAQ

1. What's currently supported?

   Gold Fig is being released with basic support for a few AWS and GCP services, focused primarily on IAM, ec2/compute, and s3/storage.

1. What's the set of permissions needed to run an import?

   Gold Fig uses read-only API calls, will not make any changes to your infrastructure, and does not require any write permissions for any API.

   - AWS: the available credentials when running the import must have at least permissions in the following policies:
     - arn:aws:iam::aws:policy/SecurityAudit
     - arn:aws:iam::aws:policy/job-function/ViewOnlyAccess
   - GCP: the credentials available via `gcloud` must have at least the permissions covered by the following roles, with bindings at the organization level\*:

     - roles/Browser
     - roles/firebase.developViewer
     - roles/iam.securityReviewer
     - roles/viewer

     \* Note that due to GCP's permission structure, `roles/owner` is not sufficient for organizations that include folders. In this case you will need to add the above roles.

1. How does Gold Fig compare Terraform, Deployment Manager, Cloudformation, etc?

   Infrastructure-as-code tools (which are great!) impose structure and assert how portions of your infrastructure _should_ be. Gold Fig is focused on surveying what your infrastructure _actually is_ and makes no changes to your deployment. This is a complementary tool to IAC, and indeed one use case could be aiding in migrating to and enforcing the usage of IAC.

1. What's next on the Roadmap?

   Increasing the breadth of services supported. Currently, only a few of the more common resources are properly mapped out, with relationships between them includes. We are hard at work adding support for more. If there's a particular resources of interest, please file an issue!

## Schema Documentation

Schema documentation can be found [here](./schema-docs)

## License
Copyright (c) 2019-2020 Gold Fig Labs Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, v.2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

[Mozilla Public License v2.0](./LICENSE)
