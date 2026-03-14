from app.kubernetes.kube_client import kube_client
from app.models.alert_models import AlertDetail
from typing import List, Optional
import logging

logger = logging.getLogger(__name__)

class AlertService:
    async def get_alerts(self, namespace: Optional[str] = None) -> List[AlertDetail]:
        try:
            if namespace:
                events = kube_client.v1.list_namespaced_event(namespace)
            else:
                events = kube_client.v1.list_event_for_all_namespaces()
            
            # Sort by last timestamp, newest first
            sorted_events = sorted(
                events.items, 
                key=lambda x: x.last_timestamp if x.last_timestamp else x.event_time if x.event_time else "", 
                reverse=True
            )

            return [
                AlertDetail(
                    message=e.message,
                    reason=e.reason,
                    type=e.type,
                    namespace=e.metadata.namespace,
                    timestamp=str(e.last_timestamp) if e.last_timestamp else "N/A",
                    severity="Warning" if e.type == "Warning" else "Normal"
                ) for e in sorted_events[:50] # Limit to 50 most recent
            ]
        except Exception as e:
            logger.error(f"Error fetching alerts: {e}")
            return []

alert_service = AlertService()
