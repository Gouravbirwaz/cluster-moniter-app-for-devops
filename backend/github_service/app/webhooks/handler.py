import hmac
import hashlib
import json
import logging
import redis
from fastapi import APIRouter, Request, Header, HTTPException
from app.core.config import settings

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/webhooks", tags=["webhooks"])

# Redis connection
redis_client = redis.Redis.from_url(settings.REDIS_URL, decode_responses=True)

def verify_signature(payload: bytes, signature: str, secret: str):
    if not secret:
        return True 
    
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
    
    try:
        data = json.loads(payload)
        repo_full_name = data.get("repository", {}).get("full_name")
        if not repo_full_name:
            return {"status": "ignored", "reason": "no repository info"}

        event_msg = {
            "type": "github_event",
            "event": x_github_event,
            "resource": repo_full_name,
            "message": f"GitHub {x_github_event} event in {repo_full_name}"
        }
        
        # Publish to unified events stream
        redis_client.xadd("events", {"payload": json.dumps(event_msg)})
        
        logger.info(f"Processed {x_github_event} for {repo_full_name} and published to Redis")
        return {"status": "processed"}
    except Exception as e:
        logger.error(f"Webhook processing failed: {e}")
        return {"status": "error", "detail": str(e)}

