from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import asyncio
from datetime import datetime, timedelta
import random
import logging

try:
    from kubernetes import client, config
    KUBERNETES_LIB_AVAILABLE = True
except ImportError:
    KUBERNETES_LIB_AVAILABLE = False

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="K8s Monitor Backend")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global K8s State
k8s_mode = True

@app.on_event("startup")
async def startup_event():
    global k8s_mode
    if not KUBERNETES_LIB_AVAILABLE:
        logger.warning("Kubernetes library not installed. Running in Mock Mode.")
        return

    try:
        config.load_kube_config()
        k8s_mode = True
        logger.info("Successfully loaded kube-config.")
    except Exception as e:
        logger.warning(f"Failed to load kube-config: {e}. Trying in-cluster config...")
        try:
            config.load_incluster_config()
            k8s_mode = True
            logger.info("Successfully loaded in-cluster config.")
        except Exception as e2:
            logger.error(f"Failed to load in-cluster config: {e2}. Defaulting to Mock Mode.")
            k8s_mode = False

# Models
class User(BaseModel):
    id: str
    username: str
    email: str
    permissions: List[str]

class Cluster(BaseModel):
    id: str
    name: str
    region: str
    status: str
    totalNodes: int
    activeAlerts: int
    cpuUsage: float
    memoryUsage: float

class Node(BaseModel):
    id: str
    name: str
    clusterId: str
    status: str
    role: str
    version: str
    cpuUsage: float
    memoryUsage: float
    diskPressure: float
    networkIo: float

class Alert(BaseModel):
    id: str
    title: str
    message: str
    severity: str
    clusterId: str
    resource: str
    timestamp: datetime

# Helper Functions
def parse_cpu(quantity: str) -> float:
    """Returns CPU in cores (float)"""
    if quantity.endswith('n'):
        return float(quantity[:-1]) / 1e9
    elif quantity.endswith('m'):
        return float(quantity[:-1]) / 1e3
    elif quantity.endswith('u'):
        return float(quantity[:-1]) / 1e6
    return float(quantity)

def parse_memory(quantity: str) -> float:
    """Returns Memory in Bytes (float)"""
    if quantity.endswith('Ki'):
        return float(quantity[:-2]) * 1024
    elif quantity.endswith('Mi'):
        return float(quantity[:-2]) * 1024 * 1024
    elif quantity.endswith('Gi'):
        return float(quantity[:-2]) * 1024 * 1024 * 1024
    elif quantity.endswith('Ti'):
        return float(quantity[:-2]) * 1024 * 1024 * 1024 * 1024
    return float(quantity)

# Mock Data (Fallback)
clusters_db = [
    Cluster(id="c1", name="prod-us-east-1", region="us-east-1", status="healthy", totalNodes=50, activeAlerts=0, cpuUsage=45.5, memoryUsage=60.2),
]

# Endpoints

@app.post("/auth/login", response_model=User)
async def login(credentials: dict):
    await asyncio.sleep(0.5)
    if credentials.get("username") == "admin" and credentials.get("password") == "password":
        return User(id="1", username="admin", email="admin@example.com", permissions=["admin"])
    raise HTTPException(status_code=401, detail="Invalid credentials")

