import sys
import os
sys.path.append(os.getcwd())

from app.database import SessionLocal
from app.models.github_models import Repository

db = SessionLocal()
try:
    repos = db.query(Repository).all()
    print(f"Total repos: {len(repos)}")
    for repo in repos:
        print(f"- {repo.full_name} (owner: {repo.owner}, name: {repo.name})")
finally:
    db.close()
