from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import vault_router
from app.models.secret_models import Base
from sqlalchemy import create_engine
from app.core.config import settings

app = FastAPI(title="DevOps Secret Vault Service")

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create tables on startup
engine = create_engine(settings.DATABASE_URL)
Base.metadata.create_all(bind=engine)

app.include_router(vault_router.router, prefix="/api/v1")

@app.get("/")
async def root():
    return {"message": "Vault Service is running", "version": "1.0.0"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)
