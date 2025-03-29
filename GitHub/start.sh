#!/bin/bash

# Set log files
LOG_FILE="/app/logs/ollama.log"
ERROR_LOG="/app/logs/error.log"
SYSTEM_INFO="/app/logs/system_info.log"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE" "$ERROR_LOG" "$SYSTEM_INFO"

# Print system information
function log_system_info() {
  echo "==================== SYSTEM INFORMATION ====================" > "$SYSTEM_INFO"
  echo "Date: $(date)" >> "$SYSTEM_INFO"
  echo "Hostname: $(hostname)" >> "$SYSTEM_INFO"
  echo "Kernel version: $(uname -a)" >> "$SYSTEM_INFO"
  echo "CPU information:" >> "$SYSTEM_INFO"
  lscpu 2>/dev/null >> "$SYSTEM_INFO" || echo "Unable to get CPU information" >> "$SYSTEM_INFO"
  echo "GPU information:" >> "$SYSTEM_INFO"
  if command -v nvidia-smi &> /dev/null; then
    nvidia-smi 2>/dev/null >> "$SYSTEM_INFO" || echo "nvidia-smi command failed" >> "$SYSTEM_INFO"
  else
    echo "No NVIDIA GPU or driver detected" >> "$SYSTEM_INFO"
  fi
  echo "Memory information:" >> "$SYSTEM_INFO"
  free -h >> "$SYSTEM_INFO"
  echo "Disk space:" >> "$SYSTEM_INFO"
  df -h >> "$SYSTEM_INFO"
  echo "Environment variables:" >> "$SYSTEM_INFO"
  env >> "$SYSTEM_INFO"
  echo "==================== END SYSTEM INFORMATION ====================" >> "$SYSTEM_INFO"
}

log_system_info

# Print Ollama version
if command -v ollama &> /dev/null; then
  ollama --version >> "$SYSTEM_INFO" 2>&1 || echo "Unable to get Ollama version" >> "$SYSTEM_INFO"
else
  echo "Ollama not installed or not in PATH" >> "$SYSTEM_INFO"
fi

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

# Start Ollama service
function start_ollama_service() {
  log "Starting Ollama service..."
  # Start Ollama as a daemon
  ollama serve > /dev/null 2>&1 &
  # Save PID
  OLLAMA_PID=$!
  log "Ollama service started, PID: $OLLAMA_PID"
}

# Check if Ollama service is running
function check_ollama_service() {
  # Wait for service to start
  local max_attempts=30
  local attempt=1
  local is_running=false
  
  log "Waiting for Ollama service to be ready..."
  
  while [ $attempt -le $max_attempts ]; do
    if curl -s http://localhost:11434/api/health &>/dev/null; then
      log "Ollama service is ready!"
      is_running=true
      break
    fi
    
    sleep 1
    attempt=$((attempt + 1))
  done
  
  if ! $is_running; then
    log_error "Ollama service not ready within expected time"
    return 1
  fi
  
  return 0
}

# Download/pull model
function pull_model() {
  if [ -z "$MODEL_NAME" ]; then
    log_error "MODEL_NAME environment variable not specified"
    return 1
  fi
  
  log "Starting to pull model: $MODEL_NAME"
  
  # Multiple attempts
  local max_attempts=3
  local attempt=1
  local success=false
  
  while [ $attempt -le $max_attempts ]; do
    log "Attempt $attempt/$max_attempts: pulling model $MODEL_NAME"
    
    if ollama pull "$MODEL_NAME" > /dev/null 2>&1; then
      log "Model $MODEL_NAME pulled successfully"
      success=true
      break
    else
      log_error "Attempt $attempt: failed to pull model $MODEL_NAME"
    fi
    
    attempt=$((attempt + 1))
    sleep 5
  done
  
  if ! $success; then
    log_error "Unable to pull model $MODEL_NAME, maximum attempts reached"
    return 1
  fi
  
  return 0
}

# Start services
function start_services() {
  # Start Ollama service
  start_ollama_service
  
  # Check if Ollama service is running
  if ! check_ollama_service; then
    log_error "Ollama service startup failed"
    exit 1
  fi
  
  # Pull model
  if ! pull_model; then
    log_error "Model pull failed"
    exit 1
  fi
  
  log "Services started successfully"
}

# Create API test script
function create_test_script() {
  local test_script="/app/test_api.sh"
  log "Creating API test script: $test_script"
  
  cat > "$test_script" << 'EOF'
#!/bin/bash
# Ollama API Test Script

# Default values
HOST="localhost"
PORT="11434"
MODEL_NAME="${MODEL_NAME:-llama2}"
PROMPT="Please introduce yourself briefly"

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo "Error: curl command required but not installed."
    exit 1
fi

# Display help information
function show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --host      API host (default: $HOST)"
    echo "  -p, --port      API port (default: $PORT)"
    echo "  -m, --model     Model name (default: $MODEL_NAME)"
    echo "  -t, --text      Prompt text (default: \"$PROMPT\")"
    echo "  --help          Show this help information"
    exit 0
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--host) HOST="$2"; shift ;;
        -p|--port) PORT="$2"; shift ;;
        -m|--model) MODEL_NAME="$2"; shift ;;
        -t|--text) PROMPT="$2"; shift ;;
        --help) show_help ;;
        *) echo "Unknown parameter: $1"; show_help ;;
    esac
    shift
done

echo "Sending API request to http://${HOST}:${PORT}/api/generate..."
echo "Model: $MODEL_NAME"
echo "Prompt: \"$PROMPT\""
echo "Please wait..."

# Send request
curl -s "http://${HOST}:${PORT}/api/generate" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"${MODEL_NAME}\",\"prompt\":\"${PROMPT}\"}" | \
    jq -r '.response' 2>/dev/null || echo "Request failed or error parsing result"

echo -e "\nTest completed"
EOF
  
  chmod +x "$test_script"
  log "API test script created"
}

# Main function
function main() {
  log "=== Starting Ollama service ==="
  
  # Create necessary directories
  mkdir -p /root/.ollama

  # Start services
  start_services
  
  # Create API test script
  create_test_script
  
  log "=== Ollama service startup complete, accessible via http://localhost:11434 ==="
  
  # Keep container running
  if [[ "${1}" != "--no-wait" ]]; then
    tail -f /dev/null
  fi
}

# Execute main function
main "$@" 