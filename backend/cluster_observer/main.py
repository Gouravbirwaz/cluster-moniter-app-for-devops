import asyncio
from fastapi import FastAPI
import logging

# Silence verbose library logs
for logger_name in ["urllib3", "urllib3.connectionpool", "kubernetes", "kubernetes.client.rest"]:
    logging.getLogger(logger_name).setLevel(logging.ERROR)
    logging.getLogger(logger_name).propagate = False

from app.services.resource_watcher import resource_watcher

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Cluster Observer Service")

@app.on_event("startup")
async def startup_event():
    # Start watchers in the background
    asyncio.create_task(resource_watcher.watch_pods())
    asyncio.create_task(resource_watcher.watch_nodes())
    asyncio.create_task(resource_watcher.publish_metrics())
    logger.info("Watchers and metric publisher started")


@app.get("/health")
def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8007)
