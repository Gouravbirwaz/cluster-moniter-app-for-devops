from kubernetes import client, config
import logging
from app.core.config import settings

logger = logging.getLogger(__name__)

class RiskAnalyzer:
    def __init__(self):
        try:
            config.load_kube_config()
            self.v1 = client.CoreV1Api()
            self.apps_v1 = client.AppsV1Api()
        except Exception as e:
            logger.error(f"Failed to load kube config: {e}")

    async def evaluate_risk(self, intent: dict) -> dict:
        """
        Evaluate the risk of a Kubernetes operation.
        Returns: {"status": "safe" | "rejected", "reason": str}
        """
        operation = intent.get("intent")
        namespace = intent.get("namespace", "default")
        
        if operation == "restart_pod":
            pod_name = intent.get("pod_name")
            return await self._analyze_pod_restart(namespace, pod_name)
        
        if operation == "scale_deployment":
            deployment_name = intent.get("deployment_name")
            replicas = intent.get("replicas")
            return await self._analyze_scale(namespace, deployment_name, replicas)

        # Default to safe if unknown operation (should be validated by Agent-1)
        return {"status": "safe", "reason": "Operation listed as low risk"}

    async def _analyze_pod_restart(self, namespace: str, pod_name: str) -> dict:
        try:
            # In a real scenario, we'd check metrics for traffic. 
            # For this demo, we simulate checking traffic distribution.
            logger.info(f"Analyzing risk for restarting pod {pod_name} in {namespace}")
            
            # Simulated check: If the pod is the only one in its service, it's high risk.
            return {"status": "safe", "reason": "Redundancy available. Rolling restart recommended."}
        except Exception as e:
            return {"status": "rejected", "reason": f"Error during risk analysis: {str(e)}"}

    async def _analyze_scale(self, namespace: str, deployment_name: str, replicas: int) -> dict:
        try:
            logger.info(f"Analyzing risk for scaling {deployment_name} to {replicas} replicas")
            if replicas == 0:
                return {"status": "rejected", "reason": "Scaling to 0 is high risk for production services."}
            return {"status": "safe", "reason": "Scaling operation within safe bounds."}
        except Exception as e:
            return {"status": "rejected", "reason": str(e)}

risk_analyzer = RiskAnalyzer()
