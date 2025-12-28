#!/bin/bash

# Emo Hallo - Emotional Talking Head Generation System
# This script starts both backend and frontend services

# If you could not download the model from the official site, you can use the mirror site.
# Just remove the comment of the following line .
# 如果你无法从官方网站下载模型，你可以使用镜像网站。
# 只需要移除下面一行的注释即可。

# export HF_ENDPOINT=https://hf-mirror.com

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration
BACKEND_PORT=${EMO_HALLO_BACKEND_PORT:-8001}
BACKEND_HOST="127.0.0.1"
BACKEND_URL="http://$BACKEND_HOST:$BACKEND_PORT"
# 模型加载需要时间，增加重试次数和间隔
HEALTH_CHECK_RETRIES=${EMO_HALLO_HEALTH_CHECK_RETRIES:-20}  # 最多120次重试 = 10分钟
HEALTH_CHECK_INTERVAL=${EMO_HALLO_HEALTH_CHECK_INTERVAL:-60}  # 每5秒检查一次

# Python environment configuration
BACKEND_ENV_PATH=${EMO_HALLO_BACKEND_ENV:-/remote-home/JJHe/.conda/envs/mpt}
FRONTEND_ENV_PATH=${EMO_HALLO_FRONTEND_ENV:-/remote-home/JJHe/.conda/envs/mpt}

