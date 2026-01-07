#!/bin/bash

# Emo Hallo - Emotional Talking Head Generation System
# This script starts both backend and frontend services

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ===== 禁用代理以连接本地后端 =====
export http_proxy=""
export https_proxy=""
export HTTP_PROXY=""
export HTTPS_PROXY=""


# Configuration
BACKEND_PORT=${EMO_HALLO_BACKEND_PORT:-8001}
BACKEND_HOST="127.0.0.1"
BACKEND_URL="http://$BACKEND_HOST:$BACKEND_PORT"
# 模型加载需要时间，增加重试次数和间隔
HEALTH_CHECK_RETRIES=${EMO_HALLO_HEALTH_CHECK_RETRIES:-20}  # 最多120次重试 = 10分钟
HEALTH_CHECK_INTERVAL=${EMO_HALLO_HEALTH_CHECK_INTERVAL:-60}  # 每5秒检查一次

# Frontend listen address configuration
# 默认为 0.0.0.0 (允许远程访问)
# 如果需要仅本地访问，设置为 127.0.0.1
FRONTEND_LISTEN_ADDRESS=${EMO_HALLO_LISTEN_ADDRESS:-0.0.0.0}

# Python environment configuration
PYTHON_ENV_PATH=${EMO_HALLO_ENV:-/remote-home/JJHe/.conda/envs/mpt}

# GPU configuration
CUDA_VISIBLE_DEVICES=${EMO_HALLO_GPU_ID:-0}  # 指定GPU序号，默认0
export CUDA_VISIBLE_DEVICES

# Logging configuration
# 支持的日志级别: DEBUG, INFO, WARNING, ERROR, CRITICAL
# 优先级: 直接传入的 LOG_LEVEL > EMO_HALLO_LOG_LEVEL 环境变量 > 默认 INFO
LOG_LEVEL=${LOG_LEVEL:-${EMO_HALLO_LOG_LEVEL:-INFO}}
export LOG_LEVEL

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[Hallo2]${NC} $1"
}
print_error() {
    echo -e "${RED}[Hallo2]${NC} $1"
}
print_warning() {
    echo -e "${YELLOW}[Hallo2]${NC} $1"
}
print_info() {
    echo -e "${BLUE}[Hallo2]${NC} $1"
}

# Cleanup function to kill background processes
cleanup() {
    print_warning "Shutting down all services..."

    # Kill health check process first
    if [ ! -z "$HEALTH_CHECK_PID" ] && ps -p "$HEALTH_CHECK_PID" > /dev/null 2>&1; then
        print_info "Stopping health check (PID: $HEALTH_CHECK_PID)..."
        kill -9 "$HEALTH_CHECK_PID" 2>/dev/null || true
    fi

    # Force kill by specific PID (more reliable)
    if [ ! -z "$BACKEND_PID" ]; then
        print_info "Force killing backend (PID: $BACKEND_PID)..."
        kill -9 "$BACKEND_PID" 2>/dev/null || true
    fi

    if [ ! -z "$FRONTEND_PID" ]; then
        print_info "Force killing frontend (PID: $FRONTEND_PID)..."
        kill -9 "$FRONTEND_PID" 2>/dev/null || true
    fi

    # Kill all matching processes by command pattern
    print_warning "Killing all remaining Emo Hallo processes..."

    # Kill uvicorn (backend) - match by module name
    pkill -9 -f "emo_hallo.backend" 2>/dev/null || true
    pkill -9 -f "uvicorn.*8001" 2>/dev/null || true
    pkill -9 -f -- "-m uvicorn" 2>/dev/null || true

    # Kill streamlit (frontend) - match by app
    pkill -9 -f "emo_hallo/Main.py" 2>/dev/null || true
    pkill -9 -f "streamlit" 2>/dev/null || true

    # Kill any remaining python processes related to emo_hallo
    pkill -9 -f "emo_hallo" 2>/dev/null || true

    # Final catch-all: check and kill any remaining processes on specific ports
    if lsof -Pi :8001 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "Port 8001 still in use, force killing..."
        PIDS=$(lsof -t -i :8001 2>/dev/null)
        if [ ! -z "$PIDS" ]; then
            echo "$PIDS" | xargs kill -9 2>/dev/null || true
        fi
    fi

    if lsof -Pi :8501 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "Port 8501 still in use, force killing..."
        PIDS=$(lsof -t -i :8501 2>/dev/null)
        if [ ! -z "$PIDS" ]; then
            echo "$PIDS" | xargs kill -9 2>/dev/null || true
        fi
    fi

    sleep 1
    print_status "All services stopped"
    exit 0
}

