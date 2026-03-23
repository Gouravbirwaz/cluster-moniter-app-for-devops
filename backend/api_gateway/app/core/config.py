from pydantic_settings import BaseSettings
import os

class Settings(BaseSettings):
    PROJECT_NAME: str = "DevOps Platform Gateway"
    API_V1_STR: str = "/api/v1"
    
    JWT_SECRET: str = os.getenv("JWT_SECRET", "super-secret-key-1234567890")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7 # 1 week
    
    # Service URLs
    AGENT1_SERVICE_URL: str = os.getenv("AGENT1_SERVICE_URL", "http://127.0.0.1:8005")
    CLUSTER_GUARDIAN_URL: str = os.getenv("CLUSTER_GUARDIAN_URL", "http://127.0.0.1:8006")
    METRICS_SERVICE_URL: str = os.getenv("METRICS_SERVICE_URL", "http://127.0.0.1:8008")
    GITHUB_SERVICE_URL: str = os.getenv("GITHUB_SERVICE_URL", "http://127.0.0.1:8001")
    VAULT_SERVICE_URL: str = os.getenv("VAULT_SERVICE_URL", "http://127.0.0.1:8002")
    
    class Config:
        env_file = ".env"

settings = Settings()
