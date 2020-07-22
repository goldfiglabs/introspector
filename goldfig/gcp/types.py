from typing import Union

import google.auth.credentials
from google.oauth2 import credentials

GcpCredentials = Union[credentials.Credentials,
                       google.auth.credentials.Credentials]