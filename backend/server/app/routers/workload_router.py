from fastapi import APIRouter, HTTPException, Query
from app.services.workload_service import workload_service
from app.models.workload_models import WorkloadDetail, NamespaceDetail
from typing import List, Optional

router = APIRouter(prefix="/workloads", tags=["workloads"])

@router.get("", response_model=List[WorkloadDetail])
async def get_workloads(namespace: Optional[str] = Query(None)):
    try:
        return await workload_service.get_workloads(namespace=namespace)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/namespaces", response_model=List[NamespaceDetail])
async def get_namespaces():
    try:
        return await workload_service.get_namespaces()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
