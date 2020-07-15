class GFError(Exception):
  '''Wrapper for errors to be thrown by this library'''
  def __init__(self, message):
    super().__init__(message)
    self.message = message


class GFInternal(GFError):
  pass