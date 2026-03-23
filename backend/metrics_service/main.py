from fastapi import FastAPI
import logging

# Silence verbose library logs
for logger_name in ["urllib3", "urllib3.connectionpool", "kubernetes", "kubernetes.client.rest"]:
    logging.getLogger(logger_name).setLevel(logging.ERROR)
    logging.getLogger(logger_name).propagate = False

from app.services.prometheus_client import prometheus_client

app = FastAPI(title="Metrics Service")

import asyncio
import json

@app.get("/api/v1/metrics/cluster")
async def get_cluster_metrics():
    logging.info("Received request for cluster metrics")
    return await asyncio.to_thread(prometheus_client.get_cluster_metrics)

@app.get("/api/v1/metrics/events")
async def get_cluster_events():
    logging.info("Received request for cluster events")
    if not prometheus_client.redis_client:
        return []
    
    try:
        # Read last 10 events from Redis stream
        # Using to_thread for the blocking redis call
        events = await asyncio.to_thread(prometheus_client.redis_client.xrevrange, "events", count=10)
        formatted_events = []
        for _, payload in events:
            if "payload" in payload:
                formatted_events.append(json.loads(payload["payload"]))
        return formatted_events
    except Exception as e:
        logging.error(f"Error fetching events from Redis: {e}")
        return []

@app.get("/health")
def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8008)
