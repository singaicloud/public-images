#!/bin/bash

# Start SSH service
service ssh start

# Configure Ollama to listen on all interfaces
export OLLAMA_HOST="0.0.0.0"

# Note: Ollama does not support distributed processing
# This container runs as a standalone service
# Each instance operates independently

# If environment variables for a distributed setup exist, log a note
if [ ! -z "$SING_RANK" ] || [ ! -z "$SING_WORLD_SIZE" ] || [ ! -z "$SING_MASTER_ADDR" ]; then
    echo "NOTE: Detected distributed environment variables, but Ollama operates as a standalone service."
    echo "Each Ollama instance will run independently without coordination."
fi

# Check if a specific model should be pulled at startup
if [ ! -z "$OLLAMA_MODEL" ]; then
    echo "Pulling model $OLLAMA_MODEL at startup"
    ollama pull $OLLAMA_MODEL
fi

# Start Ollama service
echo "Starting Ollama server..."
exec ollama serve