# Variable to track health check process
HEALTH_CHECK_PID=""

# Set up signal handlers
trap cleanup SIGINT SIGTERM EXIT

# Print startup information
print_status "Starting Emo Hallo - Emotional Talking Head Generation System"
print_info "This will start both backend and frontend services simultaneously"
print_status ""
print_info "Configuration:"
print_info "  Backend Port:  $BACKEND_PORT"
print_info "  GPU ID:        $CUDA_VISIBLE_DEVICES"
print_info "  Log Level:     $LOG_LEVEL"
print_status ""

# Setup Python commands
PYTHON_CMD="$PYTHON_ENV_PATH/bin/python"
STREAMLIT_CMD="$PYTHON_ENV_PATH/bin/streamlit"
print_info "Python environment: $PYTHON_ENV_PATH"
print_status ""

# Create logs directory
mkdir -p "$SCRIPT_DIR/logs"
BACKEND_LOG="$SCRIPT_DIR/logs/backend.log"
FRONTEND_LOG="$SCRIPT_DIR/logs/frontend.log"

# Convert LOG_LEVEL to lowercase for services (uvicorn and Streamlit)
UVICORN_LOG_LEVEL=$(echo "$LOG_LEVEL" | tr '[:upper:]' '[:lower:]')
STREAMLIT_LOG_LEVEL=$(echo "$LOG_LEVEL" | tr '[:upper:]' '[:lower:]')

# Set backend URL environment variable for frontend
export BACKEND_URL="$BACKEND_URL"

# Kill any existing Streamlit processes to prevent port conflicts
if pgrep -f "streamlit run" > /dev/null 2>&1; then
    print_warning "Stopping existing Streamlit instances..."
    pkill -9 -f "streamlit run" 2>/dev/null || true
    sleep 3
fi

# Double-check port 8501 is free
if lsof -Pi :8501 -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_warning "Port 8501 still in use, force killing..."
    PIDS=$(lsof -t -i :8501 2>/dev/null)
    if [ ! -z "$PIDS" ]; then
        echo "$PIDS" | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
fi

# ========== Start Frontend First ==========
print_status "Starting Streamlit frontend service..."

# Configure Streamlit via environment variables to disable file watching
export STREAMLIT_SERVER_RUN_ON_SAVE=false
export STREAMLIT_SERVER_HEADLESS=true
export STREAMLIT_LOGGER_LEVEL=error
export STREAMLIT_CLIENT_SHOW_ERROR_DETAILS=true
export STREAMLIT_SERVER_MAX_UPLOAD_SIZE=500
export STREAMLIT_SERVER_ENABLE_XSRF_PROTECTION=true
export STREAMLIT_BROWSER_SERVER_ADDRESS="0.0.0.0"
export STREAMLIT_BROWSER_GATHER_USAGE_STATS=false
export STREAMLIT_SERVER_ENABLE_CORS=true

# CRITICAL: Force watchdog to use polling instead of inotify
# This avoids "inotify watch limit reached" errors when Streamlit tries to watch files
export USE_POLLING_OBSERVER=true

# Start Streamlit in subprocess with clean HOME and polling
bash -c '
  export HOME=$(mktemp -d -p /tmp)
  export USE_POLLING_OBSERVER=true
  '"$STREAMLIT_CMD"' run ./emo_hallo/Main.py \
    --server.port=8501 \
    --logger.level=error \
    --client.toolbarMode=minimal > '"$FRONTEND_LOG"' 2>&1
  rm -rf $HOME
' &

FRONTEND_PID=$!
print_status "Frontend PID: $FRONTEND_PID"
print_info "Frontend logs: $FRONTEND_LOG"

# ========== Start Backend Second ==========
# Check if backend is already running
if lsof -Pi :$BACKEND_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_warning "Backend already running on port $BACKEND_PORT, skipping..."
    BACKEND_PID=$(lsof -t -i :$BACKEND_PORT)
else
    # Start backend service
    print_status "Starting Hallo2 backend service..."

    # 确保 LOG_LEVEL 被正确传递到子进程
    export LOG_LEVEL="$LOG_LEVEL"

    # Launch backend in background with unbuffered output
    PYTHONUNBUFFERED=1 stdbuf -oL -eL $PYTHON_CMD -u -m uvicorn emo_hallo.backend.app:app \
        --host "0.0.0.0" \
        --port "$BACKEND_PORT" \
        --log-level "$UVICORN_LOG_LEVEL" \
        >> "$BACKEND_LOG" 2>&1 &

    BACKEND_PID=$!
    print_status "Backend PID: $BACKEND_PID"
    print_info "Backend logs: $BACKEND_LOG"
