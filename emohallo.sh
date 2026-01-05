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

    # Kill backend process and all its children
    if [ ! -z "$BACKEND_PID" ]; then
        print_info "Stopping backend (PID: $BACKEND_PID)..."
        # Kill process group to ensure all children are killed
        kill -TERM -$BACKEND_PID 2>/dev/null || kill -TERM $BACKEND_PID 2>/dev/null || true
        wait $BACKEND_PID 2>/dev/null || true
    fi

    # Kill frontend process
    if [ ! -z "$FRONTEND_PID" ]; then
        print_info "Stopping frontend (PID: $FRONTEND_PID)..."
        kill -TERM $FRONTEND_PID 2>/dev/null || true
        wait $FRONTEND_PID 2>/dev/null || true
    fi

    # Give processes time to exit gracefully
    sleep 1

    # Kill any remaining processes by pattern - multiple attempts
    # Target uvicorn backend
    if pgrep -f "uvicorn.*emo_hallo" > /dev/null 2>&1; then
        print_warning "Force killing remaining backend processes..."
        pkill -9 -f "uvicorn" 2>/dev/null || true
        sleep 0.5
        pkill -9 -f "python.*emo_hallo" 2>/dev/null || true
    fi

    # Target streamlit frontend
    if pgrep -f "streamlit run" > /dev/null 2>&1; then
        print_warning "Force killing remaining frontend processes..."
        pkill -9 -f "streamlit" 2>/dev/null || true
        sleep 0.5
        pkill -9 -f "_stream" 2>/dev/null || true
    fi

    # Final verification - kill all remaining emo_hallo related processes
    pkill -9 -f "emo_hallo" 2>/dev/null || true

    sleep 1
    print_status "All services stopped"
    exit 0
}

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
    pkill -f "streamlit run" 2>/dev/null || true
    sleep 2
fi

# ========== Start Frontend First ==========
print_status "Starting Streamlit frontend service..."

# Configure Streamlit via environment variables
export STREAMLIT_SERVER_RUN_ON_SAVE=false
export STREAMLIT_SERVER_HEADLESS=true
export STREAMLIT_LOGGER_LEVEL="$STREAMLIT_LOG_LEVEL"
export STREAMLIT_SERVER_MAX_UPLOAD_SIZE=500
export STREAMLIT_BROWSER_SERVER_ADDRESS="0.0.0.0"
export STREAMLIT_SERVER_ENABLE_CORS=true

# Start Streamlit directly (no bash wrapper to avoid log issues)
$STREAMLIT_CMD run ./emo_hallo/Main.py \
    --logger.level="$STREAMLIT_LOG_LEVEL" \
    --client.toolbarMode=minimal >> "$FRONTEND_LOG" 2>&1 &

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

# Print summary (前端启动后立即显示)
echo ""
print_status "========================================="
print_status "✅ Both services are running!"
print_status "========================================="
print_info "Frontend URL:  http://0.0.0.0:8501"
print_info "Backend URL:   http://127.0.0.1:$BACKEND_PORT"
print_info ""
print_info "View logs (in another terminal):"
print_info "  • Backend:  tail -f logs/backend.log"
print_info "  • Frontend: tail -f logs/frontend.log"
print_info ""
print_info "To change log level, use environment variable:"
print_info "  LOG_LEVEL=DEBUG bash emohallo.sh"
print_info "  EMO_HALLO_LOG_LEVEL=DEBUG bash emohallo.sh"
print_info ""
print_info "Press Ctrl+C to stop all services"
print_status "========================================="
echo ""

# Wait for all services
wait