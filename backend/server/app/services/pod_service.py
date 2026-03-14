from app.kubernetes.kube_client import kube_client
from app.metrics.prometheus_client import prometheus_client
from app.metrics import prometheus_queries as queries
from app.models.pod_models import PodDetail
from typing import List
import asyncio
from datetime import datetime

class PodService:
    async def get_pods(self, namespace: str = None) -> List[PodDetail]:
        try:
            if namespace:
                pods = kube_client.v1.list_namespaced_pod(namespace)
            else:
                pods = kube_client.v1.list_pod_for_all_namespaces()
        except Exception:
            return []
        
        metrics_results = await asyncio.gather(
            prometheus_client.query(queries.POD_CPU_USAGE),
            prometheus_client.query(queries.POD_MEM_USAGE)
        )
        
        cpu_metrics = {(r['metric'].get('pod', ''), r['metric'].get('namespace', '')): float(r['value'][1]) for r in metrics_results[0].get('data', {}).get('result', [])}
        mem_metrics = {(r['metric'].get('pod', ''), r['metric'].get('namespace', '')): float(r['value'][1]) for r in metrics_results[1].get('data', {}).get('result', [])}
        
        result = []
        for pod in pods.items:
            name = pod.metadata.name
            ns = pod.metadata.namespace
            
            cpu_use = cpu_metrics.get((name, ns), 0.0)
            mem_use = mem_metrics.get((name, ns), 0.0)
            
            result.append(PodDetail(
                id=pod.metadata.uid,
                name=name,
                namespace=ns,
                status=pod.status.phase,
                node_name=pod.spec.node_name or "N/A",
                restart_count=sum(c.restart_count for c in pod.status.container_statuses) if pod.status.container_statuses else 0,
                age_seconds=int((datetime.now().astimezone() - pod.metadata.creation_timestamp).total_seconds()),
                ip=pod.status.pod_ip or "N/A",
                image=pod.spec.containers[0].image if pod.spec.containers else "N/A",
                cpu_usage_cores=cpu_use,
                memory_usage_bytes=int(mem_use),
                containers=[c.name for c in pod.spec.containers],
                labels=pod.metadata.labels or {},
                events=[], # Would need to fetch events separately
                start_time=pod.status.start_time
            ))
        return result

pod_service = PodService()
