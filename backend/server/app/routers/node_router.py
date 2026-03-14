from fastapi import APIRouter, HTTPException
from app.services.node_service import node_service
from app.models.node_models import NodeDetail
from typing import List

router = APIRouter(prefix="/nodes", tags=["nodes"])

@router.get("", response_model=List[NodeDetail])
async def get_nodes():
    try:
        return await node_service.get_nodes()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
