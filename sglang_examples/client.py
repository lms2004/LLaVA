"""
    跑不通
"""

import requests
from sglang.test.test_utils import is_in_ci


from sglang.utils import launch_server_cmd

from sglang.utils import wait_for_server, print_highlight, terminate_process

port = 30002

vision_process, port = launch_server_cmd(
    """
CUDA_VISIBLE_DEVICES=0,1 python3 -m sglang.launch_server --model-path /hy-tmp/models/liuhaotian/llava-v1.5-7b --tokenizer-path ./models/llava-hf/llava-1.5-7b-hf --port {port} --tp 2
"""
)

wait_for_server(f"http://localhost:{port}")

import subprocess

curl_command = f"""
curl -s http://localhost:{port}/v1/chat/completions \\
  -d '{{
    "model": "Qwen/Qwen2.5-VL-7B-Instruct",
    "messages": [
      {{
        "role": "user",
        "content": [
          {{
            "type": "text",
            "text": "What’s in this image?"
          }},
          {{
            "type": "image_url",
            "image_url": {{
              "url": "https://github.com/sgl-project/sglang/blob/main/test/lang/example_image.png?raw=true"
            }}
          }}
        ]
      }}
    ],
    "max_tokens": 300
  }}'
"""

response = subprocess.check_output(curl_command, shell=True).decode()
print_highlight(response)


response = subprocess.check_output(curl_command, shell=True).decode()
print_highlight(response)