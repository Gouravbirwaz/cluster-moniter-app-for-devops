from app.kubernetes.kube_client import kube_client
from app.metrics.prometheus_client import prometheus_client
from app.metrics import prometheus_queries as queries
from app.models.cluster_models import ClusterOverview
import asyncio
import logging

logger = logging.getLogger(__name__)

class ClusterService:
    async def get_overview(self) -> ClusterOverview:
        try:
            # Get K8s data
            if not kube_client.v1:
                raise Exception("Kubernetes client not initialized")
            
            nodes = kube_client.v1.list_node()
            pods = kube_client.v1.list_pod_for_all_namespaces()
            
            total_nodes = len(nodes.items)
            ready_nodes = len([n for n in nodes.items if any(c.type == 'Ready' and c.status == 'True' for c in n.status.conditions)])
            
            total_pods = len(pods.items)
            running_pods = len([p for p in pods.items if p.status.phase == 'Running'])
            pending_pods = len([p for p in pods.items if p.status.phase == 'Pending'])
            failed_pods = len([p for p in pods.items if p.status.phase == 'Failed'])
            
            version = nodes.items[0].status.node_info.kubelet_version if nodes.items else "Unknown"
            status = "Healthy" if ready_nodes == total_nodes else "Degraded"
        except Exception as e:
            logger.warning(f"K8s data fetch failed: {e}. Using fallback.")
            # Fallback for when K8s is unreachable
            total_nodes = 0
            ready_nodes = 0
            total_pods = 0
            running_pods = 0
            pending_pods = 0
            failed_pods = 0
            version = "Disconnected"
            status = "Communication Error"
        
        # Get Metrics
        try:
            metrics_results = await asyncio.gather(
                prometheus_client.query(queries.CLUSTER_CPU_USAGE),
                prometheus_client.query(queries.CLUSTER_MEM_USAGE),
                prometheus_client.query(queries.NODE_CPU_CAPACITY),
                prometheus_client.query(queries.NODE_MEM_CAPACITY)
            )
            
            def extract_val(res):
                if res.get("status") == "success" and res.get("data", {}).get("result"):
                    # Sum all results in case the query returned multiple vectors
                    total = 0.0
                    for item in res["data"]["result"]:
                        try:
                            total += float(item["value"][1])
                        except (ValueError, IndexError):
                            continue
                    return total
                return 0.0

            cpu_usage = extract_val(metrics_results[0])
            mem_usage = extract_val(metrics_results[1])
            cpu_cap = extract_val(metrics_results[2])
            mem_cap = extract_val(metrics_results[3])
            
            logger.info(f"Metrics: CPU Usage={cpu_usage}, CPU Cap={cpu_cap}, Mem Usage={mem_usage}, Mem Cap={mem_cap}")
            
            cpu_pct = (cpu_usage / cpu_cap * 100) if cpu_cap > 0 else 0.0
            mem_pct = (mem_usage / mem_cap * 100) if mem_cap > 0 else 0.0
        except Exception as e:
            logger.warning(f"Metrics fetch failed: {e}. Scaling to 0.")
            cpu_pct = 0.0
            mem_pct = 0.0
        
        return ClusterOverview(
            id="current-cluster",
            name="Production Cluster",
            region="Global",
            status=status,
            kubernetes_version=version,
            total_nodes=total_nodes,
            ready_nodes=ready_nodes,
            total_pods=total_pods,
            running_pods=running_pods,
            pending_pods=pending_pods,
            failed_pods=failed_pods,
            cpu_usage=min(cpu_pct, 100.0),
            memory_usage=min(mem_pct, 100.0)
        )

cluster_service = ClusterService()
