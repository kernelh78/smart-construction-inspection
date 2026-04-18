from collections import defaultdict
from fastapi import WebSocket


class ConnectionManager:
    def __init__(self):
        # site_id -> list of connected WebSockets
        self._connections: dict[str, list[WebSocket]] = defaultdict(list)

    async def connect(self, site_id: str, ws: WebSocket) -> None:
        await ws.accept()
        self._connections[site_id].append(ws)

    def disconnect(self, site_id: str, ws: WebSocket) -> None:
        self._connections[site_id].discard if hasattr(self._connections[site_id], 'discard') else None
        try:
            self._connections[site_id].remove(ws)
        except ValueError:
            pass

    async def broadcast(self, site_id: str, message: dict) -> None:
        dead = []
        for ws in self._connections.get(site_id, []):
            try:
                await ws.send_json(message)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect(site_id, ws)

    async def broadcast_all(self, message: dict) -> None:
        for site_id in list(self._connections):
            await self.broadcast(site_id, message)


manager = ConnectionManager()
