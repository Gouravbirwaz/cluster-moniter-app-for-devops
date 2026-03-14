import sys
import os
sys.path.append(os.getcwd())

from app.database import SessionLocal
from app.models.github_models import Repository

db = SessionLocal()
try:
    repos = db.query(Repository).all()
    print(f"Checking {len(repos)} repos...")
    for repo in repos:
        old_full_name = repo.full_name
        repo.full_name = repo.full_name.strip()
        repo.owner = repo.owner.strip()
        repo.name = repo.name.strip()
        if old_full_name != repo.full_name:
            print(f"Cleaned: '{old_full_name}' -> '{repo.full_name}'")
    db.commit()
    print("Database cleanup complete.")
finally:
    db.close()