# GPU configuration
CUDA_VISIBLE_DEVICES=${EMO_HALLO_GPU_ID:-0}  # 指定GPU序号，默认0
export CUDA_VISIBLE_DEVICES

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Cleanup function to kill background processes
cleanup() {
    print_warning "Shutting down..."

    if [ ! -z "$BACKEND_PID" ]; then
        print_status "Stopping backend (PID: $BACKEND_PID)..."
        kill $BACKEND_PID 2>/dev/null
        wait $BACKEND_PID 2>/dev/null
        print_status "Backend stopped"
    fi

    if [ ! -z "$FRONTEND_PID" ]; then
        print_status "Stopping frontend (PID: $FRONTEND_PID)..."
        kill $FRONTEND_PID 2>/dev/null
        wait $FRONTEND_PID 2>/dev/null
        print_status "Frontend stopped"
    fi

    print_status "Shutdown complete"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM EXIT

# Specify Python environments for backend and frontend
print_status "Configuring Python environments..."
print_status "GPU ID: $CUDA_VISIBLE_DEVICES"

# Backend environment
if [ -f "$BACKEND_ENV_PATH/bin/python" ]; then
    BACKEND_PYTHON_CMD="$BACKEND_ENV_PATH/bin/python"
    print_status "Backend Python: $BACKEND_ENV_PATH"
elif [ -f "$SCRIPT_DIR/venv/bin/python" ]; then
    BACKEND_PYTHON_CMD="$SCRIPT_DIR/venv/bin/python"
    print_status "Backend Python: $SCRIPT_DIR/venv"
else
    BACKEND_PYTHON_CMD="python"
    print_status "Backend Python: system"
fi

# Frontend environment
if [ -f "$FRONTEND_ENV_PATH/bin/python" ]; then
    FRONTEND_PYTHON_CMD="$FRONTEND_ENV_PATH/bin/python"
    STREAMLIT_CMD="$FRONTEND_ENV_PATH/bin/streamlit"
    print_status "Frontend Python: $FRONTEND_ENV_PATH"
elif [ -f "$SCRIPT_DIR/venv/bin/python" ]; then
    FRONTEND_PYTHON_CMD="$SCRIPT_DIR/venv/bin/python"
    STREAMLIT_CMD="$SCRIPT_DIR/venv/bin/streamlit"
    print_status "Frontend Python: $SCRIPT_DIR/venv"
else
    FRONTEND_PYTHON_CMD="python"
    STREAMLIT_CMD="streamlit"
    print_status "Frontend Python: system"
fi

# Check if Python is available
if ! $BACKEND_PYTHON_CMD --version &> /dev/null; then
    print_error "Backend Python not found at: $BACKEND_ENV_PATH"
    print_error "Available Conda environments:"
    conda env list | grep -v "^#" || echo "  (conda not found)"
    exit 1
fi

if ! $FRONTEND_PYTHON_CMD --version &> /dev/null; then
    print_error "Frontend Python not found at: $FRONTEND_ENV_PATH"
    exit 1
fi

BACKEND_VERSION=$($BACKEND_PYTHON_CMD --version)
FRONTEND_VERSION=$($FRONTEND_PYTHON_CMD --version)
print_status "Backend: $BACKEND_VERSION"
print_status "Frontend: $FRONTEND_VERSION"

# Check if backend is already running
if lsof -Pi :$BACKEND_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_warning "Backend already running on port $BACKEND_PORT, skipping..."
else
    # Start backend service
    print_status "Starting Hallo2 backend on port $BACKEND_PORT..."

    # Create logs directory
    mkdir -p "$SCRIPT_DIR/logs"
    BACKEND_LOG="$SCRIPT_DIR/logs/backend.log"

    # Launch backend in background
    $BACKEND_PYTHON_CMD -m uvicorn emo_hallo.backend.app:app \
        --host "0.0.0.0" \
        --port "$BACKEND_PORT" \
        --log-level info \
        > "$BACKEND_LOG" 2>&1 &
fi

BACKEND_PID=$!
print_status "Backend started with PID: $BACKEND_PID"

# Wait for backend to be ready
print_status "Waiting for backend to be ready (this may take several minutes while loading models)..."
RETRY_COUNT=0
MAX_WAIT_TIME=$((HEALTH_CHECK_RETRIES * HEALTH_CHECK_INTERVAL))

while [ $RETRY_COUNT -lt $HEALTH_CHECK_RETRIES ]; do
    if curl -s "$BACKEND_URL/health" > /dev/null 2>&1; then
        print_status "✓ Backend is ready!"
        break
    fi

    RETRY_COUNT=$((RETRY_COUNT + 1))
    ELAPSED=$((RETRY_COUNT * HEALTH_CHECK_INTERVAL))
    REMAINING=$((MAX_WAIT_TIME - ELAPSED))

    if [ $RETRY_COUNT -eq $HEALTH_CHECK_RETRIES ]; then
        print_error "✗ Backend failed to start after $HEALTH_CHECK_RETRIES retries (${MAX_WAIT_TIME}s)"
        print_error "Check logs for details:"
        print_error "  tail -f $BACKEND_LOG"
        exit 1
    fi

    # 每10次打印一次进度
    if [ $((RETRY_COUNT % 10)) -eq 0 ]; then
        PERCENT=$((RETRY_COUNT * 100 / HEALTH_CHECK_RETRIES))
        print_warning "Loading models... [$PERCENT%] (${ELAPSED}s elapsed, ~${REMAINING}s remaining)"
    fi

    sleep $HEALTH_CHECK_INTERVAL
done

# Set backend URL environment variable for frontend
export BACKEND_URL="$BACKEND_URL"
print_status "Backend URL: $BACKEND_URL"

# Kill any existing Streamlit processes to prevent port conflicts
if pgrep -f "streamlit run" > /dev/null 2>&1; then
    print_warning "Stopping existing Streamlit instances..."
    pkill -f "streamlit run" 2>/dev/null || true
    sleep 2
fi

# Start frontend
print_status "Starting Streamlit frontend..."

$STREAMLIT_CMD run ./emo_hallo/Main.py \
    --browser.serverAddress="0.0.0.0" \
    --server.enableCORS=True \
    --browser.gatherUsageStats=False &

FRONTEND_PID=$!
print_status "Frontend started with PID: $FRONTEND_PID"

# Wait for both services
print_status "Services running. Press Ctrl+C to stop."
wait