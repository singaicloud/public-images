# Llama2-7B

## Description
General-purpose large language model with strong conversational abilities.

## Applicable Scenarios
- ✓ Text generation
- ✓ Conversation
- ✓ Content creation

## Recommended Configuration
RTX 3090, 24GB VRAM

## Usage
```bash
docker pull 192.168.1.215:5000/llama2-7b-20250330:1.0
docker run -d -p 11434:11434 -p 22:22 --name llama2-7b 192.168.1.215:5000/llama2-7b-20250330:1.0
```

## Image Information
- Maintainer: Sing
- Base Image: ollama-base:1.0
- Default Port: 22,11434
- Default Entrypoint: `/usr/sbin/sshd && /usr/local/bin/ollama serve` 