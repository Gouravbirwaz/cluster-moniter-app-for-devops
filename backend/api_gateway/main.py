from fastapi import FastAPI, Depends, HTTPException, status
import logging

# Silence verbose library logs
for logger_name in ["urllib3", "urllib3.connectionpool", "kubernetes", "kubernetes.client.rest"]:
    logging.getLogger(logger_name).setLevel(logging.ERROR)
    logging.getLogger(logger_name).propagate = False

from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from app.core.config import settings
from app.core.auth import create_access_token
from app.routers import proxy_router
import uvicorn

app = FastAPI(title=settings.PROJECT_NAME)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Authentication endpoint
@app.post("/api/v1/login")
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    # Simple hardcoded check for demo
    if form_data.username == "admin" and form_data.password == "password":
        access_token = create_access_token(data={"sub": form_data.username})
        return {"access_token": access_token, "token_type": "bearer"}
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Incorrect username or password",
        headers={"WWW-Authenticate": "Bearer"},
    )

app.include_router(proxy_router.router, prefix=settings.API_V1_STR)

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "api-gateway"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8003, reload=True)
