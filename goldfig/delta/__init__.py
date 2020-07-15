import json
from deepdiff import DeepDiff


# TODO: this needs to be replaced
def json_diff(left, right):
  diff = DeepDiff(left, right, ignore_order=True, view='tree')
  #return diff.to_dict()
  # TODO: this is extraordinarily dumb
  return json.loads(diff.to_json())
