from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.routers import github_router
from app.webhooks import handler as webhook_handler
from app.websocket.websocket_manager import manager
from app.database import engine, Base
from app.models import github_models
import logging
import uvicorn

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title=settings.APP_NAME)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(github_router.router)
app.include_router(webhook_handler.router)

@app.on_event("startup")
def startup_event():
    Base.metadata.create_all(bind=engine)
    logger.info("Database initialized")

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "github-monitoring"}

@app.websocket("/ws/repo/{repo_owner}/{repo_name}")
async def repo_websocket_endpoint(websocket: WebSocket, repo_owner: str, repo_name: str):
    channel = f"repo_{repo_owner}_{repo_name}"
    await manager.connect(websocket, channel)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, channel)

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=settings.PORT, reload=True)
