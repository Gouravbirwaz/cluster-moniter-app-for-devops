from fastapi import WebSocket
from typing import Dict, List, Set, Any
import json
import logging

logger = logging.getLogger(__name__)

class WebSocketManager:
    def __init__(self):
        # channel_name -> set of websockets
        self.active_connections: Dict[str, Set[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, channel: str):
        await websocket.accept()
        if channel not in self.active_connections:
            self.active_connections[channel] = set()
        self.active_connections[channel].add(websocket)
        logger.info(f"Client connected to channel: {channel}")

    def disconnect(self, websocket: WebSocket, channel: str):
        if channel in self.active_connections:
            self.active_connections[channel].discard(websocket)
            if not self.active_connections[channel]:
                del self.active_connections[channel]
        logger.info(f"Client disconnected from channel: {channel}")

    async def broadcast(self, message: Any, channel: str):
        if channel not in self.active_connections:
            return

        message_text = json.dumps(message)
        disconnected = set()
        
        for websocket in self.active_connections[channel]:
            try:
                await websocket.send_text(message_text)
            except Exception as e:
                logger.error(f"Error broadcasting to 1 client on {channel}: {e}")
                disconnected.add(websocket)
        
        for ws in disconnected:
            self.disconnect(ws, channel)

    def has_subscribers(self, channel: str) -> bool:
        return channel in self.active_connections and len(self.active_connections[channel]) > 0

manager = WebSocketManager()
