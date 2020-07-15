from datetime import datetime
import sys

from goldfig.delta.report import Report


def _format_date(d: datetime) -> str:
  return d.astimezone().strftime('%Y-%m-%d %H:%M:%S')


def print_report(import_report: Report):
  if import_report.end is None:
    end_date = '<INCOMPLETE>'
  else:
    end_date = _format_date(import_report.end)
  print(f'  Start:  {_format_date(import_report.start)}')
  print(f'  End:  {end_date}')
  error_count = len(
      import_report.errors) if import_report.errors is not None else 0
  print(f'  Errors:  {error_count}')
  print(f'  Resources added:  {import_report.resources_added}')
  print(f'  Resources removed:  {import_report.resources_deleted}')
  print(f'  Resources updated:  {import_report.resources_updated}')
  print(f'    Attributes added:  {import_report.attrs_added}')
  print(f'    Attributes removed:  {import_report.attrs_deleted}')
  print(f'    Attributes updated:  {import_report.attrs_updated}')


def query_yes_no(question: str, default: str = 'yes'):
  """Ask a yes/no question via raw_input() and return their answer.

    "question" is a string that is presented to the user.
    "default" is the presumed answer if the user just hits <Enter>.
        It must be "yes" (the default), "no" or None (meaning
        an answer is required of the user).

    The "answer" return value is True for "yes" or False for "no".
    """
  valid = {"yes": True, "y": True, "ye": True, "no": False, "n": False}
  if default is None:
    prompt = " [y/n] "
  elif default == "yes":
    prompt = " [Y/n] "
  elif default == "no":
    prompt = " [y/N] "
  else:
    raise ValueError("invalid default answer: '%s'" % default)

  while True:
    sys.stdout.write(question + prompt)
    choice = input().lower()
    if default is not None and choice == '':
      return valid[default]
    elif choice in valid:
      return valid[choice]
    else:
      sys.stdout.write("Please respond with 'yes' or 'no' "
                       "(or 'y' or 'n').\n")
