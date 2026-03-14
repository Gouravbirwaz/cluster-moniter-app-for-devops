from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel

class ClusterBase(BaseModel):
    name: str
    region: str
    status: str
    kubernetes_version: str

class ClusterOverview(ClusterBase):
    id: str
    total_nodes: int
    ready_nodes: int
    total_pods: int
    running_pods: int
    pending_pods: int
    failed_pods: int
    cpu_usage: float
    memory_usage: float

class ClusterStats(BaseModel):
    timestamp: datetime
    cpu_usage_cores: float
    memory_usage_bytes: int
    pod_count: int
    node_count: int
