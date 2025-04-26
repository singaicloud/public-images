#!/bin/bash

# Set log files
LOG_FILE="/app/logs/ollama.log"
ERROR_LOG="/app/logs/error.log"
SYSTEM_INFO="/app/logs/system_info.log"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE" "$ERROR_LOG" "$SYSTEM_INFO"

# Model name mapping
# Set model, handle different model format inputs
RAW_MODEL_NAME=${MODEL_NAME:-"llama2:7b"}

# Map generic model names to their specific Ollama model names
case "$RAW_MODEL_NAME" in
    "llama2:7b" | "llama2" )
        OLLAMA_MODEL_NAME="llama2:7b"
        ;;
    "deepseek:7b" | "deepseek" )
        OLLAMA_MODEL_NAME="deepseek-llm:7b"
        ;;
    "codellama:7b" | "codellama" )
        OLLAMA_MODEL_NAME="codellama:7b"
        ;;
    "qwen:7b" | "qwen" )
        OLLAMA_MODEL_NAME="qwen:7b"
        ;;
    * )
        # If the model name doesn't match any known pattern, use it as-is
        OLLAMA_MODEL_NAME="$RAW_MODEL_NAME"
        ;;
esac

# Print system information
function log_system_info() {
  echo "==================== SYSTEM INFORMATION ====================" > "$SYSTEM_INFO"
  echo "Date: $(date)" >> "$SYSTEM_INFO"
  echo "Hostname: $(hostname)" >> "$SYSTEM_INFO"
  echo "Kernel version: $(uname -a)" >> "$SYSTEM_INFO"
  echo "Input model name: $RAW_MODEL_NAME" >> "$SYSTEM_INFO"
  echo "Mapped model name: $OLLAMA_MODEL_NAME" >> "$SYSTEM_INFO"
  
  # GPU information
  if command -v nvidia-smi &> /dev/null; then
    echo "GPU information:" >> "$SYSTEM_INFO"
    nvidia-smi >> "$SYSTEM_INFO" 2>&1 || echo "nvidia-smi command failed" >> "$SYSTEM_INFO"
  else
    echo "No NVIDIA GPU detected" >> "$SYSTEM_INFO"
  fi
  
  # Memory and disk information
  echo "Memory information:" >> "$SYSTEM_INFO"
  free -h >> "$SYSTEM_INFO"
  echo "Disk space:" >> "$SYSTEM_INFO"
  df -h >> "$SYSTEM_INFO"
  
  echo "Ollama version:" >> "$SYSTEM_INFO"
  ollama --version >> "$SYSTEM_INFO" 2>&1 || echo "Unable to get Ollama version" >> "$SYSTEM_INFO"
  
  echo "==================== END SYSTEM INFORMATION ====================" >> "$SYSTEM_INFO"
}

# Logging functions
function log() {
  local message="$1"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] $message" >> "$LOG_FILE"
  echo "[$timestamp] $message"
}

function log_error() {
  local message="$1"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] ERROR: $message" >> "$ERROR_LOG"
  echo "[$timestamp] ERROR: $message" >&2
}

# Main function
function main() {
  log_system_info
  log "Starting Ollama service..."
  
  # Start Ollama
  ollama serve > /dev/null 2>&1 &
  OLLAMA_PID=$!
  log "Ollama service started, PID: $OLLAMA_PID"
  
  # Wait for service to be ready
  log "Waiting for Ollama service to be ready..."
  local ready=false
  for i in {1..30}; do
    if curl -s http://localhost:11434/api/health &>/dev/null; then
      ready=true
      break
    fi
    sleep 1
  done
  
  if [ "$ready" = false ]; then
    log_error "Ollama service not ready within expected time, please check logs"
    exit 1
  fi
  
  log "Ollama service is ready"
  
  # Pull model
  log "Pulling model: $OLLAMA_MODEL_NAME"
  if ! ollama pull "$OLLAMA_MODEL_NAME"; then
    log_error "Failed to pull model $OLLAMA_MODEL_NAME"
    log "This may be due to an incorrect model name or network issues."
    log "Available models can be found at: https://ollama.ai/library"
    log "Container will continue running, but you'll need to manually pull a model."
    # Don't exit so the container stays running for manual intervention
  else
    log "Model $OLLAMA_MODEL_NAME pulled successfully"
  fi
  
  # Create simple test script
  cat > /app/test_model.sh << 'EOFS'
#!/bin/bash
# Simple model test script
if [ -z "$1" ]; then
  # Get the model name from the running container
  MODEL=$(ollama list | awk 'NR>1 {print $1; exit}')
  if [ -z "$MODEL" ]; then
    echo "No models found. Please pull a model first using 'ollama pull MODEL_NAME'"
    exit 1
  fi
else
  MODEL="$1"
fi

PROMPT="${2:-"Please introduce yourself briefly"}"
echo "Testing model: $MODEL"
echo "Prompt: $PROMPT"
curl -s "http://localhost:11434/api/generate" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$MODEL\",\"prompt\":\"$PROMPT\"}" | \
    grep -o '"response":"[^"]*"' | sed 's/"response":"//;s/"//'
EOFS
  chmod +x /app/test_model.sh
  
  # Create helper scripts
  cat > /app/list_models.sh << 'EOFS'
#!/bin/bash
# List available models
echo "Locally available models:"
ollama list

echo -e "\nTo pull a new model, use: ollama pull MODEL_NAME"
echo "For example: ollama pull llama2:7b"
echo "For a list of available models, visit: https://ollama.ai/library"
EOFS
  chmod +x /app/list_models.sh
  
  log "Ollama service startup complete, accessible via http://localhost:11434"
  log "Available model: $OLLAMA_MODEL_NAME (if pull was successful)"
  log "To test the model, use: /app/test_model.sh"
  log "To list available models, use: /app/list_models.sh"
  
  # Keep container running
  tail -f /dev/null
}

# Execute main function
main