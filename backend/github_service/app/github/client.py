import httpx
from typing import List, Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)

class GitHubClient:
    def __init__(self, token: str):
        self.token = token
        self.base_url = "https://api.github.com"
        self.headers = {
            "Authorization": f"token {token}",
            "Accept": "application/vnd.github.v3+json"
        }

    async def get_repository(self, owner: str, repo: str) -> Dict[str, Any]:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.base_url}/repos/{owner}/{repo}", headers=self.headers)
            response.raise_for_status()
            return response.json()

    async def get_commits(self, owner: str, repo: str, limit: int = 20) -> List[Dict[str, Any]]:
        async with httpx.AsyncClient() as client:
            params = {"per_page": limit}
            response = await client.get(f"{self.base_url}/repos/{owner}/{repo}/commits", headers=self.headers, params=params)
            response.raise_for_status()
            return response.json()

    async def get_pull_requests(self, owner: str, repo: str, state: str = "open") -> List[Dict[str, Any]]:
        async with httpx.AsyncClient() as client:
            params = {"state": state}
            response = await client.get(f"{self.base_url}/repos/{owner}/{repo}/pulls", headers=self.headers, params=params)
            response.raise_for_status()
            return response.json()

    async def get_workflows(self, owner: str, repo: str) -> Dict[str, Any]:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.base_url}/repos/{owner}/{repo}/actions/workflows", headers=self.headers)
            response.raise_for_status()
            return response.json()

    async def get_workflow_runs(self, owner: str, repo: str, limit: int = 10) -> Dict[str, Any]:
        async with httpx.AsyncClient() as client:
            params = {"per_page": limit}
            response = await client.get(f"{self.base_url}/repos/{owner}/{repo}/actions/runs", headers=self.headers, params=params)
            response.raise_for_status()
            return response.json()
