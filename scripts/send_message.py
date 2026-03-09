import requests
import base64
import os
from dotenv import load_dotenv

load_dotenv()

invoke_url = f"{os.getenv('BASE_URL')}/chat/completions"
stream = True

def read_b64(path):
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode()

headers = {
    "Authorization": f"Bearer {os.getenv('NVIDIA_API_KEY')}",
    "Accept": "text/event-stream" if stream else "application/json"
}

payload = {
    "model": os.getenv('MODEL'),
    "messages": [{"role":"user","content":"Hello"}],
    "max_tokens": 16384,
    "temperature": 0.60,
    "top_p": 0.95,
    "stream": stream,
    "chat_template_kwargs": {"enable_thinking":True},
}

response = requests.post(invoke_url, headers=headers, json=payload, stream=stream)
if stream:
    for line in response.iter_lines():
        if line:
            print(line.decode("utf-8"))
else:
    print(response.json())
