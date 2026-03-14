from fastapi import APIRouter, HTTPException
from app.services.alert_service import alert_service
from app.models.alert_models import AlertDetail
from typing import List, Optional

router = APIRouter(prefix="/alerts", tags=["alerts"])

@router.get("", response_model=List[AlertDetail])
async def get_alerts(namespace: Optional[str] = None):
    try:
        return await alert_service.get_alerts(namespace)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
