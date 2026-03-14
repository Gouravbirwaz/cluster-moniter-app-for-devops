from cryptography.fernet import Fernet
from app.core.config import settings
import base64

class EncryptionService:
    def __init__(self):
        # Fernet requires 32-urlsafe-base64-encoded bytes
        key = settings.VAULT_SECRET_KEY
        if len(key) < 32:
            key = (key * 32)[:32]
        
        encoded_key = base64.urlsafe_b64encode(key.encode() if isinstance(key, str) else key)
        self.fernet = Fernet(encoded_key)

    def encrypt(self, plain_text: str) -> str:
        return self.fernet.encrypt(plain_text.encode()).decode()

    def decrypt(self, encrypted_text: str) -> str:
        return self.fernet.decrypt(encrypted_text.encode()).decode()

encryption_service = EncryptionService()
