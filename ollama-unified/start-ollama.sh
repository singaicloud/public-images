#!/bin/bash

# Start SSH service
service ssh start

# Check for environment variables that would indicate distributed setup
if [ ! -z "$SING_RANK" ] && [ ! -z "$SING_WORLD_SIZE" ] && [ ! -z "$SING_MASTER_ADDR" ]; then
    echo "Detected distributed environment settings"
    echo "RANK: $SING_RANK"
    echo "WORLD_SIZE: $SING_WORLD_SIZE"
    echo "MASTER_ADDR: $SING_MASTER_ADDR"
    
    # Set up Ollama environment variables if needed for distributed setup
    # Currently Ollama doesn't have built-in distributed training support,
    # but these variables are kept for future compatibility or custom implementations
    export OLLAMA_HOST="0.0.0.0"
    
    # If not the master node, wait for master to be ready
    if [ "$SING_RANK" != "0" ]; then
        echo "This is a worker node. Waiting for master node to be ready..."
        # Simple check to see if master is ready - can be improved
        while ! ping -c 1 -W 1 $SING_MASTER_ADDR &> /dev/null; do
            echo "Waiting for master node to be reachable..."
            sleep 5
        done
    fi
fi

# Check if a specific model should be pulled at startup
if [ ! -z "$OLLAMA_MODEL" ]; then
    echo "Pulling model $OLLAMA_MODEL at startup"
    ollama pull $OLLAMA_MODEL
fi

# Start Ollama service
echo "Starting Ollama server..."
exec ollama serve
