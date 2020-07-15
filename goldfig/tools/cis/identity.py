from psycopg2.extras import Json
from sqlalchemy.orm import Session

from goldfig.tools.cis.base import Profile, ThreeTierBenchmark, TierTag


class IamProfiles(ThreeTierBenchmark):
  def __init__(self):
    super().__init__(
        profile=Profile.LEVEL1,
        description='Tagged-Tier of VMs have a consistent and unique profile',
        reference_ids=['2.1'])

  def exec(self, db: Session, provider_account_id: int, tier_tag: TierTag):
    results = db.execute(
        '''
      -- pairs is the set of vm resource ids and the
      -- policy that they roll up to, via an auth chain
      WITH pairs AS (
        SELECT
          vm_policy_path.path[1] AS VM,
          vm_policy_path.path[array_length(vm_policy_path.path, 1)] AS policy_id
        FROM
          (
            -- auth_path is the recursive graph search to
            -- build an auth chain for each vm
            WITH RECURSIVE auth_path (src, dst, path) AS (
              SELECT
                VM.id AS src,
                Step.id AS dst,
                ARRAY[VM.id] AS path
              FROM
                resource AS VM
                LEFT JOIN resource_relation AS ActsAs
                  ON VM.id = ActsAs.resource_id
                  AND ActsAs.relation = 'acts-as'
                LEFT JOIN resource AS Step
                  ON Step.id = ActsAs.target_id
              WHERE
                VM.category = 'VMInstance'
                AND VM.provider_account_id = :provider_account_id

              UNION ALL

              SELECT
                AP.dst AS src,
                Step.id AS dst,
                array_append(AP.path, AP.dst) AS path
              FROM
                auth_path AS AP
                LEFT JOIN resource_relation AS Manages
                  ON AP.dst = Manages.target_id
                  AND Manages.relation = 'manages'
                LEFT JOIN resource AS Step
                  ON Step.id = Manages.resource_id
                LEFT JOIN resource AS Src
                  ON Src.id = AP.src
              WHERE
                Src.category != 'Policy'
            )
            SELECT
              array_append(AP.path, AP.dst) AS path,
              Policy.uri
            FROM
              auth_path AS AP,
              resource AS Policy
            WHERE
              Policy.id = AP.dst
              AND Policy.category = 'Policy'
          ) AS vm_policy_path
      )
      -- select, policy id, the tagged vms that roll up
      -- to that policy id, and the untagged vms that roll
      -- up to that policy id.
      -- Any results indicate failure:
      -- - either there is more than one policy for tagged vms
      -- - or untagged vms also roll up to the same policy
      SELECT
        Policy.uri AS policy_uri,
        tagged_pairs.vms AS tagged_vms,
        other_pairs.vms AS other_vms
      FROM
        (
          SELECT
            ARRAY_AGG(VM.uri) AS vms,
            pairs.policy_id AS policy_id,
            COUNT(*) OVER () AS cnt
          FROM
            pairs
            LEFT JOIN resource AS VM
              ON VM.id = pairs.vm
            LEFT JOIN resource_attribute AS Tags
              ON Tags.resource_id = VM.id
              AND Tags.type = 'Metadata'
              AND Tags.attr_name = 'Tags'
          WHERE
            Tags.attr_value->>:role_key = :role_value
          GROUP BY pairs.policy_id
        ) AS tagged_pairs
        LEFT JOIN
          (
            SELECT
              ARRAY_AGG(VM.uri) AS vms,
              COUNT(*) AS cnt,
              pairs.policy_id AS policy_id
            FROM
              pairs
              LEFT JOIN resource AS VM
                ON VM.id = pairs.vm
            WHERE NOT EXISTS (
              SELECT
                1
              FROM
                resource_attribute AS Tags
              WHERE
                Tags.attr_value->>:role_key = :role_value
                AND Tags.resource_id = pairs.vm
                AND Tags.type = 'Metadata'
                AND Tags.attr_name = 'Tags'
            )
            GROUP BY pairs.policy_id
          ) AS other_pairs
          ON tagged_pairs.policy_id = other_pairs.policy_id
        LEFT JOIN resource AS Policy
          ON Policy.id = tagged_pairs.policy_id
      WHERE
        tagged_pairs.cnt > 1
        OR
        other_pairs.cnt > 0
    ''', {
            'provider_account_id': provider_account_id,
            'role_key': tier_tag[0],
            'role_value': tier_tag[1]
        })
    rows = list(results)
    multiple_policies = {}
    shared_policies = {}
    for row in rows:
      policy_uri = row['policy_uri']
      multiple_policies[policy_uri] = row['tagged_vms']
      other_vms = row['other_vms']
      if other_vms is not None:
        shared_policies[policy_uri] = other_vms
    if len(rows) <= 1:
      multiple_policies = {}
    return {
        'multiple_policies_violations': multiple_policies,
        'shared_policies_violations': shared_policies
    }

  def exec_explain(self, db: Session, provider_account_id: int,
                   tier_tag: TierTag) -> str:
    results = self.exec(db, provider_account_id, tier_tag)
    key, value = tier_tag
    nl = '\n'
    multiple_policies = results['multiple_policies_violations']
    shared_policies = results['shared_policies_violations']
    if len(multiple_policies) + len(shared_policies) == 0:
      desc = 'NONE'
    else:
      desc = ''
      if len(multiple_policies) > 1:
        topic = 'Multiple Policies associated with a single tag'
        desc += '\t' + topic + '\n\t\t'
        lines = []
        for policy, vms in multiple_policies.items():
          lines.append(
              f'Policy URI {policy} assigned to VMs: {", ".join(vms)}')
        desc += '\n\t\t'.join(lines)
      if len(shared_policies) > 0:
        topic = 'Policies used by tagged VMs that are also in use by other VMs'
        desc += '\t' + topic + '\n\t\t'
        lines = []
        for policy, vms in shared_policies.items():
          lines.append(
              f'Policy URI {policy} also used by other VMs {", ".join(vms)}')
        desc += '\n\t\t'.join(lines)
    return f'VMs tagged {key}: {value} without a unique policy{nl}{desc}'
