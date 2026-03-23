import os
from dotenv import load_dotenv
print(f"Current Dir: {os.getcwd()}")
print(f"Env file exists: {os.path.exists('.env')}")
load_dotenv()
key = os.getenv("GEMINI_API_KEY")
if key:
    print(f"GEMINI_API_KEY found: {key[:5]}...{key[-5:]}")
else:
    print("GEMINI_API_KEY NOT FOUND")
