# Beginner's Guide to Distributed vLLM Serving

This guide will walk you through how to submit multi-node tasks for distributed inference using vLLM. Whether you're running tensor parallel or pipeline parallel inference, this guide will help you get started with distributed serving.

## What's Included

```
vllm/
├── Dockerfile          # Recipe for building the vLLM serving environment
├── shm_broadcast.py    # Essential file that fixes multi-node bugs in vLLM-0.6.6
└── run_ray_cluster.sh  # Launch script to start Ray cluster and vLLM serving
```

## Getting Started

Follow these steps to launch your distributed vLLM serving:

1. Click "Quick Launch" and select `vllm:ssh-enabled-latest` image.
   > Note: This image is based on vLLM v0.6.6 with our custom fixes for multi-node deployment bugs. We've patched the shared memory communication issues that affected the original vLLM v0.6.6 in distributed environments.

2. In GPU Configuration, select the number of GPUs needed (recommend using the same GPU model, e.g., 3090).

3. In Job Configuration, set the Entry Command. For example:
```bash
./run_ray_cluster.sh -model facebook/opt-6.7b -port 2345 -tp 2 -pp 1
```
   - `-model`: The model to serve
   - `-port`: The vLLM service port (you can access the service through the mapped port)
   - `-tp`: Tensor parallel size
   - `-pp`: Pipeline parallel size

4. In Exposed Ports, add:
   - Port 22 (for SSH)
   - Your service port (e.g., 2345)

5. Configure Environment Variables:
   - `HF_TOKEN`: Required for downloading models from Hugging Face. Get your token from [Hugging Face Access Tokens](https://huggingface.co/docs/hub/security-tokens)
   - `HF_HOME`: Directory for storing model weights. Default is `/private_data/.cache/huggingface`. If model weights already exist here, no download is needed.

6. Click "Launch" to start the service.

7. The service will be ready in about 5-10 minutes (depending on model download time, weight loading time, Ray startup time, and vLLM service startup time).

8. Verify the service is running with a test request:
```bash
curl http://gw.tacc.ust.hk:YOUR_MAPPED_PORT/v1/completions \
-H "Content-Type: application/json" \
-d '{
    "model": "facebook/opt-6.7b",
    "prompt": "The future of AI is",
    "max_tokens": 10,
    "temperature": 0.7
}'
```
Replace `YOUR_MAPPED_PORT` with your actual mapped port and `model` with your chosen model.


