import google.generativeai as genai
import httpx
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

class LLMProvider:
    def __init__(self):
        if settings.GEMINI_API_KEY:
            genai.configure(api_key=settings.GEMINI_API_KEY)
            self.gemini_model = genai.GenerativeModel(settings.DEFAULT_MODEL)
            logger.info(f"Gemini provider initialized with model {settings.DEFAULT_MODEL}")
        else:
            self.gemini_model = None
            logger.warning("Gemini API key not found. Gemini provider will be unavailable.")

    async def generate_response(self, prompt: str, system_instruction: str = "") -> str:
        # Try Gemini first if available
        if self.gemini_model:
            try:
                response = self.gemini_model.generate_content(
                    f"System: {system_instruction}\n\nUser: {prompt}"
                )
                return response.text
            except Exception as e:
                logger.error(f"Gemini error: {e}")
                
        # Fallback to Ollama
        return await self._generate_ollama(prompt, system_instruction)

    async def _generate_ollama(self, prompt: str, system_instruction: str = "") -> str:
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{settings.OLLAMA_BASE_URL}/api/generate",
                    json={
                        "model": "mistral", # Default fallback
                        "prompt": f"System: {system_instruction}\n\nUser: {prompt}",
                        "stream": False
                    },
                    timeout=60.0
                )
                if response.status_code == 200:
                    return response.json().get("response", "Error: Empty response from Ollama")
                return f"Error: Ollama returned {response.status_code}"
        except Exception as e:
            logger.error(f"Ollama error: {e}")
            return f"Error: Failed to connect to LLM providers. {str(e)}"

llm_provider = LLMProvider()
