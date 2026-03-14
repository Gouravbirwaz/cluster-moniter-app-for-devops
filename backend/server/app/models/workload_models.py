from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel

class WorkloadBase(BaseModel):
    name: str
    namespace: str
    type: str  # deployment, statefulset, daemonset
    replicas: int
    available_replicas: int
    status: str

class WorkloadDetail(WorkloadBase):
    id: str
    image: str
    labels: dict
    creation_timestamp: datetime
    selector: dict
    strategy: Optional[str]

class NamespaceDetail(BaseModel):
    name: str
    status: str
    creation_timestamp: datetime
    labels: Optional[dict] = {}
    total_pods: int = 0
    running_pods: int = 0
    failed_pods: int = 0
    resource_quota: Optional[dict] = None
