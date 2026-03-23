from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.services.llm_provider import llm_provider
from app.core.config import settings

router = APIRouter()

class LLMRequest(BaseModel):
    prompt: str
    system_instruction: str = "You are a DevOps assistant. Help the user with their infrastructure queries."

class LLMResponse(BaseModel):
    response: str
    model_used: str

@router.post("/generate", response_model=LLMResponse)
async def generate_llm_response(request: LLMRequest):
    try:
        response_text = await llm_provider.generate_response(request.prompt, request.system_instruction)
        return LLMResponse(
            response=response_text,
            model_used=settings.DEFAULT_MODEL if settings.GEMINI_API_KEY else "ollama/mistral"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
