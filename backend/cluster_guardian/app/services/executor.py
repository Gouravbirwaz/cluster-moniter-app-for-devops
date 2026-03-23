from kubernetes import client, config
import logging

logger = logging.getLogger(__name__)

class ClusterExecutor:
    def __init__(self):
        try:
            config.load_kube_config()
            self.v1 = client.CoreV1Api()
            self.apps_v1 = client.AppsV1Api()
        except Exception as e:
            logger.error(f"Failed to load kube config: {e}")

    async def execute(self, intent: dict) -> dict:
        operation = intent.get("intent")
        namespace = intent.get("namespace", "default")
        
        try:
            if operation == "restart_pod":
                pod_name = intent.get("pod_name")
                self.v1.delete_namespaced_pod(name=pod_name, namespace=namespace)
                return {"status": "success", "message": f"Pod {pod_name} deleted (restarted)"}
            
            if operation == "scale_deployment":
                deployment_name = intent.get("deployment_name")
                replicas = intent.get("replicas")
                body = {"spec": {"replicas": replicas}}
                self.apps_v1.patch_namespaced_deployment_scale(
                    name=deployment_name, namespace=namespace, body=body
                )
                return {"status": "success", "message": f"Deployment {deployment_name} scaled to {replicas}"}
            
            return {"status": "error", "message": f"Operation {operation} not implemented"}
        except Exception as e:
            logger.error(f"Execution error: {e}")
            return {"status": "error", "message": str(e)}

executor = ClusterExecutor()
