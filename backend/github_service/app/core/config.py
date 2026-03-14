from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    APP_NAME: str = "GitHub Monitoring Service"
    DEBUG: bool = True
    PORT: int = 8001
    
    # Database
    DATABASE_URL: str = "sqlite:///./github_monitor.db"
    
    # Security
    VAULT_SECRET_KEY: str = "your-very-secret-vault-key-change-it" # Use 32-byte string for Fernet
    
    # Redis for WebSocket Pub/Sub
    REDIS_URL: str = "redis://localhost:6379/1"
    
    # GitHub Config
    GITHUB_WEBHOOK_SECRET: Optional[str] = None
    VAULT_SERVICE_URL: str = "http://localhost:8002/api/v1"
    
    class Config:
        env_file = ".env"

settings = Settings()
