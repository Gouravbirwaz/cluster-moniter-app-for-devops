from kubernetes import client, config
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

class KubeClient:
    def __init__(self):
        self._v1 = None
        self._apps_v1 = None
        self._custom_objects = None
        self._initialized = False

    def _ensure_initialized(self):
        if self._initialized:
            return True
        
        try:
            if settings.KUBE_CONFIG_PATH:
                config.load_kube_config(config_file=settings.KUBE_CONFIG_PATH)
                logger.info(f"Loaded K8s config from: {settings.KUBE_CONFIG_PATH}")
            else:
                try:
                    config.load_incluster_config()
                    logger.info("Loaded in-cluster K8s config")
                except config.ConfigException:
                    config.load_kube_config()
                    logger.info("Loaded default kubeconfig from ~/.kube/config")
            
            self._v1 = client.CoreV1Api()
            self._apps_v1 = client.AppsV1Api()
            self._custom_objects = client.CustomObjectsApi()
            self._initialized = True
            return True
        except Exception as e:
            logger.warning(f"K8s client initialization failed (config path: {settings.KUBE_CONFIG_PATH}): {e}. Will retry on next access.")
            return False

    @property
    def v1(self):
        self._ensure_initialized()
        return self._v1

    @property
    def apps_v1(self):
        self._ensure_initialized()
        return self._apps_v1

    @property
    def custom_objects(self):
        self._ensure_initialized()
        return self._custom_objects

kube_client = KubeClient()
