import httpx
import json
import logging
from app.core.config import settings

logger = logging.getLogger(__name__)

class ReasoningEngine:
    def __init__(self):
        self.llm_url = settings.LLM_SERVICE_URL

    async def _fetch_cluster_context(self) -> str:
        """Fetch live cluster overview from backend server as fallback context."""
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                url = f"{settings.BACKEND_SERVER_URL}/api/v1/cluster/overview"
                resp = await client.get(url)
                if resp.status_code == 200:
                    data = resp.json()
                    return json.dumps(data, indent=2)
        except Exception as e:
            logger.warning(f"Failed to fetch live cluster context: {e}")
        return "{}"

    async def analyze_query(self, user_query: str, context: dict = None) -> dict:
        # 1. Use provided context or fetch live fallback
        if not context:
            logger.info("No context provided, fetching live cluster context...")
            live_context_str = await self._fetch_cluster_context()
        else:
            live_context_str = json.dumps(context, indent=2)

        system_prompt = f"""
        You are Agent-1, a powerful DevOps Assistant. You have real-time access to the Kubernetes cluster and GitHub repositories.
        
        CURRENT CLUSTER CONTEXT:
        {live_context_str}
        
        INSTRUCTIONS:
        1. If the user asks about cluster health, metrics, or resource status:
           - Use the CURRENT CLUSTER CONTEXT provided above to give specific, technical answers.
           - Be proactive: if you see failed pods or high CPU in the context, mention it.
           
        2. If the user asks for an ACTION (e.g., "restart pod", "scale", "delete"):
           - You DO NOT perform actions yourself. You delegate to Agent-2 (the Cluster Guardian).
           - Identify the intent and required parameters.
           - Respond with a clear technical explanation AND a JSON block at the end for Agent-2.
           
           Example intent JSON: {{"intent": "restart_pod", "namespace": "default", "pod_name": "api-v1-xxx"}}
           
        3. If the data needed is not in the context, explain what you see and what might be missing.
        
        Always be technical, concise, and helpful.
        """
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.llm_url}/generate",
                    json={
                        "prompt": user_query,
                        "system_instruction": system_prompt
                    },
                    timeout=30.0
                )
                if response.status_code == 200:
                    data = response.json()
                    return {"status": "success", "content": data["response"]}
                return {"status": "error", "message": f"LLM service returned {response.status_code}"}
        except Exception as e:
            logger.error(f"Reasoning engine error: {e}")
            return {"status": "error", "message": str(e)}

    def extract_intent(self, text: str) -> dict:
        # Simple heuristic to find JSON in LLM response
        try:
            start = text.find('{')
            end = text.rfind('}') + 1
            if start != -1 and end != -1:
                return json.loads(text[start:end])
        except Exception:
            pass
        return None

reasoning_engine = ReasoningEngine()
