from fastapi import APIRouter, HTTPException, Request, Response
from fastapi.responses import JSONResponse
import httpx
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/github", tags=["github"])

@router.api_route("/{path_name:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_github(request: Request, path_name: str):
    """
    Proxy requests to the GitHub Monitoring Service.
    """
    # If the app calls POST /api/v1/github/connect, path_name is "connect"
    # Microservice NOW expects POST /connect
    url = f"{settings.GITHUB_SERVICE_URL}/{path_name}"
    logger.info(f"Proxying GitHub request: {request.method} {request.url} -> {url}")
    
    # Forward query parameters
    params = dict(request.query_params)
    
    # Forward body for POST/PUT
    body = await request.body()
    
    # Forward headers (excluding host)
    headers = dict(request.headers)
    headers.pop("host", None)
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.request(
                method=request.method,
                url=url,
                params=params,
                content=body,
                headers=headers,
                timeout=10.0
            )
            
            # Forward the status code and content
            if "application/json" in response.headers.get("content-type", ""):
                try:
                    return JSONResponse(
                        content=response.json(),
                        status_code=response.status_code
                    )
                except Exception:
                    pass
            
            return Response(
                content=response.content,
                status_code=response.status_code,
                media_type=response.headers.get("content-type")
            )
        except httpx.RequestError as exc:
            logger.error(f"An error occurred while requesting {exc.request.url!r}: {exc}")
            raise HTTPException(status_code=502, detail=f"Error connecting to GitHub Service: {str(exc)}")
        except Exception as e:
            logger.error(f"Unexpected error in GitHub proxy: {str(e)}")
            raise HTTPException(status_code=500, detail=str(e))
