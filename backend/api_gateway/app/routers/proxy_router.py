from fastapi import APIRouter, Request, Depends, HTTPException
import httpx
import logging
from app.core.config import settings
from app.core.auth import get_current_user

router = APIRouter()
logger = logging.getLogger(__name__)

async def proxy_request(service_url: str, path: str, request: Request):
    url = f"{service_url}{path}"
    async with httpx.AsyncClient(timeout=10.0) as client:
        method = request.method
        content = await request.body()
        headers = dict(request.headers)
        # Remove host header to avoid conflicts
        if "host" in headers:
            del headers["host"]
            
        try:
            response = await client.request(
                method, url, content=content, headers=headers, params=request.query_params, timeout=10.0
            )
            # If the service returns an error, we should pass it through or wrap it nicely
            if response.status_code >= 400:
                logger.warning(f"Service {url} returned {response.status_code}")
            
            return response.json()
        except HTTPException as e:
            raise e
        except Exception as e:
            logger.error(f"Proxy error to {url}: {e}")
            raise HTTPException(
                status_code=502, 
                detail={
                    "error": "Service connection failed",
                    "url": url,
                    "details": str(e)
                }
            )

@router.post("/ai/process")
async def process_ai(request: Request, user=Depends(get_current_user)):
    return await proxy_request(settings.AGENT1_SERVICE_URL, "/api/v1/ai/process", request)


@router.get("/metrics/cluster")
async def get_metrics(request: Request):
    return await proxy_request(settings.METRICS_SERVICE_URL, "/api/v1/metrics/cluster", request)

@router.post("/guardian/execute")
async def execute_command(request: Request, user=Depends(get_current_user)):
    return await proxy_request(settings.CLUSTER_GUARDIAN_URL, "/api/v1/guardian/execute", request)



# GitHub and Vault passthrough
@router.api_route("/github/{path:path}", methods=["GET", "POST", "DELETE", "PUT"])
async def github_proxy(path: str, request: Request, user=Depends(get_current_user)):
    return await proxy_request(settings.GITHUB_SERVICE_URL, f"/api/v1/github/{path}", request)


@router.api_route("/vault/{path:path}", methods=["GET", "POST", "DELETE", "PUT"])
async def vault_proxy(path: str, request: Request, user=Depends(get_current_user)):
    return await proxy_request(settings.VAULT_SERVICE_URL, f"/api/v1/vault/{path}", request)

