from fastapi import APIRouter, Request, Header, HTTPException
from app.websocket.websocket_manager import manager
import hmac
import hashlib
import json
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/webhooks", tags=["webhooks"])

def verify_signature(payload: bytes, signature: str, secret: str):
    if not secret:
        return True # Or handle as error
    
    expected_signature = "sha256=" + hmac.new(
        secret.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()
    
    return hmac.compare_digest(expected_signature, signature)

@router.post("/github")
async def github_webhook(
    request: Request,
    x_github_event: str = Header(...),
    x_hub_signature_256: str = Header(None)
):
    payload = await request.body()
    # In a real app, verify signature here if secret is configured
    
    try:
        data = json.loads(payload)
        repo_full_name = data.get("repository", {}).get("full_name")
        if not repo_full_name:
            return {"status": "ignored", "reason": "no repository info"}

        channel = f"repo_{repo_full_name.replace('/', '_')}"
        
        message = {
            "type": "GITHUB_EVENT",
            "event": x_github_event,
            "data": data
        }
        
        # Broadcast to anyone interested in this repo
        await manager.broadcast(message, channel)
        
        logger.info(f"Processed {x_github_event} for {repo_full_name}")
        return {"status": "processed"}
    except Exception as e:
        logger.error(f"Webhook processing failed: {e}")
        return {"status": "error", "detail": str(e)}
