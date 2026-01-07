#!/bin/bash

echo "🔧 Diagnosing Backend Connection Issues"
echo "========================================"
echo ""

# ===== 禁用代理以连接本地后端 =====
export http_proxy=""
export https_proxy=""
export HTTP_PROXY=""
export HTTPS_PROXY=""

# 检查配置
BACKEND_HOST="${BACKEND_HOST:-127.0.0.1}"
BACKEND_PORT="${BACKEND_PORT:-8001}"
BACKEND_URL="http://$BACKEND_HOST:$BACKEND_PORT"

echo "Configuration:"
echo "  BACKEND_HOST: $BACKEND_HOST"
echo "  BACKEND_PORT: $BACKEND_PORT"
echo "  BACKEND_URL: $BACKEND_URL"
echo "  Proxy: DISABLED (cleared http_proxy, https_proxy)"
echo ""

# 1. 检查后端进程
echo "1️⃣  Checking if backend is running..."
if ps aux | grep -q "[u]vicorn emo_hallo"; then
    echo "✓ Backend process is running"
    ps aux | grep "[u]vicorn emo_hallo" | awk '{print "  PID:", $2, "Memory:", $6, "KB"}'
else
    echo "❌ Backend process not found!"
    exit 1
fi
echo ""

# 2. 检查端口监听
echo "2️⃣  Checking if port $BACKEND_PORT is listening..."
if command -v netstat &> /dev/null; then
    if netstat -tuln 2>/dev/null | grep -q ":$BACKEND_PORT"; then
        echo "✓ Port $BACKEND_PORT is listening"
        netstat -tuln 2>/dev/null | grep ":$BACKEND_PORT"
    else
        echo "❌ Port $BACKEND_PORT is not listening!"
        echo "   All listening ports:"
        netstat -tuln 2>/dev/null | grep LISTEN | grep -E ":(80|8000|8001|8080|9000)"
    fi
elif command -v ss &> /dev/null; then
    if ss -tuln 2>/dev/null | grep -q ":$BACKEND_PORT"; then
        echo "✓ Port $BACKEND_PORT is listening"
        ss -tuln 2>/dev/null | grep ":$BACKEND_PORT"
    else
        echo "❌ Port $BACKEND_PORT is not listening!"
    fi
fi
echo ""

# 3. 测试本地连接
echo "3️⃣  Testing local connection to backend..."
echo "   Command: curl -v http://127.0.0.1:$BACKEND_PORT/health"
response=$(curl -v http://127.0.0.1:$BACKEND_PORT/health 2>&1)
if echo "$response" | grep -q "HTTP"; then
    echo "✓ Local connection works!"
    echo "$response" | grep -E "HTTP|Connected|health" | head -5
else
    echo "❌ Local connection failed!"
    echo "$response"
fi
echo ""

# 4. 测试远程连接（如果不是本地）
if [ "$BACKEND_HOST" != "127.0.0.1" ] && [ "$BACKEND_HOST" != "localhost" ]; then
    echo "4️⃣  Testing remote connection to $BACKEND_HOST:$BACKEND_PORT..."
    echo "   Command: curl -v http://$BACKEND_HOST:$BACKEND_PORT/health"
    response=$(curl -v http://$BACKEND_HOST:$BACKEND_PORT/health 2>&1)
    if echo "$response" | grep -q "HTTP"; then
        echo "✓ Remote connection works!"
        echo "$response" | grep -E "HTTP|Connected|health" | head -5
    else
        echo "❌ Remote connection failed!"
        echo "   This might be due to:"
        echo "   - Firewall blocking port $BACKEND_PORT"
        echo "   - Wrong IP address"
        echo "   - Backend not binding to 0.0.0.0"
        echo "$response" | head -10
    fi
fi
echo ""

# 5. 检查后端日志
echo "5️⃣  Recent backend logs:"
LOG_PATH="/remote-home/JJHe/MoneyPrinterTurbo/logs/backend.log"
if [ -f "$LOG_PATH" ]; then
    echo "Last 10 lines:"
    tail -10 "$LOG_PATH"
else
    echo "❌ Log file not found: $LOG_PATH"
fi
echo ""

# 6. 总结
echo "📝 Summary:"
echo "  If backend is running and port is listening, but connection fails:"
echo "  - Try: BACKEND_HOST=127.0.0.1 bash test/inference.sh"
echo "  - Check if running from same network/server"
echo "  - Verify firewall rules"
echo ""
