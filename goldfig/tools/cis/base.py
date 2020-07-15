from enum import Enum
from typing import Tuple, List

TierTag = Tuple[str, str]


class Profile(Enum):
  LEVEL1 = 1
  LEVEL2 = 2


class ThreeTierBenchmark:
  def __init__(self, profile: Profile, description: str,
               reference_ids: List[str]):
    self._profile = profile
    self._description = description
    self._reference_ids = reference_ids

  def __repr__(self) -> str:
    sections = ', '.join(self._reference_ids)
    return \
      f'3-Tier Architecture CIS Benchmark, {self._profile}. See Section(s): {sections} ' \
      f'Description: {self._description}'

  def exec_explain(self, *args, **kwargs) -> str:
    raise NotImplementedError('Abstract class')
