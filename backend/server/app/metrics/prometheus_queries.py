# Prometheus Queries for K8s monitoring

CLUSTER_CPU_USAGE = "(sum(rate(container_cpu_usage_seconds_total[5m])) or (sum(rate(node_cpu_seconds_total{mode!='idle'}[5m]))))"
CLUSTER_MEM_USAGE = "(sum(container_memory_working_set_bytes) or (sum(node_memory_MemTotal_bytes) - sum(node_memory_MemFree_bytes)))"

NODE_CPU_CAPACITY = "(sum(kube_node_status_allocatable{resource='cpu'}) or sum(machine_cpu_cores) or count(node_cpu_seconds_total{mode='idle'}))"
NODE_MEM_CAPACITY = "(sum(kube_node_status_allocatable{resource='memory'}) or sum(machine_memory_bytes) or sum(node_memory_MemTotal_bytes))"

NODE_CPU_USAGE = "sum by (node) (rate(container_cpu_usage_seconds_total[5m]))"
NODE_MEM_USAGE = "sum by (node) (container_memory_working_set_bytes)"

POD_CPU_USAGE = "sum by (pod, namespace) (rate(container_cpu_usage_seconds_total{container!=''}[5m]))"
POD_MEM_USAGE = "sum by (pod, namespace) (container_memory_working_set_bytes{container!=''})"

ALERTS_FIRING_COUNT = "count(ALERTS{alertstate='firing'})"
