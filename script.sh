cd /hy-tmp

echo "配置 Hugging Face cli"
pip install -U "huggingface_hub[cli]"

# vim ~/.profile
export HF_ENDPOINT=https://hf-mirror.com


# https://huggingface.co/llava-hf/llava-1.5-7b-hf/tree/main
# https://huggingface.co/liuhaotian/llava-v1.5-7b
# 默认下载：~/.cache/huggingface/hub/
echo "下载模型.."
echo "llava-v1.5-7b 下载中"
huggingface-cli download --resume-download liuhaotian/llava-v1.5-7b --local-dir /hy-tmp/models/liuhaotian/llava-v1.5-7b
echo "llava-v1.5-7b 下载完成"

echo "llava-hf/llava-1.5-7b-hf 分词器下载中"
huggingface-cli download --resume-download llava-hf/llava-1.5-7b-hf --local-dir ./models/llava-hf/llava-1.5-7b-hf
echo "llava-hf/llava-1.5-7b-hf 分词器下载完成"

huggingface-cli download --resume-download openai/clip-vit-large-patch14-336 --local-dir ./models/openai/clip-vit-large-patch14-336

# python 环境

# 虚拟环境
conda create -n llava python=3.10 -y
conda activate llava
pip install --upgrade pip  # enable PEP 660 support
pip install -e .
pip install gradio
pip install "sglang[all]"
# installation page of its repo: https://github.com/protocolbuffers/protobuf/tree/master/python#installation and follow the ones
# 1. Downgrade the protobuf package to 3.20.x or lower.
# 2. Set PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python (but this will use pure-Python parsing and will be much slower).
pip install protobuf==3.19.5
pip install --upgrade accelerate
pip install fastapi==0.111.0

# TypeError: LlavaLlamaForCausalLM.forward() got an unexpected keyword argument 'cache_position'
pip install transformers==4.37.2



# 验证
python ./LLaVA/llava/eval/run_llava.py --model-path /hy-tmp/models/liuhaotian/llava-v1.5-7b --image-file https://llava-vl.github.io/static/images/view.jpg --query "What are the things I should be cautious about when I visit here?"

# 没跑通
# python -m llava.serve.cli \
#     --model-path /hy-tmp/models/liuhaotian/llava-v1.5-7b \
#     --image-file "https://llava-vl.github.io/static/images/view.jpg" \
#     --load-4bit


# Gradio (UI Server)
#   │
#   ↓
# Controller (API Server:10000)
#   │
#   ├──> Model Worker: llava-v1.5-7b (PORT:40000)
#   │
#   ├──> Model Worker: llava-v1.5-13b (PORT:40001)
#   │
#   └──> SGLang Worker: llava-v1.6-34b (PORT:40002)
#           │
#           ↓
#         SGLang Backend: llava-v1.6-34b (sglang server)

# 参考： https://zhuanlan.zhihu.com/p/696406884
# Gradio (UI Server)
python -m llava.serve.gradio_web_server --controller http://localhost:10000 --model-list-mode reload

# Controller
python -m llava.serve.controller --host 0.0.0.0 --port 10000

# Launch a model worker
python -m llava.serve.model_worker --host 0.0.0.0 --controller http://localhost:10000 --port 40000 --worker http://localhost:40000 --model-path /hy-tmp/models/liuhaotian/llava-v1.5-7b


# # LLaVA-SGLang worker that will communicate between LLaVA controller and SGLang backend
# python -m llava.serve.sglang_worker --host 0.0.0.0 --controller http://localhost:10000 --port 40000 --worker http://localhost:40000 --sgl-endpoint http://127.0.0.1:30000

# # SGLang Backend (双卡)
# CUDA_VISIBLE_DEVICES=0,1 python3 -m sglang.launch_server --model-path /hy-tmp/models/liuhaotian/llava-v1.5-7b --tokenizer-path ./models/llava-hf/llava-1.5-7b-hf --port 30000 --tp 2

 