import sys
import os
sys.path.append(os.getcwd())

from main import app

print("Listing all routes for github_service:")
for route in app.routes:
    if hasattr(route, 'path'):
        methods = getattr(route, 'methods', 'WS')
        print(f"{methods} {route.path}")
