#!/bin/bash

# 前端加载速度诊断脚本

echo "=== 前端页面加载速度诊断 ==="
echo ""
echo "⏱️  测试Streamlit启动时间..."
echo ""

# 清空日志
> /remote-home/JJHe/MoneyPrinterTurbo/logs/frontend.log

# 启动前端并记录时间
START_TIME=$(date +%s)
echo "启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 启动Streamlit并等待3秒
cd /remote-home/JJHe/MoneyPrinterTurbo

export STREAMLIT_SERVER_RUN_ON_SAVE=false
export STREAMLIT_SERVER_HEADLESS=true
export STREAMLIT_LOGGER_LEVEL=error
export STREAMLIT_SERVER_MAX_UPLOAD_SIZE=500
export STREAMLIT_SERVER_ENABLE_CORS=true

timeout 10 /remote-home/JJHe/.conda/envs/mpt/bin/streamlit run ./emo_hallo/Main.py \
    --server.port=8501 \
    --server.address=0.0.0.0 \
    --logger.level=error \
    --client.toolbarMode=minimal >> logs/frontend.log 2>&1 &

PID=$!

echo "等待页面加载..."
for i in {1..10}; do
    if grep -q "You can now view" logs/frontend.log; then
        END_TIME=$(date +%s)
        ELAPSED=$((END_TIME - START_TIME))
        echo "✓ 前端启动完成，耗时: ${ELAPSED}秒"
        echo ""
        break
    fi
    echo "  [$i/10] 等待中..."
    sleep 1
done

echo "日志内容:"
echo "=============="
head -20 logs/frontend.log
echo "=============="
echo ""

# 清理
kill $PID 2>/dev/null || true

# 诊断建议
echo "📋 诊断建议:"
echo ""
echo "如果加载时间 > 5秒，可能原因："
echo "  1. 后端未启动或连接超时"
echo "  2. 模块导入耗时（app.config, hallo2_client等）"
echo "  3. 配置文件加载"
echo "  4. 多语言文件加载"
echo ""
echo "解决方案："
echo "  1. 确保后端已启动: ps aux | grep uvicorn"
echo "  2. 添加Streamlit缓存优化"
echo "  3. 延迟加载Hallo2Client"
echo "  4. 使用@st.cache_resource缓存重型对象"