@app.get("/clusters", response_model=List[Cluster])
async def get_clusters():
    if k8s_mode:
        try:
            # List contexts to simulate clusters
            contexts, active_context = config.list_kube_config_contexts()
            logger.info(f"Loaded contexts: {contexts}")
            if not contexts:
                logger.warning("No contexts found in kubeconfig")
                # If no contexts found, try to use the loaded config as a single cluster
                return [Cluster(id="current", name="current-cluster", region="local", status="healthy", totalNodes=1, activeAlerts=0, cpuUsage=0.0, memoryUsage=0.0)]
            
            result = []
            for ctx in contexts:
                name = ctx['name']
                logger.info(f"Processing context: {name}")
                try:
                    # Switch context logic (simplified for local demo)
                    # We will reuse the default loaded config if context matches or just try to use it
                    # But for correct multi-cluster, we need new_client_from_config
                    
                    try:
                        # Load config for context, get client configuration, disable SSL, then create client
                        c = client.Configuration()
                        c.verify_ssl = False
                        c.assert_hostname = False
                        config.load_kube_config(context=name, client_configuration=c)
                        
                        api_cli = client.ApiClient(configuration=c)
                        v1 = client.CoreV1Api(api_client=api_cli)
                        cust = client.CustomObjectsApi(api_client=api_cli)
                    except:
                        # Fallback to default but disable SSL
                        c = client.Configuration.get_default_copy()
                        c.verify_ssl = False
                        c.assert_hostname = False
                        client.Configuration.set_default(c)
                        v1 = client.CoreV1Api()
                        cust = client.CustomObjectsApi()

                    # Get Nodes
                    nodes_list = v1.list_node().items
                    total_nodes = len(nodes_list)
                    
                    total_cpu_cap = 0.0
                    total_mem_cap = 0.0
                    total_cpu_usage = 0.0
                    total_mem_usage = 0.0

                    # Calculate Capacity
                    for n in nodes_list:
                        alloc = n.status.allocatable
                        total_cpu_cap += parse_cpu(alloc.get('cpu', '0'))
                        total_mem_cap += parse_memory(alloc.get('memory', '0Ki'))

                    # Calculate Usage (if metrics available)
                    try:
                        metrics_list = cust.list_cluster_custom_object("metrics.k8s.io", "v1beta1", "nodes")
                        for m in metrics_list.get('items', []):
                            usage = m['usage']
                            total_cpu_usage += parse_cpu(usage.get('cpu', '0'))
                            total_mem_usage += parse_memory(usage.get('memory', '0Ki'))
                    except:
                        pass # Metrics not available

                    cpu_pct = (total_cpu_usage / total_cpu_cap * 100) if total_cpu_cap > 0 else 0.0
                    mem_pct = (total_mem_usage / total_mem_cap * 100) if total_mem_cap > 0 else 0.0

                    # Count Alerts (Warnings)
                    active_alerts = 0
                    try:
                        events = v1.list_event_for_all_namespaces(field_selector='type=Warning')
                        active_alerts = len(events.items)
                    except:
                        pass

                    result.append(Cluster(
                        id=name,
                        name=name,
                        region="local" if "kind" in name else "unknown",
                        status="healthy", 
                        totalNodes=total_nodes,
                        activeAlerts=active_alerts,
                        cpuUsage=cpu_pct,
                        memoryUsage=mem_pct
                    ))

                except Exception as e:
                    logger.error(f"Error processing cluster {name}: {e}")
                    # Continue to next cluster, don't return mock
                    continue
            return result
        except Exception as e:
            logger.error(f"Error listing clusters: {e}")
            raise HTTPException(status_code=500, detail=str(e))
    return []

