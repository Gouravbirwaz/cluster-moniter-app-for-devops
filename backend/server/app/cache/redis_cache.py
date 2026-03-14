import redis.asyncio as redis
from app.core.config import settings
import json
import logging

logger = logging.getLogger(__name__)

class RedisCache:
    def __init__(self):
        self.redis = redis.from_url(settings.REDIS_URL, decode_responses=True)

    async def get(self, key: str):
        try:
            data = await self.redis.get(key)
            return json.loads(data) if data else None
        except Exception as e:
            logger.error(f"Redis get failed for key {key}: {e}")
            return None

    async def set(self, key: str, value: any, expire: int = 300):
        try:
            await self.redis.set(key, json.dumps(value), ex=expire)
        except Exception as e:
            logger.error(f"Redis set failed for key {key}: {e}")

    async def delete(self, key: str):
        await self.redis.delete(key)

redis_cache = RedisCache()
