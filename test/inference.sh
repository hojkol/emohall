#!/bin/bash

echo "🔍 Debugging Hallo2 Inference Endpoint"
echo "======================================"

# ===== 禁用代理以连接本地后端 =====
export http_proxy=""
export https_proxy=""
export HTTP_PROXY=""
export HTTPS_PROXY=""

# ===== 配置后端服务器 =====
# 支持远程和本地后端
BACKEND_HOST="${BACKEND_HOST:-127.0.0.1}"  # 默认本地，可通过环境变量覆盖
BACKEND_PORT="${BACKEND_PORT:-8001}"
BACKEND_URL="http://$BACKEND_HOST:$BACKEND_PORT"

echo "📡 Backend URL: $BACKEND_URL"
echo ""

# 检查后端是否运行
echo -e "\n1️⃣  Checking backend health..."
echo "   Running: curl -s $BACKEND_URL/health"
response=$(curl -s --max-time 5 "$BACKEND_URL/health" 2>&1)

if [ -z "$response" ]; then
    echo "❌ No response from backend"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check backend is running: ps aux | grep uvicorn"
    echo "  2. Check port is listening: netstat -tuln | grep 8001"
    echo "  3. Try connection: curl -v http://$BACKEND_HOST:$BACKEND_PORT/health"
    echo "  4. For remote backend, use: BACKEND_HOST=<remote_ip> bash $0"
    exit 1
fi

echo "Health check response: $response"

# 验证文件路径
echo -e "\n2️⃣  Checking test files..."
IMAGE_PATH="/remote-home/JJHe/hallo2/examples/reference_images/9.png"
AUDIO_PATH="/remote-home/JJHe/hallo2/examples/driving_audios/10.wav"

if [ ! -f "$IMAGE_PATH" ]; then
    echo "❌ Image not found: $IMAGE_PATH"
    exit 1
fi
if [ ! -f "$AUDIO_PATH" ]; then
    echo "❌ Audio not found: $AUDIO_PATH"
    exit 1
fi
echo "✓ Image found: $IMAGE_PATH"
echo "✓ Audio found: $AUDIO_PATH"

# 尝试推理请求
echo -e "\n3️⃣  Submitting inference request..."
response=$(curl -s -X POST "$BACKEND_URL/api/v1/inference/hallo2" \
    -F "image_file=@$IMAGE_PATH" \
    -F "audio_file=@$AUDIO_PATH" \
    -F "use_cache=true")

echo "Inference response:"
if command -v jq &> /dev/null; then
    echo "$response" | jq . 2>/dev/null || echo "$response"
else
    echo "$response"
fi

# 查看后端日志（仅本地有效）
echo -e "\n4️⃣  Recent backend logs:"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
LOG_PATH="$SCRIPT_DIR/logs/backend.log"

if [ -f "$LOG_PATH" ]; then
    echo "Last 20 lines from $LOG_PATH:"
    tail -20 "$LOG_PATH" | grep -E "inference|ERROR|task" || tail -20 "$LOG_PATH"
else
    echo "Log file not found: $LOG_PATH"
    echo "This is normal for remote backend runs."
    echo "Check logs on remote server: tail -f /remote-home/JJHe/MoneyPrinterTurbo/logs/backend.log"
fi
