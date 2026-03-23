from Cryptodome.Cipher import AES
from Cryptodome.Random import get_random_bytes
from app.core.config import settings
import base64
import json

class EncryptionService:
    def __init__(self):
        # Key must be 32 bytes for AES-256
        key_str = settings.VAULT_SECRET_KEY
        if len(key_str) < 32:
            key_str = (key_str * 32)[:32]
        self.key = key_str.encode()[:32]

    def encrypt(self, plain_text: str) -> str:
        nonce = get_random_bytes(12)
        cipher = AES.new(self.key, AES.MODE_GCM, nonce=nonce)
        ciphertext, tag = cipher.encrypt_and_digest(plain_text.encode())
        
        # Combine nonce, tag, and ciphertext
        combined = base64.b64encode(nonce + tag + ciphertext).decode()
        return combined

    def decrypt(self, encrypted_text: str) -> str:
        data = base64.b64decode(encrypted_text.encode())
        nonce = data[:12]
        tag = data[12:28]
        ciphertext = data[28:]
        
        cipher = AES.new(self.key, AES.MODE_GCM, nonce=nonce)
        decrypted = cipher.decrypt_and_verify(ciphertext, tag)
        return decrypted.decode()

encryption_service = EncryptionService()

