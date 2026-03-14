from pydantic_settings import BaseSettings
import os

class Settings(BaseSettings):
    PROJECT_NAME: str = "K8s Monitor Platform"
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = os.environ.get("SECRET_KEY", "your-secret-key-here")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8  # 8 days
    
    PROMETHEUS_URL: str = os.environ.get("PROMETHEUS_URL", "http://localhost:9090")
    REDIS_URL: str = os.environ.get("REDIS_URL", "redis://localhost:6379/0")
    
    # K8s Config
    KUBE_CONFIG_PATH: str = os.environ.get("KUBE_CONFIG_PATH", "")
    
    # Microservices URLs
    GITHUB_SERVICE_URL: str = os.environ.get("GITHUB_SERVICE_URL", "http://localhost:8001")
    VAULT_SERVICE_URL: str = os.environ.get("VAULT_SERVICE_URL", "http://localhost:8002")
    
    def __init__(self, **values):
        super().__init__(**values)
        if not self.KUBE_CONFIG_PATH:
            local_kubeconfig = os.path.join(os.getcwd(), "temp_kubeconfig")
            if os.path.exists(local_kubeconfig):
                self.KUBE_CONFIG_PATH = local_kubeconfig

    class Config:
        case_sensitive = True

settings = Settings()
