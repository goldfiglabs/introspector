import logging
from typing import Any, Dict, Generator, Tuple

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

_log = logging.getLogger(__name__)


def _import_application(proxy: ServiceProxy,
                        application: Dict) -> Dict[str, Any]:
  arn = application['ApplicationArn']
  tags_resp = proxy.list('list_tags_for_resource', ResourceArn=arn)
  if tags_resp is not None:
    application['Tags'] = tags_resp[1]['ResourceTags']
  return application


def _import_applications(proxy: ServiceProxy):
  applications_resp = proxy.list('describe_applications')
  if applications_resp is not None:
    applications = applications_resp[1]['Applications']
    for application in applications:
      yield 'Application', _import_application(proxy, application)


def _import_application_version(proxy: ServiceProxy,
                                version: Dict) -> Dict[str, Any]:
  arn = version['ApplicationVersionArn']
  tags_resp = proxy.list('list_tags_for_resource', ResourceArn=arn)
  if tags_resp is not None:
    version['Tags'] = tags_resp[1]['ResourceTags']
  return version


def _import_application_versions(proxy: ServiceProxy):
  versions_resp = proxy.list('describe_application_versions')
  if versions_resp is not None:
    versions = versions_resp[1]['ApplicationVersions']
    for version in versions:
      yield 'ApplicationVersion', _import_application_version(proxy, version)


def _import_environment(proxy: ServiceProxy,
                        environment: Dict) -> Dict[str, Any]:
  arn = environment['EnvironmentArn']
  tags_resp = proxy.list('list_tags_for_resource', ResourceArn=arn)
  if tags_resp is not None:
    environment['Tags'] = tags_resp[1]['ResourceTags']
  resources_resp = proxy.get('describe_environment_resources',
                             EnvironmentName=environment['EnvironmentName'])
  if resources_resp is not None:
    environment.update(resources_resp['EnvironmentResources'])
  else:
    _log.warn(f'Failed to get environment resources for {arn}')
  return environment


def _import_environments(proxy: ServiceProxy):
  environments_resp = proxy.list('describe_environments')
  if environments_resp is not None:
    environments = environments_resp[1]['Environments']
    for environment in environments:
      yield 'Environment', _import_environment(proxy, environment)


def _import_elasticbeanstalk_region(
    proxy: ServiceProxy, region: str,
    spec: ServiceSpec) -> Generator[Tuple[str, Any], None, None]:
  _log.info(f'importing ElasticBeanstalk {region}')
  if resource_gate(spec, 'Application'):
    yield from _import_applications(proxy)
  if resource_gate(spec, 'ApplicationVersion'):
    yield from _import_application_versions(proxy)
  if resource_gate(spec, 'Environment'):
    yield from _import_environments(proxy)


SVC = RegionalService('elasticbeanstalk', _import_elasticbeanstalk_region)