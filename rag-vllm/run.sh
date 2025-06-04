#!/bin/bash

# Set environment variables
VLLM_HOST=${VLLM_HOST:-"localhost"}
VLLM_PORT=${VLLM_PORT:-"8000"}
RAG_PORT=3456

# Display configuration information
echo "Starting RAG service with the following configuration:"
echo "vLLM service address: $VLLM_HOST:$VLLM_PORT"
echo "RAG service port: $RAG_PORT"

# Confirm whether to continue
read -p "Continue starting the service? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Startup cancelled"
    exit 1
fi

# Run Docker container
docker run -d \
    --name rag-service \
    --network host \
    -e VLLM_HOST=$VLLM_HOST \
    -e VLLM_PORT=$VLLM_PORT \
    --restart unless-stopped \
    rag-service:latest

if [ $? -eq 0 ]; then
    echo "RAG service started!"
    echo "You can access the service via the following URLs:"
    echo "- Health check: http://localhost:$RAG_PORT/"
    echo "- Direct query endpoint: http://localhost:$RAG_PORT/query"
    echo "- RAG query endpoint: http://localhost:$RAG_PORT/rag"
    echo
    echo "Use the following command to view logs:"
    echo "docker logs -f rag-service"
else
    echo "Failed to start service, please check the error messages"
fi
