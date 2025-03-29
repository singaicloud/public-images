#!/bin/bash

# 设置日志文件
LOG_FILE="/app/logs/ollama.log"
ERROR_LOG="/app/logs/error.log"
SYSTEM_INFO="/app/logs/system_info.log"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE" "$ERROR_LOG" "$SYSTEM_INFO"

# 打印系统信息
function log_system_info() {
  echo "==================== 系统信息 ====================" > "$SYSTEM_INFO"
  echo "日期: $(date)" >> "$SYSTEM_INFO"
  echo "主机名: $(hostname)" >> "$SYSTEM_INFO"
  echo "内核版本: $(uname -a)" >> "$SYSTEM_INFO"
  echo "CPU信息:" >> "$SYSTEM_INFO"
  lscpu 2>/dev/null >> "$SYSTEM_INFO" || echo "无法获取CPU信息" >> "$SYSTEM_INFO"
  echo "GPU信息:" >> "$SYSTEM_INFO"
  if command -v nvidia-smi &> /dev/null; then
    nvidia-smi 2>/dev/null >> "$SYSTEM_INFO" || echo "nvidia-smi命令失败" >> "$SYSTEM_INFO"
  else
    echo "未发现NVIDIA GPU或驱动" >> "$SYSTEM_INFO"
  fi
  echo "内存信息:" >> "$SYSTEM_INFO"
  free -h >> "$SYSTEM_INFO"
  echo "磁盘空间:" >> "$SYSTEM_INFO"
  df -h >> "$SYSTEM_INFO"
  echo "环境变量:" >> "$SYSTEM_INFO"
  env >> "$SYSTEM_INFO"
  echo "==================== 结束系统信息 ====================" >> "$SYSTEM_INFO"
}

log_system_info

# 打印Ollama版本
if command -v ollama &> /dev/null; then
  ollama --version >> "$SYSTEM_INFO" 2>&1 || echo "无法获取Ollama版本" >> "$SYSTEM_INFO"
else
  echo "Ollama未安装或不在PATH中" >> "$SYSTEM_INFO"
fi

# 日志函数
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

# 启动Ollama服务
function start_ollama_service() {
  log "启动Ollama服务..."
  # 以守护进程方式启动Ollama
  ollama serve > /dev/null 2>&1 &
  # 保存PID
  OLLAMA_PID=$!
  log "Ollama服务启动，PID: $OLLAMA_PID"
}

# 检查Ollama服务是否运行
function check_ollama_service() {
  # 等待服务启动
  local max_attempts=30
  local attempt=1
  local is_running=false
  
  log "等待Ollama服务就绪..."
  
  while [ $attempt -le $max_attempts ]; do
    if curl -s http://localhost:11434/api/health &>/dev/null; then
      log "Ollama服务已就绪！"
      is_running=true
      break
    fi
    
    sleep 1
    attempt=$((attempt + 1))
  done
  
  if ! $is_running; then
    log_error "Ollama服务未能在预期时间内就绪"
    return 1
  fi
  
  return 0
}

# 下载/拉取模型
function pull_model() {
  if [ -z "$MODEL_NAME" ]; then
    log_error "未指定MODEL_NAME环境变量"
    return 1
  fi
  
  log "开始拉取模型: $MODEL_NAME"
  
  # 进行多次尝试
  local max_attempts=3
  local attempt=1
  local success=false
  
  while [ $attempt -le $max_attempts ]; do
    log "尝试 $attempt/$max_attempts: 拉取模型 $MODEL_NAME"
    
    if ollama pull "$MODEL_NAME" > /dev/null 2>&1; then
      log "模型 $MODEL_NAME 拉取成功"
      success=true
      break
    else
      log_error "尝试 $attempt: 拉取模型 $MODEL_NAME 失败"
    fi
    
    attempt=$((attempt + 1))
    sleep 5
  done
  
  if ! $success; then
    log_error "无法拉取模型 $MODEL_NAME，已达到最大尝试次数"
    return 1
  fi
  
  return 0
}

# 启动服务
function start_services() {
  # 启动Ollama服务
  start_ollama_service
  
  # 检查Ollama服务是否运行
  if ! check_ollama_service; then
    log_error "Ollama服务启动失败"
    exit 1
  fi
  
  # 拉取模型
  if ! pull_model; then
    log_error "模型拉取失败"
    exit 1
  fi
  
  log "服务启动成功"
}

# 创建API测试脚本
function create_test_script() {
  local test_script="/app/test_api.sh"
  log "创建API测试脚本: $test_script"
  
  cat > "$test_script" << 'EOF'
#!/bin/bash
# Ollama API测试脚本

# 设置默认值
HOST="localhost"
PORT="11434"
MODEL_NAME="${MODEL_NAME:-llama2}"
PROMPT="简单介绍一下你自己"

# 检查curl是否可用
if ! command -v curl &> /dev/null; then
    echo "错误: 需要curl命令，但未安装。"
    exit 1
fi

# 显示帮助信息
function show_help() {
    echo "使用方法: $0 [选项]"
    echo "选项:"
    echo "  -h, --host      API主机 (默认: $HOST)"
    echo "  -p, --port      API端口 (默认: $PORT)"
    echo "  -m, --model     模型名称 (默认: $MODEL_NAME)"
    echo "  -t, --text      提示文本 (默认: \"$PROMPT\")"
    echo "  --help          显示此帮助信息"
    exit 0
}

# 解析命令行参数
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--host) HOST="$2"; shift ;;
        -p|--port) PORT="$2"; shift ;;
        -m|--model) MODEL_NAME="$2"; shift ;;
        -t|--text) PROMPT="$2"; shift ;;
        --help) show_help ;;
        *) echo "未知参数: $1"; show_help ;;
    esac
    shift
done

echo "发送API请求到 http://${HOST}:${PORT}/api/generate..."
echo "模型: $MODEL_NAME"
echo "提示: \"$PROMPT\""
echo "请稍候..."

# 发送请求
curl -s "http://${HOST}:${PORT}/api/generate" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"${MODEL_NAME}\",\"prompt\":\"${PROMPT}\"}" | \
    jq -r '.response' 2>/dev/null || echo "请求失败或结果解析错误"

echo -e "\n测试完成"
EOF
  
  chmod +x "$test_script"
  log "API测试脚本已创建"
}

# 主函数
function main() {
  log "=== 开始启动Ollama服务 ==="
  
  # 创建必要的目录
  mkdir -p /root/.ollama

  # 启动服务
  start_services
  
  # 创建API测试脚本
  create_test_script
  
  log "=== Ollama服务启动完成，可通过 http://localhost:11434 访问 ==="
  
  # 保持容器运行
  if [[ "${1}" != "--no-wait" ]]; then
    tail -f /dev/null
  fi
}

# 执行主函数
main "$@" 