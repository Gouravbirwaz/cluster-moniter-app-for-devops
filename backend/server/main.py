from app.main import app
import uvicorn
import logging

# Silence verbose library logs
for logger_name in ["urllib3", "urllib3.connectionpool", "kubernetes", "kubernetes.client.rest"]:
    logging.getLogger(logger_name).setLevel(logging.ERROR)
    logging.getLogger(logger_name).propagate = False

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