@app.get("/clusters/{cluster_id}/nodes", response_model=List[Node])
async def get_nodes(cluster_id: str):
    if k8s_mode:
        try:
            # Switch context if possible, or just use current
            # For simplicity in this demo, we assume the active context is what we want
            # or we create a client for that context.
            # api = client.CoreV1Api(api_client=config.new_client_from_config(context=cluster_id)) 
            # Note: new_client_from_config might fail if context not found.
            
            # Load config with flexible SSL handling
            try:
                config.load_kube_config()
                c = client.Configuration.get_default_copy()
                c.verify_ssl = False
                # c.assert_hostname = False # Optional, sometimes needed
                client.Configuration.set_default(c)
                logger.info("Loaded kube-config with SSL verification disabled.")
            except Exception as e:
                logger.warning(f"Failed to load kube-config: {e}")

            # Try to load specific context
            try:
                if cluster_id != "local":
                    try:
                        c = client.Configuration()
                        c.verify_ssl = False
                        c.assert_hostname = False
                        config.load_kube_config(context=cluster_id, client_configuration=c)
                        api_client = client.ApiClient(configuration=c)
                        
                        v1 = client.CoreV1Api(api_client=api_client)
                        cust = client.CustomObjectsApi(api_client=api_client)
                    except Exception as e:
                        logger.error(f"Failed to load specific context {cluster_id}: {e}")
                         # Fallback to default but disable SSL
                        c = client.Configuration.get_default_copy()
                        c.verify_ssl = False
                        c.assert_hostname = False
                        client.Configuration.set_default(c)
                        v1 = client.CoreV1Api()
                        cust = client.CustomObjectsApi()
                else:
                    c = client.Configuration.get_default_copy()
                    c.verify_ssl = False
                    c.assert_hostname = False
                    client.Configuration.set_default(c)
                    v1 = client.CoreV1Api()
                    cust = client.CustomObjectsApi()
            except:
                v1 = client.CoreV1Api()
                cust = client.CustomObjectsApi()

            nodes = v1.list_node()
            
            # Fetch Metrics (if available)
            node_metrics = {}
            try:
                metrics = cust.list_cluster_custom_object("metrics.k8s.io", "v1beta1", "nodes")
                for m in metrics.get('items', []):
                    name = m['metadata']['name']
                    usage = m['usage']
                    node_metrics[name] = {'cpu': usage['cpu'], 'memory': usage['memory']}
            except Exception as e:
                logger.warning(f"Metrics API not available: {e}")

            result = []
            for n in nodes.items:
                # Parse status
                status = "unknown"
                for condition in n.status.conditions:
                    if condition.type == "Ready":
                        status = "ready" if condition.status == "True" else "notReady"
                        break
                
                    # Parse Capacity
                    cpu_cap = parse_cpu(n.status.allocatable.get('cpu', '1'))
                    mem_cap = parse_memory(n.status.allocatable.get('memory', '1Ki'))

                    # Calculate Usage %
                    cpu_usage_pct = 0.0
                    mem_usage_pct = 0.0
                    
                    if n.metadata.name in node_metrics:
                        m = node_metrics[n.metadata.name]
                        # Metrics in API are strings too
                        usage_cpu = parse_cpu(m['cpu'])
                        usage_mem = parse_memory(m['memory'])
                        
                        if cpu_cap > 0:
                            cpu_usage_pct = (usage_cpu / cpu_cap) * 100
                        if mem_cap > 0:
                            mem_usage_pct = (usage_mem / mem_cap) * 100
                
                result.append(Node(
                    id=n.metadata.uid,
                    name=n.metadata.name,
                    clusterId=cluster_id,
                    status=status,
                    role="control-plane" if "control-plane" in n.metadata.labels.get("node-role.kubernetes.io/control-plane", "") else "worker",
                    version=n.status.node_info.kubelet_version,
                    cpuUsage=cpu_usage_pct,
                    memoryUsage=mem_usage_pct,
                    diskPressure=0.0,
                    networkIo=0.0
                ))
            return result


        except Exception as e:
            logger.error(f"Error getting nodes: {e}")
            raise HTTPException(status_code=500, detail=f"Failed to fetch nodes: {str(e)}")
            
    return []

@app.get("/alerts", response_model=List[Alert])
async def get_alerts():
    if k8s_mode:
        try:
            # Ensure SSL is disabled for default client too
            # For default client, we modify the global default or create a new one
            c = client.Configuration.get_default_copy()
            c.verify_ssl = False
            c.assert_hostname = False
            client.Configuration.set_default(c)
            
            # Re-initialize client with new default
            v1 = client.CoreV1Api(client.ApiClient(configuration=c))
            events = v1.list_event_for_all_namespaces(field_selector='type=Warning')
            
            result = []
            for e in events.items:
                result.append(Alert(
                    id=e.metadata.uid,
                    title=e.reason,
                    message=e.message,
                    severity="warning",
                    clusterId="current",
                    resource=f"{e.involved_object.kind}/{e.involved_object.name}",
                    timestamp=e.last_timestamp or e.event_time or datetime.now()
                ))
            return result
        except Exception as e:
            logger.error(f"Error fetching alerts: {e}")
            return []
    
    return []

