import hmac

from websockify.auth_plugins import BasicHTTPAuth


class BasicHTTPAuthFile(BasicHTTPAuth):
    """BasicHTTPAuth reading "username:password" from a file"""

    def __init__(self, src=None):
        with open(src, 'rb') as f:
            super().__init__(f.read())

    def validate_creds(self, username, password):
        # Undo the ISO-8859-1 decoding of the Authorization header
        return hmac.compare_digest(f'{username}:{password}'.encode('ISO-8859-1'), self.src)