fi

# ========== 后台启动健康检查 ==========
# 在后台监控后端就绪状态（不阻塞前端启动）
(
    print_status "Waiting for backend to be fully ready..."
    print_warning "Backend is loading Hallo2 model (this takes ~5-10 minutes on first run)"
    print_info "Check logs for detailed progress: tail -f $BACKEND_LOG"

    RETRY_COUNT=0
    MAX_WAIT_TIME=$((HEALTH_CHECK_RETRIES * HEALTH_CHECK_INTERVAL))
    BACKEND_READY=false

    while [ $RETRY_COUNT -lt $HEALTH_CHECK_RETRIES ]; do
        if curl -s "$BACKEND_URL/health" > /dev/null 2>&1; then
            print_status "✓ Backend is ready!"
            BACKEND_READY=true
            break
        fi

        RETRY_COUNT=$((RETRY_COUNT + 1))
        ELAPSED=$((RETRY_COUNT * HEALTH_CHECK_INTERVAL))

        # Print progress every few attempts
        if [ $((RETRY_COUNT % 2)) -eq 0 ]; then
            PERCENT=$((RETRY_COUNT * 100 / HEALTH_CHECK_RETRIES))
            echo "  [$RETRY_COUNT/$HEALTH_CHECK_RETRIES] Waiting... (${ELAPSED}s elapsed - Check logs/backend.log for progress)"
        fi

        sleep $HEALTH_CHECK_INTERVAL
    done

    if [ "$BACKEND_READY" = false ]; then
        print_error "✗ Backend failed to start after $HEALTH_CHECK_RETRIES retries (${MAX_WAIT_TIME}s)"
        print_error "Check logs for details:"
        print_error "  tail -f $BACKEND_LOG"
    fi
) &

# Capture health check process PID so we can kill it on cleanup
HEALTH_CHECK_PID=$!

# 自动初始化前端页面（触发Streamlit脚本执行）
print_info "Initializing frontend..."
(
    sleep 5  # 等待Streamlit完全启动
    for i in {1..10}; do
        if curl -s "http://localhost:8501" > /dev/null 2>&1; then
            print_info "✓ Frontend initialized successfully"
            break
        fi
        if [ $i -eq 10 ]; then
            print_warning "⚠️ Frontend initialization timeout (may still be loading)"
        fi
        sleep 2
    done
) &

# Print summary (前端启动后立即显示)
echo ""
echo ""
print_status "========================================="
print_status "✅ Emo Hallo Services Started Successfully!"
print_status "========================================="
echo ""
print_status "📱 FRONTEND - How to Access:"
if [ "$FRONTEND_LISTEN_ADDRESS" = "127.0.0.1" ]; then
    print_info "   Local access only (default configuration):"
    print_info ""
    print_info "   ✓ http://localhost:8501"
    print_info "   ✓ http://127.0.0.1:8501"
    print_info ""
    print_info "   For remote access from other machines:"
    print_info "   EMO_HALLO_LISTEN_ADDRESS=0.0.0.0 bash emohallo.sh"
else
    print_info "   Accessible from any machine:"
    print_info ""
    print_info "   ✓ Local:            http://localhost:8501"
    print_info "   ✓ From other PCs:   http://<your-server-ip>:8501"
    print_info ""
fi
print_info ""
print_status "⚙️  BACKEND - API Server:"
print_info "   http://127.0.0.1:$BACKEND_PORT"
print_info ""
print_warning "⏳ IMPORTANT - Backend Status:"
print_warning "   Backend is loading Hallo2 model in background"
print_warning "   Time: 5-10 minutes on first run"
print_warning ""
print_warning "   Check progress with:"
print_warning "   tail -f logs/backend.log"
print_info ""
print_info "📋 View Service Logs (in another terminal):"
print_info "   • Backend:  tail -f logs/backend.log"
print_info "   • Frontend: tail -f logs/frontend.log"
print_info ""
print_info "🔧 Configuration:"
print_info "   Change log level: LOG_LEVEL=DEBUG bash emohallo.sh"
print_info ""
print_info "⛔ Stop all services: Press Ctrl+C"
print_status "========================================="
echo ""

# Wait for all services
wait
