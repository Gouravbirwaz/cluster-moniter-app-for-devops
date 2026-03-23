from pydantic_settings import BaseSettings
import os

class Settings(BaseSettings):
    PROJECT_NAME: str = "Agent-1 Reasoning Service"
    API_V1_STR: str = "/api/v1"
    
    # LLM Service URL
    LLM_SERVICE_URL: str = os.getenv("LLM_SERVICE_URL", "http://127.0.0.1:8004/api/v1/llm")

    
    # Redis
    REDIS_HOST: str = os.getenv("REDIS_HOST", "localhost")
    REDIS_PORT: int = int(os.getenv("REDIS_PORT", 6379))
    
    # Backend Server (for cluster data)
    BACKEND_SERVER_URL: str = os.getenv("BACKEND_SERVER_URL", "http://127.0.0.1:8000")
    
    class Config:
        env_file = ".env"

settings = Settings()
