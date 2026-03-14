import asyncio
import logging
import json
from typing import Optional, Dict, List, Tuple, Any
from kubernetes import watch
from app.kubernetes.kube_client import kube_client
from app.websocket.websocket_manager import manager

logger = logging.getLogger(__name__)

class ResourceWatcher:
    def __init__(self):
        self.watch = watch.Watch()
        self.stop_event = asyncio.Event()
        self.message_queue: asyncio.Queue = asyncio.Queue()
        self._processor_task: Optional[asyncio.Task] = None

    async def _process_queue(self):
        """Dedicated task to drain the queue and broadcast messages."""
        logger.info("Message queue processor started")
        while not self.stop_event.is_set():
            try:
                # Wait for a message with a timeout to check stop_event
                try:
                    # Queue holds tuples of (message_dict, channel_name)
                    item = await asyncio.wait_for(self.message_queue.get(), timeout=1.0)
                    if item is None:
                        continue
                    message_data, channel = item
                except asyncio.TimeoutError:
                    continue
                
                await manager.broadcast(message_data, channel)
                self.message_queue.task_done()
            except Exception as e:
                logger.error(f"Error in message processor: {e}")
                await asyncio.sleep(1)

    async def _run_watcher(self, watch_func, channel, event_type, data_extractor):
        """Generic watcher runner that handles connectivity and threading."""
        logger.info(f"Initialized demand-driven watcher for {channel}:{event_type}")
        retry_delay = 5
        loop = asyncio.get_event_loop()

        def sync_watch():
            """The blocking watch loop to run in a thread."""
            watcher = watch.Watch()
            try:
                api_client = getattr(kube_client, 'v1')
                if not api_client:
                    return "not_initialized"
                
                for event in watcher.stream(watch_func, _request_timeout=60):
                    if self.stop_event.is_set():
                        break
                    
                    message = {
                        "type": event_type,
                        "action": event['type'],
                        "data": data_extractor(event['object'])
                    }
                    # Thread-safe queue insertion
                    loop.call_soon_threadsafe(self.message_queue.put_nowait, (message, channel))
            except Exception as e:
                return str(e)
            finally:
                watcher.stop()
            return None

        while not self.stop_event.is_set():
            if not manager.has_subscribers(channel):
                await asyncio.sleep(5)
                continue

            logger.info(f"Starting connection for {event_type} watcher...")
            # Run the blocking sync_watch in a thread pool
            error_msg = await loop.run_in_executor(None, sync_watch)
            
            if error_msg:
                if error_msg == "not_initialized":
                    logger.warning(f"K8s client not ready for {event_type}. Retrying...")
                else:
                    logger.warning(f"{event_type} watcher connection lost: {error_msg}. Retrying in {retry_delay}s...")
                
                await asyncio.sleep(retry_delay)
                retry_delay = min(retry_delay * 2, 60)
            else:
                retry_delay = 5

    async def watch_nodes(self):
        def extract_node(node):
            return {
                "name": node.metadata.name,
                "status": "Ready" if any(c.type == 'Ready' and c.status == 'True' for c in node.status.conditions) else "NotReady",
                "uid": node.metadata.uid
            }
        await self._run_watcher(kube_client.v1.list_node, "cluster_mon", "NODE_EVENT", extract_node)

    async def watch_pods(self):
        def extract_pod(pod):
            return {
                "name": pod.metadata.name,
                "namespace": pod.metadata.namespace,
                "status": pod.status.phase,
                "uid": pod.metadata.uid
            }
        await self._run_watcher(kube_client.v1.list_pod_for_all_namespaces, "cluster_mon", "POD_EVENT", extract_pod)

    async def watch_events(self):
        def extract_event(event):
            return {
                "name": event.metadata.name,
                "message": event.message,
                "type": event.type,
                "reason": event.reason,
                "object": f"{event.involved_object.kind}/{event.involved_object.name}"
            }
        await self._run_watcher(kube_client.v1.list_event_for_all_namespaces, "cluster_mon", "CLUSTER_EVENT", extract_event)
    
    async def watch_metrics(self):
        """Periodically broadcast cluster metrics snapshot."""
        from app.services.cluster_service import cluster_service
        logger.info("Starting cluster metrics broadcaster...")
        
        while not self.stop_event.is_set():
            if not manager.has_subscribers("cluster_mon"):
                await asyncio.sleep(5)
                continue
                
            try:
                overview = await cluster_service.get_overview()
                message = {
                    "type": "METRIC_EVENT",
                    "data": {
                        "cpu_usage": overview.cpu_usage,
                        "memory_usage": overview.memory_usage,
                        "running_pods": overview.running_pods,
                        "failed_pods": overview.failed_pods
                    }
                }
                # Broadcast immediately via queue
                self.message_queue.put_nowait((message, "cluster_mon"))
            except Exception as e:
                logger.error(f"Error in metrics broadcaster: {e}")
            
            await asyncio.sleep(2) # Poll every 2 seconds for true real-time

    async def watch_pod_logs(self, namespace: str, pod_name: str, container: str = None):
        channel = f"logs_{namespace}_{pod_name}"
        logger.info(f"Starting log watcher for {pod_name} in namespace {namespace}...")
        
        loop = asyncio.get_event_loop()

        def sync_logs():
            watcher = watch.Watch()
            try:
                kwargs = {'name': pod_name, 'namespace': namespace, 'follow': True}
                if container:
                    kwargs['container'] = container
                
                # Using watcher.stream for more reliable line-by-line reading
                for line in watcher.stream(kube_client.v1.read_namespaced_pod_log, **kwargs):
                    if self.stop_event.is_set():
                        break
                    
                    message = {
                        "type": "POD_LOG",
                        "pod": pod_name,
                        "data": line if isinstance(line, str) else line.decode('utf-8', errors='replace')
                    }
                    # Thread-safe queue insertion
                    loop.call_soon_threadsafe(self.message_queue.put_nowait, (message, channel))
            except Exception as e:
                logger.error(f"Sync log watcher failed for {pod_name}: {e}")
            finally:
                watcher.stop()

        await loop.run_in_executor(None, sync_logs)

    async def start_all(self):
        # Start the queue processor
        if not self._processor_task or self._processor_task.done():
            self._processor_task = asyncio.create_task(self._process_queue())
            
        # Fire and forget the watcher tasks
        asyncio.create_task(self.watch_nodes())
        asyncio.create_task(self.watch_pods())
        asyncio.create_task(self.watch_events())
        asyncio.create_task(self.watch_metrics())

    def stop(self):
        self.stop_event.set()

resource_watcher = ResourceWatcher()
