import requests
import os
from dotenv import load_dotenv

load_dotenv()

invoke_url = f"{os.getenv('BASE_URL')}/chat/completions"

headers = {
    "Authorization": f"Bearer {os.getenv('NVIDIA_API_KEY')}",
    "Accept": "application/json"
}

payload = {
    "model": os.getenv('MODEL'),
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 1024,
    "temperature": 0.60,
    "top_p": 0.95,
    "stream": False,
    "chat_template_kwargs": {"enable_thinking": True},
}

response = requests.post(invoke_url, headers=headers, json=payload)
if response.status_code == 200:
    result = response.json()
    if "choices" in result and len(result["choices"]) > 0:
        message = result["choices"][0]["message"]
        print("AI Response:")
        print("=" * 50)
        # Check if there's reasoning content
        if "reasoning_content" in message:
            print("Reasoning:")
            print(message["reasoning_content"])
            print("\n" + "=" * 50)
        print("Content:")
        print(message.get("content", ""))
    else:
        print("No response generated")
else:
    print(f"Error: {response.status_code} - {response.text}")
