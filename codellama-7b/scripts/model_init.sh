#!/bin/bash

# Set environment variables
MODEL_NAME=${MODEL_NAME:-"codellama:7b"}
MODEL_PATH="/root/.ollama/models"

# Logging function
function log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Ensure directory exists
mkdir -p $MODEL_PATH

# Skip download if model already exists
if [ -d "$MODEL_PATH/$MODEL_NAME" ]; then
  log "Model $MODEL_NAME already exists, skipping download."
  exit 0
fi

# Log system information
log "Initializing CodeLlama 7B model..."
log "Hardware information:"
if command -v nvidia-smi &> /dev/null; then
  nvidia-smi
else
  log "No NVIDIA GPU detected"
fi

# Log memory information
log "Memory information:"
free -h

# Try to download model
log "Pre-downloading model $MODEL_NAME..."

# Start Ollama service temporarily
ollama serve > /dev/null 2>&1 &
OLLAMA_PID=$!
log "Temporary Ollama service started, PID: $OLLAMA_PID"

# Wait for service to start
sleep 5

# Try to pull model
MAX_RETRIES=3
RETRY_COUNT=0
SUCCESS=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  log "Attempting to pull model (attempt $((RETRY_COUNT+1))/$MAX_RETRIES)..."
  if ollama pull $MODEL_NAME; then
    SUCCESS=true
    break
  else
    RETRY_COUNT=$((RETRY_COUNT+1))
    log "Pull failed, waiting 10 seconds before retry..."
    sleep 10
  fi
done

# Shutdown temporary Ollama service
if [ -n "$OLLAMA_PID" ]; then
  kill $OLLAMA_PID
  log "Temporary Ollama service shutdown"
fi

if [ "$SUCCESS" = true ]; then
  log "Model $MODEL_NAME successfully initialized"
else
  log "Model initialization failed, will retry during container startup"
fi

exit 0 