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
huggingface-cli download --resume-download liuhaotian/llava-v1.5-7b --local-dir ./models/liuhaotian/llava-v1.5-7b
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

# 运行
python -m llava.serve.controller --host 0.0.0.0 --port 10000

python -m llava.serve.gradio_web_server --controller http://localhost:10000 --model-list-mode reload


# 双卡
CUDA_VISIBLE_DEVICES=0,1 python3 -m sglang.launch_server --model-path ./models/liuhaotian/llava-v1.5-7b --tokenizer-path ./models/llava-hf/llava-1.5-7b-hf --port 30000 --tp 2

# llava 的 worker
python -m llava.serve.sglang_worker --host 0.0.0.0 --controller http://localhost:10000 --port 40000 --worker http://localhost:40000 --sgl-endpoint http://127.0.0.1:30000

# 实际推理的worker
python -m llava.serve.model_worker --host 0.0.0.0 --controller http://localhost:10000 --port 40000 --worker http://localhost:40000 --model-path ./models/liuhaotian/llava-v1.5-7b
