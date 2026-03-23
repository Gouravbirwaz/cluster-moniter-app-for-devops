from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.vault.vault_service import VaultService
from app.core.config import settings
from pydantic import BaseModel
from typing import List, Optional
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

router = APIRouter(tags=["vault"])


# Database setup
engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class SecretCreate(BaseModel):
    name: str
    type: str
    value: str
    description: Optional[str] = None

class SecretResponse(BaseModel):
    id: str
    name: str
    type: str
    description: Optional[str] = None

@router.post("/secrets", response_model=SecretResponse)
def create_secret(secret: SecretCreate, db: Session = Depends(get_db)):
    vault = VaultService(db)
    try:
        db_secret = vault.create_secret(secret.name, secret.type, secret.value, secret.description)
        return db_secret.to_dict()
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/secrets", response_model=List[SecretResponse])
def list_secrets(db: Session = Depends(get_db)):
    vault = VaultService(db)
    secrets = vault.list_secrets()
    return [s.to_dict() for s in secrets]

@router.delete("/secrets/{name}")
def delete_secret(name: str, db: Session = Depends(get_db)):
    vault = VaultService(db)
    if vault.delete_secret(name):
        return {"message": "Secret deleted"}
    raise HTTPException(status_code=404, detail="Secret not found")

@router.get("/secrets/{name}/value")
def get_secret_value(name: str, db: Session = Depends(get_db)):
    vault = VaultService(db)
    value = vault.get_secret_value(name)
    if value:
        return {"value": value}
    raise HTTPException(status_code=404, detail="Secret not found")
