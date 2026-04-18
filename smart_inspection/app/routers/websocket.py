from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from jose import JWTError, jwt

from ..config import settings
from ..core.ws_manager import manager

router = APIRouter()


def _verify_token(token: str) -> str | None:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload.get("sub")
    except JWTError:
        return None


@router.websocket("/ws/sites/{site_id}/live")
async def site_live(
    site_id: str,
    ws: WebSocket,
    token: str = Query(...),
):
    user = _verify_token(token)
    if not user:
        await ws.close(code=4001)
        return

    await manager.connect(site_id, ws)
    try:
        await ws.send_json({"type": "connected", "site_id": site_id})
        while True:
            await ws.receive_text()  # keep-alive ping 수신
    except WebSocketDisconnect:
        manager.disconnect(site_id, ws)
