from app.kubernetes.kube_client import kube_client
from app.models.workload_models import WorkloadDetail
from typing import List
from datetime import datetime

class WorkloadService:
    async def get_workloads(self, namespace: str = None) -> List[WorkloadDetail]:
        result = []
        
        # Fetch Workloads
        try:
            if not kube_client.apps_v1:
                return []
                
            if namespace:
                deps = kube_client.apps_v1.list_namespaced_deployment(namespace)
                sts = kube_client.apps_v1.list_namespaced_stateful_set(namespace)
                ds = kube_client.apps_v1.list_namespaced_daemon_set(namespace)
            else:
                deps = kube_client.apps_v1.list_deployment_for_all_namespaces()
                sts = kube_client.apps_v1.list_stateful_set_for_all_namespaces()
                ds = kube_client.apps_v1.list_daemon_set_for_all_namespaces()
        except Exception:
            return []

        for item in deps.items:
            result.append(WorkloadDetail(
                id=item.metadata.uid,
                name=item.metadata.name,
                namespace=item.metadata.namespace,
                type="deployment",
                replicas=item.spec.replicas or 0,
                available_replicas=item.status.available_replicas or 0,
                status="Healthy" if item.spec.replicas == item.status.available_replicas else "Degraded",
                image=item.spec.template.spec.containers[0].image,
                labels=item.metadata.labels or {},
                creation_timestamp=item.metadata.creation_timestamp,
                selector=item.spec.selector.match_labels or {},
                strategy=item.spec.strategy.type if item.spec.strategy else "Unknown"
            ))

        for item in sts.items:
            result.append(WorkloadDetail(
                id=item.metadata.uid,
                name=item.metadata.name,
                namespace=item.metadata.namespace,
                type="statefulset",
                replicas=item.spec.replicas or 0,
                available_replicas=item.status.ready_replicas or 0,
                status="Healthy" if item.spec.replicas == item.status.ready_replicas else "Degraded",
                image=item.spec.template.spec.containers[0].image,
                labels=item.metadata.labels or {},
                creation_timestamp=item.metadata.creation_timestamp,
                selector=item.spec.selector.match_labels or {},
                strategy=None
            ))

        return result

    async def get_namespaces(self) -> List[dict]:
        try:
            if not kube_client.v1:
                return []
            ns_list = kube_client.v1.list_namespace()
            pods = kube_client.v1.list_pod_for_all_namespaces()
            
            # Map pods to namespaces
            ns_stats = {}
            for ns in ns_list.items:
                ns_stats[ns.metadata.name] = {"total": 0, "running": 0, "failed": 0}
            
            for pod in pods.items:
                ns_name = pod.metadata.namespace
                if ns_name in ns_stats:
                    ns_stats[ns_name]["total"] += 1
                    phase = pod.status.phase
                    if phase == "Running":
                        ns_stats[ns_name]["running"] += 1
                    elif phase in ["Failed", "Unknown"]:
                        ns_stats[ns_name]["failed"] += 1

            return [{
                "name": ns.metadata.name,
                "status": ns.status.phase,
                "creation_timestamp": ns.metadata.creation_timestamp,
                "labels": ns.metadata.labels or {},
                "total_pods": ns_stats[ns.metadata.name]["total"],
                "running_pods": ns_stats[ns.metadata.name]["running"],
                "failed_pods": ns_stats[ns.metadata.name]["failed"]
            } for ns in ns_list.items]
        except Exception:
            return []

workload_service = WorkloadService()
