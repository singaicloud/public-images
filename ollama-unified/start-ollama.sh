#!/bin/bash

# Start SSH service
service ssh start

# Configure Ollama to listen on all interfaces
export OLLAMA_HOST="0.0.0.0"

# Start Ollama service in background
echo "Starting Ollama server..."
ollama serve &

# Wait for server to start up
echo "Waiting for Ollama server to initialize..."
sleep 10

# Check if a specific model should be pulled at startup
if [ ! -z "$OLLAMA_MODEL" ]; then
    echo "Pulling custom model $OLLAMA_MODEL at startup"
    ollama pull $OLLAMA_MODEL
else
    # Default to llama2-7b if no specific model is specified
    echo "Pulling default model llama2 at startup"
    ollama pull llama2
fi

# Keep container running
wait
