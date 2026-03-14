import httpx
from app.core.config import settings
from app.github.client import GitHubClient
from pydantic import BaseModel
from typing import Dict, Any
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.github_models import Repository
from fastapi import Depends, APIRouter, HTTPException

router = APIRouter(tags=["github"])

class RepoConnectRequest(BaseModel):
    repository: str # owner/repo
    token_secret_name: str

@router.post("/connect")
async def connect_repository(req: RepoConnectRequest, db: Session = Depends(get_db)):
    # Fetch token from Standalone Vault Service
    async with httpx.AsyncClient() as client:
        try:
            # Internal call to vault_service on 8002
            # vault_service has prefix /api/v1/vault
            url = f"{settings.VAULT_SERVICE_URL}/vault/secrets/{req.token_secret_name}/value"
            response = await client.get(url)
            if response.status_code != 200:
                raise HTTPException(status_code=404, detail=f"Secret '{req.token_secret_name}' not found in Vault Service")
            token = response.json().get("value")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error communicating with Vault Service: {str(e)}")
    
    if not token:
        raise HTTPException(status_code=404, detail="Token value missing in Vault response")
    
    try:
        # Clean up input: handle "https://github.com/owner/repo" or "owner/repo/"
        repo_path = req.repository.strip().rstrip("/")
        if "github.com/" in repo_path:
            repo_path = repo_path.split("github.com/")[-1]
        
        parts = repo_path.split("/")
        if len(parts) < 2:
             raise HTTPException(status_code=400, detail=f"Invalid repository format: '{req.repository}'. Expected 'owner/repo' or GitHub URL")
        
        owner, repo = parts[-2], parts[-1].replace(".git", "")
        full_name = f"{owner}/{repo}"

        gh_client = GitHubClient(token)
        repo_data = await gh_client.get_repository(owner, repo)
        
        # Save to database
        db_repo = db.query(Repository).filter(Repository.full_name == full_name).first()
        if not db_repo:
            db_repo = Repository(
                full_name=full_name,
                owner=owner,
                name=repo,
                token_secret_name=req.token_secret_name,
                description=repo_data.get("description"),
                stars=repo_data.get("stargazers_count", 0),
                forks=repo_data.get("forks_count", 0)
            )
            db.add(db_repo)
        else:
            db_repo.token_secret_name = req.token_secret_name
            db_repo.description = repo_data.get("description")
            db_repo.stars = repo_data.get("stargazers_count", 0)
            db_repo.forks = repo_data.get("forks_count", 0)
        
        db.commit()
        db.refresh(db_repo)

        return {
            "status": "connected",
            "repository": repo_data["full_name"],
            "description": repo_data["description"]
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to connect to GitHub: {str(e)}")

@router.get("/repos")
async def list_repositories(db: Session = Depends(get_db)):
    """List all connected repositories."""
    repos = db.query(Repository).all()
    return [repo.to_dict() for repo in repos]
@router.get("/repos/{owner}/{repo}/commits")
async def get_repo_commits(owner: str, repo: str, db: Session = Depends(get_db)):
    """Fetch commits for a specific repository."""
    owner = owner.strip()
    repo = repo.strip()
    full_name = f"{owner}/{repo}"
    print(f"DEBUG: get_repo_commits called with {full_name}")
    db_repo = db.query(Repository).filter(Repository.full_name == full_name).first()
    if not db_repo:
        # Case insensitive fallback
        db_repo = db.query(Repository).filter(Repository.full_name.ilike(full_name)).first()
        if not db_repo:
             # Try partial match if exactly 2 parts
             db_repo = db.query(Repository).filter(Repository.full_name.contains(repo)).first()
             if not db_repo:
                raise HTTPException(status_code=404, detail=f"Repository '{full_name}' not found")
    
    # Get token from Vault
    async with httpx.AsyncClient() as client:
        try:
            # Use fixed path segments for vault call to avoid similar issues
            url = f"{settings.VAULT_SERVICE_URL}/vault/secrets/{db_repo.token_secret_name}/value"
            response = await client.get(url)
            if response.status_code != 200:
                raise HTTPException(status_code=404, detail=f"Token '{db_repo.token_secret_name}' not found in Vault")
            token = response.json().get("value")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Vault communication error: {str(e)}")

    gh_client = GitHubClient(token)
    try:
        commits = await gh_client.get_commits(db_repo.owner, db_repo.name)
        return commits
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/repos/{owner}/{repo}/pulls")
async def get_repo_pulls(owner: str, repo: str, db: Session = Depends(get_db)):
    """Fetch pull requests for a specific repository."""
    full_name = f"{owner}/{repo}"
    db_repo = db.query(Repository).filter(Repository.full_name == full_name).first()
    if not db_repo:
        db_repo = db.query(Repository).filter(Repository.full_name.ilike(full_name)).first()
        if not db_repo:
             raise HTTPException(status_code=404, detail=f"Repository '{full_name}' not found")
    
    async with httpx.AsyncClient() as client:
        try:
            url = f"{settings.VAULT_SERVICE_URL}/vault/secrets/{db_repo.token_secret_name}/value"
            response = await client.get(url)
            token = response.json().get("value")
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

    gh_client = GitHubClient(token)
    try:
        return await gh_client.get_pull_requests(db_repo.owner, db_repo.name)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/repos/{owner}/{repo}/workflows")
async def get_repo_workflows(owner: str, repo: str, db: Session = Depends(get_db)):
    """Fetch workflows for a specific repository."""
    full_name = f"{owner}/{repo}"
    db_repo = db.query(Repository).filter(Repository.full_name == full_name).first()
    if not db_repo:
        db_repo = db.query(Repository).filter(Repository.full_name.ilike(full_name)).first()
        if not db_repo:
            raise HTTPException(status_code=404, detail=f"Repository '{full_name}' not found")
    
    async with httpx.AsyncClient() as client:
        try:
            url = f"{settings.VAULT_SERVICE_URL}/vault/secrets/{db_repo.token_secret_name}/value"
            response = await client.get(url)
            token = response.json().get("value")
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

    gh_client = GitHubClient(token)
    try:
        return await gh_client.get_workflows(db_repo.owner, db_repo.name)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
@router.delete("/repos/{owner}/{repo}")
async def delete_repository(owner: str, repo: str, db: Session = Depends(get_db)):
    """Disconnect and delete a repository from the database."""
    full_name = f"{owner}/{repo}"
    db_repo = db.query(Repository).filter(Repository.full_name == full_name).first()
    if not db_repo:
        raise HTTPException(status_code=404, detail="Repository not found")
    
    try:
        db.delete(db_repo)
        db.commit()
        return {"message": f"Repository {full_name} disconnected successfully"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))
