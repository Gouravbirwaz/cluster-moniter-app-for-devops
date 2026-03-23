import asyncio
import json
import logging

# Silence verbose library logs
for logger_name in ["urllib3", "urllib3.connectionpool", "kubernetes", "kubernetes.client.rest"]:
    logging.getLogger(logger_name).setLevel(logging.ERROR)
    logging.getLogger(logger_name).propagate = False

import os
import redis.asyncio as redis
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title=settings.PROJECT_NAME)

# CORS Middleware - Disable credentials for wildcard origin to fix WebSocket 403/closure
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
        logger.info(f"New client connected. Total clients: {len(self.active_connections)}")

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        logger.info(f"Client disconnected. Total clients: {len(self.active_connections)}")

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except Exception as e:
                logger.error(f"Error broadcasting to client: {e}")

manager = ConnectionManager()

async def redis_listener():
    try:
        r = redis.Redis(
            host=settings.REDIS_HOST, 
            port=settings.REDIS_PORT, 
            decode_responses=True,
            socket_timeout=2.0,
            socket_connect_timeout=2.0
        )
        # Check connection once before starting
        await r.ping()
        logger.info(f"Redis listener started on {settings.REDIS_HOST}:{settings.REDIS_PORT}")
        
        # Create group if not exists
        try:
            await r.xgroup_create("events", "websocket_group", id="0", mkstream=True)
        except Exception:
            pass # Group already exists
        
        while True:
            # Read from stream
            messages = await r.xreadgroup("websocket_group", "ws_consumer", {"events": ">"}, count=10, block=1000)
            for stream, entries in messages:
                for msg_id, payload in entries:
                    # payload is a dict like {"payload": "{\"type\": \"...\", ...}"}
                    if "payload" in payload:
                        # Extract and broadcast the nested JSON directly to avoid double encoding
                        logger.info(f"Broadcasting event: {payload['payload'][:100]}...")
                        await manager.broadcast(payload["payload"])
                    else:
                        # Fallback for events with different structure
                        await manager.broadcast(json.dumps(payload))
                    
                    # Acknowledge message
                    await r.xack("events", "websocket_group", msg_id)
            
            await asyncio.sleep(0.1)
    except Exception as e:
        logger.error(f"Redis listener error: {e}")
    finally:
        await r.close()

@app.on_event("startup")
async def startup_event():
    asyncio.create_task(redis_listener())

@app.websocket("/api/v1/ws/events")

async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            # Keep connection alive
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket)

@app.get("/health")
def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8009)
