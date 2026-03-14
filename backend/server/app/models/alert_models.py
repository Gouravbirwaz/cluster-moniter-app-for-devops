from pydantic import BaseModel
from typing import Optional

class AlertDetail(BaseModel):
    message: str
    reason: str
    type: str
    namespace: str
    timestamp: str
    severity: str # 'Normal' or 'Warning'
