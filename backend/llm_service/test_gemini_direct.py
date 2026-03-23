import google.generativeai as genai
import os
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")

print(f"Configuring with key: {api_key[:5]}...")
genai.configure(api_key=api_key)

try:
    model = genai.GenerativeModel('gemini-1.5-flash')
    print("Sending 'hi' to Gemini...")
    response = model.generate_content("hi")
    print(f"RESPONSE SUCCESS: {response.text}")
except Exception as e:
    print(f"GEMINI FAILED: {type(e).__name__}: {e}")
