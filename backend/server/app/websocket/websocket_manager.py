from fastapi import WebSocket
from typing import List, Dict
import json

class WebSocketManager:
    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, channel: str):
        await websocket.accept()
        if channel not in self.active_connections:
            self.active_connections[channel] = []
        self.active_connections[channel].append(websocket)

    def disconnect(self, websocket: WebSocket, channel: str):
        if channel in self.active_connections:
            self.active_connections[channel].remove(websocket)

    async def broadcast(self, message: dict, channel: str):
        if channel in self.active_connections:
            # Create a list to avoid issues if disconnecting during broadcast
            connections = list(self.active_connections[channel])
            for connection in connections:
                try:
                    await connection.send_text(json.dumps(message))
                except Exception as e:
                    # Connection might be dead, it will be handled by the disconnect logic
                    # but we catch it here to avoid breaking the entire broadcast
                    pass

    def has_subscribers(self, channel: str) -> bool:
        return channel in self.active_connections and len(self.active_connections[channel]) > 0

manager = WebSocketManager()
