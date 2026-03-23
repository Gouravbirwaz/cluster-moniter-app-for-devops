import logging

# Silence verbose library logs
for logger_name in ["urllib3", "urllib3.connectionpool", "kubernetes", "kubernetes.client.rest"]:
    logging.getLogger(logger_name).setLevel(logging.ERROR)
    logging.getLogger(logger_name).propagate = False

import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from app.services.risk_analyzer import risk_analyzer
from app.services.executor import executor
from app.core.config import settings

app = FastAPI(title=settings.PROJECT_NAME)

class IntentRequest(BaseModel):
    intent: dict

@app.post("/api/v1/guardian/execute")

async def handle_execution(request: IntentRequest):
    # 1. Risk Analysis
    risk_result = await risk_analyzer.evaluate_risk(request.intent)
    
    if risk_result["status"] == "rejected":
        return {
            "status": "rejected",
            "reason": risk_result["reason"],
            "suggestion": "Perform a rolling restart instead of deletion."
        }
    
    # 2. Execution
    execution_result = await executor.execute(request.intent)
    return execution_result

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "cluster-guardian"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8006, reload=True)
