import os
from typing import Dict, Iterator

from botocore.loaders import create_loader
from botocore.regions import EndpointResolver
import botocore.session as boto
from botocore.exceptions import ClientError


class RegionCache:
  def __init__(self, session: boto.Session, partition: str):
    self._boto = session
    self._cache: Dict[str, bool] = {}
    self.partition = partition
    data_dir = os.path.join(os.path.dirname(boto.__file__), 'data')
    self._loader = create_loader(data_dir)
    endpoint_data = self._loader.load_data('endpoints')
    self._endpoints = EndpointResolver(endpoint_data)

  def _region_is_available(self, region: str) -> bool:
    # https://www.cloudar.be/awsblog/checking-if-a-region-is-enabled-using-the-aws-api/
    # https://stackoverflow.com/a/56184952
    regional_sts = self._boto.create_client('sts', region_name=region)
    try:
      regional_sts.get_caller_identity()
      return True
    except ClientError:
      return False

  def _get_and_cache_region(self, region: str) -> bool:
    cached = self._cache.get(region)
    if cached is not None:
      return cached
    available = self._region_is_available(region)
    self._cache[region] = available
    return available

  def regions_for_service(self, service: str) -> Iterator[str]:
    sm = self._loader.load_service_model(service, type_name='service-2')
    prefix = sm['metadata'].get('endpointPrefix', service)
    for region in self._endpoints.get_available_endpoints(
        prefix, partition_name=self.partition):
      if self._get_and_cache_region(region):
        yield region
