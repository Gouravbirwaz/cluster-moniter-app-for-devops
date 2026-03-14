from fastapi import FastAPI, Depends, Request
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.routers import cluster_router, node_router, pod_router, workload_router, websocket_router, alert_router, github_router, vault_router
from app.metrics.prometheus_client import prometheus_client
from app.kubernetes.resource_watcher import resource_watcher
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Middleware to log requests
@app.middleware("http")
async def log_requests(request: Request, call_next):
    logger.info(f"Incoming request: {request.method} {request.url.path}")
    response = await call_next(request)
    logger.info(f"Response status: {response.status_code}")
    return response

# Routers
app.include_router(cluster_router.router, prefix=settings.API_V1_STR)
app.include_router(node_router.router, prefix=settings.API_V1_STR)
app.include_router(pod_router.router, prefix=settings.API_V1_STR)
app.include_router(workload_router.router, prefix=settings.API_V1_STR)
app.include_router(websocket_router.router, prefix=settings.API_V1_STR)
app.include_router(alert_router.router, prefix=settings.API_V1_STR)
app.include_router(github_router.router, prefix=settings.API_V1_STR)
app.include_router(vault_router.router, prefix=settings.API_V1_STR)

# Fallback for old app versions or direct calls
app.include_router(github_router.router)
app.include_router(vault_router.router)

@app.on_event("startup")
async def startup_event():
    logger.info("Starting up K8s Monitoring Platform...")
    await resource_watcher.start_all()

@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Shutting down...")
    await prometheus_client.close()

@app.get("/")
async def root():
    return {"message": "K8s Monitoring Control Center API", "version": "1.0.0"}
