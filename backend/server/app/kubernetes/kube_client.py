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
            if settings.KUBE_API_SERVER:
                logger.info(f"Using Kubernetes API Server: {settings.KUBE_API_SERVER}")
                configuration = client.Configuration()
                configuration.host = settings.KUBE_API_SERVER
                api_client = client.ApiClient(configuration)
                self._v1 = client.CoreV1Api(api_client)
                self._apps_v1 = client.AppsV1Api(api_client)
                self._custom_objects = client.CustomObjectsApi(api_client)
            else:
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
            logger.warning(f"K8s client initialization failed: {e}. Will retry on next access.")
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

    def initialize_from_string(self, kubeconfig_str: str):
        """
        Dynamically initialize the Kubernetes client from a kubeconfig string.
        """
        import yaml
        import tempfile
        import os

        try:
            # Create a temporary file to store the kubeconfig string
            with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.yaml') as tmp:
                tmp.write(kubeconfig_str)
                tmp_path = tmp.name

            try:
                config.load_kube_config(config_file=tmp_path)
                logger.info(f"Loaded dynamic K8s config from temporary file: {tmp_path}")
                
                self._v1 = client.CoreV1Api()
                self._apps_v1 = client.AppsV1Api()
                self._custom_objects = client.CustomObjectsApi()
                self._initialized = True
                return True
            finally:
                # Clean up the temporary file
                if os.path.exists(tmp_path):
                    os.remove(tmp_path)
        except Exception as e:
            logger.error(f"Failed to initialize Kubernetes client from string: {e}")
            return False

kube_client = KubeClient()
