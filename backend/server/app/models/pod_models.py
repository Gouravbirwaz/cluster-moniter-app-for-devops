from datetime import datetime
from typing import Dict, List, Optional
from pydantic import BaseModel

class PodBase(BaseModel):
    name: str
    namespace: str
    status: str
    node_name: str
    restart_count: int
    age_seconds: int

class PodDetail(PodBase):
    id: str
    ip: str
    image: str
    cpu_usage_cores: float
    memory_usage_bytes: int
    containers: List[str]
    labels: Dict[str, str]
    events: List[str]
    start_time: Optional[datetime]
