from app.kubernetes.kube_client import kube_client
from app.metrics.prometheus_client import prometheus_client
from app.metrics import prometheus_queries as queries
from app.models.node_models import NodeDetail
from typing import List
import asyncio

class NodeService:
    async def get_nodes(self) -> List[NodeDetail]:
        try:
            nodes = kube_client.v1.list_node()
        except Exception:
            return []
        
        metrics_results = await asyncio.gather(
            prometheus_client.query(queries.NODE_CPU_USAGE),
            prometheus_client.query(queries.NODE_MEM_USAGE)
        )
        
        cpu_metrics = {r['metric'].get('node', ''): float(r['value'][1]) for r in metrics_results[0].get('data', {}).get('result', [])}
        mem_metrics = {r['metric'].get('node', ''): float(r['value'][1]) for r in metrics_results[1].get('data', {}).get('result', [])}
        
        result = []
        for node in nodes.items:
            name = node.metadata.name
            status = "Ready" if any(c.type == 'Ready' and c.status == 'True' for c in node.status.conditions) else "NotReady"
            
            cpu_cap = float(node.status.allocatable.get('cpu', '1').replace('m', '')) / 1000.0 if 'm' in node.status.allocatable.get('cpu', '1') else float(node.status.allocatable.get('cpu', '1'))
            mem_cap = self._parse_mem(node.status.allocatable.get('memory', '0'))
            
            cpu_use = cpu_metrics.get(name, 0.0)
            mem_use = mem_metrics.get(name, 0.0)
            
            result.append(NodeDetail(
                id=node.metadata.uid,
                name=name,
                status=status,
                role="worker" if "node-role.kubernetes.io/worker" in node.metadata.labels else "control-plane",
                version=node.status.node_info.kubelet_version,
                internal_ip=next((addr.address for addr in node.status.addresses if addr.type == 'InternalIP'), "N/A"),
                cpu_capacity=cpu_cap,
                memory_capacity_bytes=mem_cap,
                disk_capacity_bytes=self._parse_mem(node.status.allocatable.get('ephemeral-storage', '0')),
                cpu_usage_pct=(cpu_use / cpu_cap * 100) if cpu_cap > 0 else 0.0,
                memory_usage_pct=(mem_use / mem_cap * 100) if mem_cap > 0 else 0.0,
                disk_pressure=any(c.type == 'DiskPressure' and c.status == 'True' for c in node.status.conditions),
                memory_pressure=any(c.type == 'MemoryPressure' and c.status == 'True' for c in node.status.conditions),
                pod_count=0, # Would need to filter pods by node
                labels=node.metadata.labels,
                annotations=node.metadata.annotations
            ))
        return result

    def _parse_mem(self, mem_str: str) -> int:
        if mem_str.endswith('Ki'): return int(mem_str[:-2]) * 1024
        if mem_str.endswith('Mi'): return int(mem_str[:-2]) * 1024**2
        if mem_str.endswith('Gi'): return int(mem_str[:-2]) * 1024**3
        return int(mem_str)

node_service = NodeService()
