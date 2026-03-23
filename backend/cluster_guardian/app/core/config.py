from pydantic_settings import BaseSettings
import os

class Settings(BaseSettings):
    PROJECT_NAME: str = "Cluster Guardian Agent"
    API_V1_STR: str = "/api/v1"
    
    # Redis
    REDIS_HOST: str = os.getenv("REDIS_HOST", "localhost")
    REDIS_PORT: int = int(os.getenv("REDIS_PORT", 6379))
    
    # Risk Analysis Thresholds
    TRAFFIC_THRESHOLD_PERCENT: float = 80.0
    
    class Config:
        env_file = ".env"

settings = Settings()
