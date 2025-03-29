# Qwen-7B

## Description
Versatile language model with strong multilingual capabilities.

## Applicable Scenarios
- ✓ Multilingual text generation
- ✓ Translation assistance
- ✓ Content creation

## Recommended Configuration
RTX 3090, 24GB VRAM

## Usage
```bash
docker pull 192.168.1.215:5000/qwen-7b-20250330:1.0
docker run -d -p 11434:11434 -p 22:22 --name qwen-7b 192.168.1.215:5000/qwen-7b-20250330:1.0
```

## Image Information
- Maintainer: Sing
- Base Image: ollama-base:1.0
- Default Port: 22,11434
- Default Entrypoint: `/usr/sbin/sshd && /usr/local/bin/ollama serve` 