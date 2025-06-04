#!/bin/bash

# Build the RAG service image
IMAGE_NAME="rag-service:latest"

echo "Building RAG service image: $IMAGE_NAME"

# Build Docker image
docker build -t $IMAGE_NAME .

if [ $? -eq 0 ]; then
    echo "Build successful! Image name: $IMAGE_NAME"
    echo "You can run the service with the following command:"
    echo "./run.sh"
else
    echo "Build failed, please check the error messages"
fi
