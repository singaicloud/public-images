# Ollama Docker Deployment

This project provides a Docker setup for deploying [Ollama](https://ollama.com), an open-source platform for running large language models (LLMs) locally.

## Project Structure

```
ollama-docker
├── Dockerfile       # Docker configuration for Ollama deployment
├── start-ollama.sh  # Startup script for initializing Ollama
└── README.md        # This documentation file
```

## Features

- Based on the official `ollama/ollama` Docker image
- Support for NVIDIA GPU acceleration when available
- SSH server for cross-node communication
- Compatible with distributed environments (using SING_* environment variables)
- Option to automatically pull models at startup

## Quick Start

### Basic Usage

```bash
# Build the Docker image
docker build -t custom-ollama .

# Run the container
docker run -d -v ollama-data:/root/.ollama -p 11434:11434 --name ollama custom-ollama
```

### With GPU Support

```bash
# Make sure you have NVIDIA Docker runtime installed
docker run -d --gpus all -v ollama-data:/root/.ollama -p 11434:11434 --name ollama custom-ollama
```

### Default model 

This image downloads and installs the `llama2` model (Meta's Llama 2 7B model) on startup by default. You can also override the default model by setting environment variables:

```bash
# Use other models instead of the default llama2
docker run -d -v ollama-data:/root/.ollama -p 11434:11434 -e OLLAMA_MODEL=mistral custom-ollama
```

The list of available models can be viewed in the [Ollama Model Library](https://ollama.com/library).

## Deployment Notes

This image is designed to run Ollama as a standalone service. Unlike the PyTorch distributed example:

- Ollama does not support distributed processing or training
- Each container runs independently as its own LLM inference service
- You can deploy multiple containers but they will not coordinate with each other

If you need to scale LLM inference, consider deploying multiple independent Ollama instances and using a load balancer in front of them.

## API Usage

Once the container is running, you can interact with Ollama through its API:

```bash
# Test the API
curl http://localhost:11434/api/generate -d '{
  "model": "llama3",
  "prompt": "Explain what large language models are"
}'
```

## SSH Access

This image includes SSH server support for administration and management purposes. The default root password is `singaicloud`.

```bash
# Connect to the container via SSH
ssh root@<container-ip>
```

## Notes on GPU Acceleration

- You need at least 8 GB of RAM to run the 7B models
- 16 GB is recommended for 13B models
- 32 GB or more is needed for larger (30B+) models

For more information, please refer to the [official Ollama documentation](https://github.com/ollama/ollama).
