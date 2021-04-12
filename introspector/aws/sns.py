import json
import logging
from typing import Any, Dict, Generator, Tuple

from introspector.aws.fetch import ServiceProxy
from introspector.aws.svc import RegionalService, ServiceSpec, resource_gate

_log = logging.getLogger(__name__)

_TOPIC_SKIP = set(['TopicArn'])  # We already have this from the initial import
_TOPIC_JSON = set(['DeliveryPolicy', 'Policy', 'EffectiveDeliveryPolicy'])
_TOPIC_INT = set(
    ['SubscriptionsConfirmed', 'SubscriptionsDeleted', 'SubscriptionsPending'])


def _import_topic(proxy: ServiceProxy, topic_data: Dict) -> Dict:
  arn = topic_data['TopicArn']
  tags_result = proxy.list('list_tags_for_resource', ResourceArn=arn)
  if tags_result is not None:
    topic_data['Tags'] = tags_result[1]['Tags']
  attrs = proxy.get('get_topic_attributes', TopicArn=arn)
  for attr, value in attrs['Attributes'].items():
    if attr in _TOPIC_SKIP:
      continue
    elif attr in _TOPIC_JSON:
      topic_data[attr] = json.loads(value)
    elif attr in _TOPIC_INT:
      topic_data[attr] = int(value)
    else:
      topic_data[attr] = value
  return topic_data


def _import_topics(proxy: ServiceProxy):
  topics_resp = proxy.list('list_topics')
  if topics_resp is not None:
    for topic_data in topics_resp[1]['Topics']:
      yield 'Topic', _import_topic(proxy, topic_data)


_SUBSCRIPTION_SKIP = set(['Owner', 'SubscriptionArn', 'TopicArn'])
_SUBSCRIPTION_JSON = set([
    'DeliveryPolicy', 'EffectiveDeliveryPolicy', 'FilterPolicy',
    'RedrivePolicy'
])
_SUBSCRIPTION_BOOLEAN = set([
    'ConfirmationWasAuthenticated', 'PendingConfirmation', 'RawMessageDelivery'
])


def _import_subscription(proxy: ServiceProxy, subscription_data: Dict) -> Dict:
  arn = subscription_data['SubscriptionArn']
  attrs = proxy.get('get_subscription_attributes', SubscriptionArn=arn)
  if attrs is not None:
    for attr, value in attrs.get('Attributes', {}).items():
      if attr in _SUBSCRIPTION_SKIP:
        continue
      elif attr in _SUBSCRIPTION_JSON:
        subscription_data[attr] = json.loads(value)
      elif attr in _SUBSCRIPTION_BOOLEAN:
        if value in ('true', 'True'):
          subscription_data[attr] = True
        else:
          subscription_data[attr] = False
      else:
        subscription_data[attr] = value
  return subscription_data


def _import_subscriptions(proxy: ServiceProxy):
  subs_resp = proxy.list('list_subscriptions')
  if subs_resp is not None:
    for subscription_data in subs_resp[1]['Subscriptions']:
      if subscription_data['SubscriptionArn'] == 'PendingConfirmation':
        continue
      yield 'Subscription', _import_subscription(proxy, subscription_data)


def _import_sns_region(
    proxy: ServiceProxy, region: str,
    spec: ServiceSpec) -> Generator[Tuple[str, Any], None, None]:
  _log.info(f'importing SNS in {region}')
  if resource_gate(spec, 'Topic'):
    yield from _import_topics(proxy)
  if resource_gate(spec, 'Subscription'):
    yield from _import_subscriptions(proxy)


SVC = RegionalService('sns', _import_sns_region)