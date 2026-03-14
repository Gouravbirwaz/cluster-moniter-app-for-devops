from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.websocket.websocket_manager import manager
from app.kubernetes.resource_watcher import resource_watcher
import logging
import asyncio
import json
import websockets
from app.core.config import settings

logger = logging.getLogger(__name__)
router = APIRouter()

@router.websocket("/ws/monitor")
async def websocket_endpoint(websocket: WebSocket):
    channel = "cluster_mon"
    await manager.connect(websocket, channel)
    logger.info(f"Client connected to {channel} stream")
    
    # Send initial confirmation
    await websocket.send_text(json.dumps({
        "type": "CONNECTION_ESTABLISHED",
        "message": "Real-time monitoring active"
    }))
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, channel)
        logger.info(f"Client disconnected from {channel} stream")
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        manager.disconnect(websocket, channel)

@router.websocket("/ws/logs/{namespace}/{pod_name}")
async def log_websocket_endpoint(websocket: WebSocket, namespace: str, pod_name: str, container: str = None):
    channel = f"logs_{namespace}_{pod_name}"
    await manager.connect(websocket, channel)
    logger.info(f"Client connected to log stream for {pod_name}")
    
    # Start the log watcher in the background if not already running
    # This is a bit simplified; in a production app we'd track active watchers
    log_task = asyncio.create_task(resource_watcher.watch_pod_logs(namespace, pod_name, container))
    
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, channel)
        log_task.cancel()
        logger.info(f"Client disconnected from log stream for {pod_name}")
    except Exception as e:
        logger.error(f"Log WebSocket error: {e}")
        manager.disconnect(websocket, channel)
        log_task.cancel()

@router.websocket("/ws/repo/{owner}/{repo}")
async def proxy_repo_websocket(websocket: WebSocket, owner: str, repo: str):
    """
    Proxy WebSocket connections to the GitHub Monitoring Service.
    """
    await websocket.accept()
    
    # Replace http with ws for the service URL
    ws_url = settings.GITHUB_SERVICE_URL.replace("http://", "ws://").replace("https://", "wss://")
    target_url = f"{ws_url}/ws/repo/{owner}/{repo}"
    
    logger.info(f"Proxying WebSocket: {websocket.url.path} -> {target_url}")
    
    try:
        async with websockets.connect(target_url) as target_ws:
            async def forward_to_client():
                try:
                    async for message in target_ws:
                        await websocket.send_text(message)
                except Exception as e:
                    logger.debug(f"Target to client forward stopped: {e}")
            
            async def forward_to_target():
                try:
                    while True:
                        message = await websocket.receive_text()
                        await target_ws.send(message)
                except Exception as e:
                    logger.debug(f"Client to target forward stopped: {e}")

            # Run both forwarding tasks concurrently
            await asyncio.gather(forward_to_client(), forward_to_target())
            
    except Exception as e:
        logger.error(f"GitHub WebSocket proxy error: {e}")
    finally:
        try:
            await websocket.close()
        except:
            pass
        logger.info(f"GitHub WebSocket disconnected: {owner}/{repo}")
