import httpx
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

class PrometheusClient:
    def __init__(self):
        self.url = f"{settings.PROMETHEUS_URL}/api/v1/query"
        self.client = httpx.AsyncClient(timeout=10.0)

    async def query(self, query_str: str) -> dict:
        try:
            response = await self.client.get(self.url, params={"query": query_str})
            response.raise_for_status()
            try:
                return response.json()
            except Exception as json_err:
                logger.error(f"Failed to parse Prometheus JSON response: {json_err}. Content: {response.text[:200]}")
                raise json_err
        except Exception as e:
            logger.error(f"Prometheus query failed: {query_str} -> {type(e).__name__}: {e}")
            return {"status": "error", "data": {"resultType": "vector", "result": []}}

    async def close(self):
        await self.client.aclose()

prometheus_client = PrometheusClient()
