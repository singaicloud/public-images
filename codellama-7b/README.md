# CodeLlama-7B

## Description
High-performance code generation and comprehension model, optimized based on the Llama architecture.

## Applicable Scenarios
- ✓ Code completion
- ✓ Code conversion
- ✓ Code interpretation

## Recommended Configuration
RTX 3090, 24GB VRAM

## Image Information
- Maintainer: Feiyuan ZHANG, Singaicloud
- Base Image: ollama-base:1.0
- Default Port: 22,11434
- Default Entrypoint: `/usr/sbin/sshd && /usr/local/bin/ollama serve` 

## Maintainer Debug Notes
```bash
docker pull 192.168.1.215:5000/codellama-7b-20250330:1.0
docker run -d -p 11434:11434 -p 22:22 --name codellama-7b 192.168.1.215:5000/codellama-7b-20250330:1.0