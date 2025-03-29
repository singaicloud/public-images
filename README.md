# Sing AI Cloud Public Images

This repository contains Dockerfiles and related files for various language models deployed using Ollama.

## Repository Structure

- `codellama-7b/`: CodeLlama 7B model files
- `deepseek-7b/`: DeepSeek 7B model files
- `llama2-7b/`: Llama2 7B model files
- `qwen-7b/`: Qwen 7B model files

## Models Overview

| Model | Description | Scenarios | Configuration |
|-------|-------------|-----------|---------------|
| CodeLlama-7B | High-performance code generation model | Code completion, conversion, interpretation | RTX 3090, 24GB VRAM |
| DeepSeek-7B | Advanced LLM with strong reasoning | Text generation, Q&A, logical reasoning | RTX 3090, 24GB VRAM |
| Llama2-7B | General-purpose conversational model | Text generation, conversation, content creation | RTX 3090, 24GB VRAM |
| Qwen-7B | Versatile multilingual model | Multilingual text, translation, content creation | RTX 3090, 24GB VRAM |

## Usage

Each model directory contains:
- Dockerfile: Configuration for building the model image
- scripts/: Helper scripts for model initialization and runtime
- README.md: Model-specific documentation and usage instructions

## Building and Pushing Images

```bash
# Example for building and pushing CodeLlama 7B
docker build -t 192.168.1.215:5000/codellama-7b-20250330:1.0 -f codellama-7b/Dockerfile .
docker push 192.168.1.215:5000/codellama-7b-20250330:1.0
``` 