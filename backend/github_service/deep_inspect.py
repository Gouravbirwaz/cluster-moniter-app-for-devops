import sys
import os
sys.path.append(os.getcwd())

from app.database import SessionLocal
from app.models.github_models import Repository

db = SessionLocal()
try:
    repos = db.query(Repository).all()
    for repo in repos:
        print(f"ID: {repo.id}")
        print(f"Full Name: '{repo.full_name}'")
        print(f"Full Name Bytes: {repo.full_name.encode('utf-8')}")
        print(f"Owner: '{repo.owner}'")
        print(f"Owner Bytes: {repo.owner.encode('utf-8')}")
        print(f"Name: '{repo.name}'")
        print(f"Name Bytes: {repo.name.encode('utf-8')}")
finally:
    db.close()
