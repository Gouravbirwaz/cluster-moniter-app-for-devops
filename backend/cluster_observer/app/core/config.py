from pydantic_settings import BaseSettings
import os

class Settings(BaseSettings):
    PROJECT_NAME: str = "Cluster Observer Service"
    
    # Redis
    REDIS_HOST: str = os.getenv("REDIS_HOST", "127.0.0.1")
    REDIS_PORT: int = int(os.getenv("REDIS_PORT", 6379))
    
    # Kubernetes
    KUBE_CONFIG_PATH: str = os.getenv("KUBE_CONFIG_PATH", "")
    KUBE_API_SERVER: str = os.getenv("KUBE_API_SERVER", "")
    DUMMY_MODE: bool = os.getenv("DUMMY_MODE", "false").lower() == "true"
    
    class Config:
        env_file = ".env"

settings = Settings()
