class GFError(Exception):
  '''Wrapper for errors to be thrown by this library'''
  def __init__(self, message):
    super().__init__(message)
    self.message = message


class GFInternal(GFError):
  pass

class GFNoAccess(GFError):
  def __init__(self, service: str, method: str):
    super().__init__(f'No access to {service} - {method}')
    self.service = service
    self.method = method