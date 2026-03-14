from typing import Dict, List, Optional
from pydantic import BaseModel

class NodeBase(BaseModel):
    name: str
    status: str
    role: str
    version: str
    internal_ip: str

class NodeDetail(NodeBase):
    id: str
    cpu_capacity: float
    memory_capacity_bytes: int
    disk_capacity_bytes: int
    cpu_usage_pct: float
    memory_usage_pct: float
    disk_pressure: bool
    memory_pressure: bool
    pod_count: int
    labels: Dict[str, str]
    annotations: Dict[str, str]
