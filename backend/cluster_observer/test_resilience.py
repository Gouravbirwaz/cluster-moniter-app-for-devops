import asyncio
import logging
from app.services.resource_watcher import ResourceWatcher
from app.core.config import settings

logging.basicConfig(level=logging.INFO)

async def test_resilience():
    print("Testing ResourceWatcher resilience with no Kubernetes...")
    # Ensure settings are set to fail
    settings.KUBE_API_SERVER = "http://localhost:12345" # Wrong port
    
    watcher = ResourceWatcher()
    
    print("Watcher initialized. Initializing k8s...")
    watcher._initialize_k8s()
    
    if watcher.v1 is None:
        print("PASS: v1 is None as expected when connection fails.")
    else:
        print("FAIL: v1 should be None.")

    print("Testing metrics publication fallback...")
    # This should run without crashing even if v1 is None
    await asyncio.wait_for(watcher.publish_metrics(), timeout=2)

if __name__ == "__main__":
    try:
        asyncio.run(test_resilience())
    except asyncio.TimeoutError:
        print("PASS: Metric publication started and didn't crash (timed out as expected due to while True loop).")
    except Exception as e:
        print(f"FAIL: Unexpected error: {e}")
