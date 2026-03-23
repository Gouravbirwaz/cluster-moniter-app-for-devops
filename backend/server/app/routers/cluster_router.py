from fastapi import APIRouter, Depends, HTTPException
import httpx
from app.core.config import settings
from pydantic import BaseModel
from typing import List, Optional
import json

router = APIRouter(tags=["clusters"])

class ClusterCreate(BaseModel):
    name: str
    kubeconfig: str
    prometheus_url: Optional[str] = None
    description: Optional[str] = None

class ClusterResponse(BaseModel):
    id: str
    name: str
    prometheus_url: Optional[str] = None
    description: Optional[str] = None

@router.post("/clusters", response_model=ClusterResponse)
async def add_cluster(cluster: ClusterCreate):
    """
    Add a new cluster configuration by storing it in the Vault.
    """
    async with httpx.AsyncClient() as client:
        # 1. Store Kubeconfig in Vault
        vault_payload = {
            "name": f"kubeconfig_{cluster.name}",
            "type": "kubeconfig",
            "value": cluster.kubeconfig,
            "description": f"Kubeconfig for cluster {cluster.name}"
        }
        
        vault_resp = await client.post(
            f"{settings.VAULT_SERVICE_URL}/api/v1/vault/secrets",
            json=vault_payload
        )
        
        if vault_resp.status_code != 200:
            raise HTTPException(status_code=vault_resp.status_code, detail="Failed to store kubeconfig in vault")
        
        # 2. Store Prometheus URL and Cluster Metadata
        # We'll use another secret for metadata or handle it in a local DB.
        # For simplicity, we'll store metadata as a secret too.
        metadata = {
            "name": cluster.name,
            "prometheus_url": cluster.prometheus_url or settings.PROMETHEUS_URL,
            "vault_secret_name": f"kubeconfig_{cluster.name}"
        }
        
        meta_payload = {
            "name": f"cluster_meta_{cluster.name}",
            "type": "cluster_metadata",
            "value": json.dumps(metadata),
            "description": f"Metadata for cluster {cluster.name}"
        }
        
        meta_resp = await client.post(
            f"{settings.VAULT_SERVICE_URL}/api/v1/vault/secrets",
            json=meta_payload
        )
        
        if meta_resp.status_code != 200:
            raise HTTPException(status_code=meta_resp.status_code, detail="Failed to store cluster metadata in vault")
            
        data = meta_resp.json()
        return {
            "id": data["id"],
            "name": cluster.name,
            "prometheus_url": cluster.prometheus_url,
            "description": cluster.description
        }

@router.get("/clusters", response_model=List[ClusterResponse])
async def list_clusters():
    """
    List all clusters from the Vault.
    """
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{settings.VAULT_SERVICE_URL}/api/v1/vault/secrets")
        if resp.status_code != 200:
            return []
            
        secrets = resp.json()
        clusters = []
        for s in secrets:
            if s["type"] == "cluster_metadata":
                # Get the actual metadata to extract the name and prometheus_url
                # In a more robust implementation, we'd fetch the value too.
                # For now, we'll just return the name from the secret name.
                clusters.append({
                    "id": s["id"],
                    "name": s["name"].replace("cluster_meta_", ""),
                    "description": s["description"]
                })
        return clusters

@router.post("/clusters/{name}/activate")
async def activate_cluster(name: str):
    """
    Set the active cluster for the backend.
    """
    from app.kubernetes.kube_client import kube_client
    
    async with httpx.AsyncClient() as client:
        # Fetch kubeconfig from vault
        resp = await client.get(f"{settings.VAULT_SERVICE_URL}/api/v1/vault/secrets/kubeconfig_{name}/value")
        if resp.status_code != 200:
            raise HTTPException(status_code=404, detail="Cluster configuration not found")
        
        kubeconfig_str = resp.json()["value"]
        
        # Re-initialize KubeClient
        success = kube_client.initialize_from_string(kubeconfig_str)
        if not success:
            raise HTTPException(status_code=500, detail="Failed to initialize Kubernetes client with provided config")
            
        return {"message": f"Cluster {name} activated successfully"}
