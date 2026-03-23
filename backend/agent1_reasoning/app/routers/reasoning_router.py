from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.services.reasoning_engine import reasoning_engine

router = APIRouter()

class QueryRequest(BaseModel):
    query: str
    context: dict = {}

from typing import Optional

class QueryResponse(BaseModel):
    answer: str
    intent: Optional[dict] = None

@router.post("/process", response_model=QueryResponse)
async def process_query(request: QueryRequest):
    result = await reasoning_engine.analyze_query(request.query, request.context)
    if result["status"] == "error":
        raise HTTPException(status_code=500, detail=result["message"])
    
    content = result["content"]
    intent = reasoning_engine.extract_intent(content)
    
    return QueryResponse(answer=content, intent=intent)
