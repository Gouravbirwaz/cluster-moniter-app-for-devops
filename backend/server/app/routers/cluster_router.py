from datetime import datetime
from app.core.config import settings
from fastapi import APIRouter, Depends, HTTPException
from app.services.cluster_service import cluster_service
from app.models.cluster_models import ClusterOverview

router = APIRouter(prefix="/cluster", tags=["cluster"])

@router.get("/overview", response_model=ClusterOverview)
async def get_cluster_overview():
    try:
        return await cluster_service.get_overview()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