class Namespace(BaseModel):
    name: str
    status: str
    totalPods: int
    runningPods: int
    failedPods: int

class Workload(BaseModel):
    id: str
    name: str
    type: str # deployment, statefulset, daemonset
    namespace: str
    replicas: int
    availableReplicas: int
    image: str
    lastUpdate: datetime
    status: str

@app.get("/clusters/{cluster_id}/namespaces", response_model=List[Namespace])
async def get_namespaces(cluster_id: str):
    if k8s_mode:
        try:
             # Try to load specific context
            try:
                c = client.Configuration()
                c.verify_ssl = False
                c.assert_hostname = False
                config.load_kube_config(context=cluster_id, client_configuration=c)
                api_client = client.ApiClient(configuration=c)
                v1 = client.CoreV1Api(api_client=api_client)
            except:
                c = client.Configuration.get_default_copy()
                c.verify_ssl = False
                c.assert_hostname = False
                client.Configuration.set_default(c)
                v1 = client.CoreV1Api()
            
            ns_list = v1.list_namespace()
            result = []
            # Optimized: List all pods once to avoid N API calls
            all_pods = v1.list_pod_for_all_namespaces().items
            pods_by_ns = {}
            for p in all_pods:
                ns = p.metadata.namespace
                if ns not in pods_by_ns:
                    pods_by_ns[ns] = {'total': 0, 'running': 0, 'failed': 0}
                
                pods_by_ns[ns]['total'] += 1
                if p.status.phase == 'Running':
                    pods_by_ns[ns]['running'] += 1
                elif p.status.phase == 'Failed':
                    pods_by_ns[ns]['failed'] += 1

            result = []
            for ns in ns_list.items:
                stats = pods_by_ns.get(ns.metadata.name, {'total': 0, 'running': 0, 'failed': 0})
                result.append(Namespace(
                    name=ns.metadata.name,
                    status=ns.status.phase,
                    totalPods=stats['total'],
                    runningPods=stats['running'],
                    failedPods=stats['failed']
                ))
            return result
        except Exception as e:
            logger.error(f"Error getting namespaces: {e}")
            raise HTTPException(status_code=500, detail=f"Failed to fetch namespaces: {str(e)}")
            
    return []

@app.get("/clusters/{cluster_id}/namespaces/{namespace}/workloads", response_model=List[Workload])
async def get_workloads(cluster_id: str, namespace: str):
    if k8s_mode:
        try:
             # Try to load specific context
            try:
                c = client.Configuration()
                c.verify_ssl = False
                c.assert_hostname = False
                config.load_kube_config(context=cluster_id, client_configuration=c)
                api_client = client.ApiClient(configuration=c)
                apps_v1 = client.AppsV1Api(api_client=api_client)
            except:
                 c = client.Configuration.get_default_copy()
                 c.verify_ssl = False
                 c.assert_hostname = False
                 client.Configuration.set_default(c)
                 apps_v1 = client.AppsV1Api()

            deployments = apps_v1.list_namespaced_deployment(namespace)
            result = []
            for d in deployments.items:
                replicas = d.status.replicas or 0
                available = d.status.available_replicas or 0
                image = d.spec.template.spec.containers[0].image
                
                result.append(Workload(
                    id=d.metadata.uid,
                    name=d.metadata.name,
                    type="deployment",
                    namespace=namespace,
                    replicas=replicas,
                    availableReplicas=available,
                    image=image,
                    lastUpdate=d.metadata.creation_timestamp,
                    status="Running" if replicas == available else "Degraded"
                ))
            return result
        except Exception as e:
             logger.error(f"Error getting workloads: {e}")
             raise HTTPException(status_code=500, detail=f"Failed to fetch workloads: {str(e)}")

    return []

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
