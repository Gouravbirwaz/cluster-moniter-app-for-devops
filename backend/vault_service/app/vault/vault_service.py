from sqlalchemy.orm import Session
from app.models.secret_models import Secret
from app.vault.encryption import encryption_service
from typing import List, Optional
import logging

logger = logging.getLogger(__name__)

class VaultService:
    def __init__(self, db: Session):
        self.db = db

    def create_secret(self, name: str, secret_type: str, value: str, description: Optional[str] = None) -> Secret:
        encrypted_value = encryption_service.encrypt(value)
        db_secret = Secret(
            name=name,
            type=secret_type,
            encrypted_value=encrypted_value,
            description=description
        )
        self.db.add(db_secret)
        self.db.commit()
        self.db.refresh(db_secret)
        return db_secret

    def get_secret_value(self, name: str) -> Optional[str]:
        secret = self.db.query(Secret).filter(Secret.name == name).first()
        if secret:
            return encryption_service.decrypt(secret.encrypted_value)
        return None

    def list_secrets(self) -> List[Secret]:
        return self.db.query(Secret).all()

    def delete_secret(self, name: str) -> bool:
        secret = self.db.query(Secret).filter(Secret.name == name).first()
        if secret:
            self.db.delete(secret)
            self.db.commit()
            return True
        return False
