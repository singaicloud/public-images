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

### Pre-loading a Model

```bash
# Run with a specific model that will be downloaded at startup
docker run -d -v ollama-data:/root/.ollama -p 11434:11434 -e OLLAMA_MODEL=llama3 --name ollama custom-ollama
```

## Distributed Environment

This image is designed to work in distributed environments similar to the PyTorch distributed example. It uses environment variables provided by the platform:

- `SING_RANK`: Unique identifier for each node within the distributed group
- `SING_WORLD_SIZE`: Total number of nodes participating in the distributed job
- `SING_MASTER_ADDR`: Host address for the node with rank 0 (master node)

## API Usage

Once the container is running, you can interact with Ollama through its API:

```bash
# Test the API
curl http://localhost:11434/api/generate -d '{
  "model": "llama3",
  "prompt": "Hello, world!"
}'
```

## Notes on GPU Acceleration

- You need at least 8 GB of RAM to run the 7B models
- 16 GB is recommended for 13B models
- 32 GB or more is needed for larger (30B+) models

For more information, please refer to the [official Ollama documentation](https://github.com/ollama/ollama).
