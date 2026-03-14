from fastapi import APIRouter, HTTPException, Query
from app.services.pod_service import pod_service
from app.models.pod_models import PodDetail
from typing import List, Optional

router = APIRouter(prefix="/pods", tags=["pods"])

@router.get("", response_model=List[PodDetail])
async def get_pods(namespace: Optional[str] = Query(None)):
    try:
        return await pod_service.get_pods(namespace=namespace)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
