# 日志管理指南

Emo Hallo 项目的所有日志都集中存储在项目根目录的 `logs/` 文件夹中。

## 目录结构

```
/logs/
├── backend.log          # 后端服务日志 (FastAPI + Uvicorn)
├── frontend.log         # 前端应用日志 (Streamlit)
└── uploads/             # 用户上传的文件和生成的输出
    └── {task_id}/
        ├── image_*.jpg|png
        ├── audio_*.wav|mp3
        └── output.mp4
```

## 日志文件详解

### 1. backend.log

**包含内容：**
- FastAPI 应用启动和关闭信息
- HTTP 请求和响应日志
- 模型加载和注册信息
- 推理任务日志
- 错误和异常信息
- GPU 相关信息

**日志格式：**
```
2024-12-28 10:30:15 - emo_hallo.backend.app - INFO - [app.py:60] - Starting Hallo2 backend service...
2024-12-28 10:30:20 - emo_hallo.backend.controllers.inference - INFO - [inference.py:48] - Creating inference task abc123
```

**示例查看：**
```bash
# 查看最后 100 行
tail -100 logs/backend.log

# 实时查看
tail -f logs/backend.log

# 查找特定内容
grep "ERROR" logs/backend.log
grep "task_id" logs/backend.log
```

### 2. frontend.log

**包含内容：**
- Streamlit 应用启动信息
- 用户交互日志
- 后端 API 调用日志
- 文件上传和下载日志
- 任务提交和进度更新
- 错误和异常信息

**日志格式：**
```
2024-12-28 10:30:25 | INFO     | emo_hallo.client - Task submitted: abc123
2024-12-28 10:30:30 | INFO     | __main__ - Monitoring progress: 45% - Running inference...
```

**示例查看：**
```bash
# 查看最后 50 行
tail -50 logs/frontend.log

# 实时查看
tail -f logs/frontend.log

# 查找特定任务
grep "abc123" logs/frontend.log
```

## 日志级别

所有日志都配置为 **INFO** 级别，这意味着以下信息会被记录：

- ✅ **INFO** - 常规信息（应用启动、任务创建等）
- ✅ **WARNING** - 警告信息（不是错误，但需要注意）
- ✅ **ERROR** - 错误信息（需要修复的问题）
- ✅ **CRITICAL** - 关键错误（系统无法继续运行）

**不记录的内容：**
- ❌ **DEBUG** - 调试信息（在生产环境中禁用）

## 日志大小管理

### 自动轮转（未来增强）

当前实现不自动轮转日志文件。如果日志文件变得很大，可以：

```bash
# 查看日志文件大小
du -h logs/

# 清空日志（保留备份）
cp logs/backend.log logs/backend.log.bak
echo "" > logs/backend.log

# 或者完全删除
rm logs/backend.log
```

### 日志文件大小示例

```bash
$ du -h logs/
4.2M    logs/backend.log
2.8M    logs/frontend.log
1.5G    logs/uploads/
1.5G    logs/
```

## 常见日志分析

### 检查后端启动是否成功

```bash
grep "Application startup complete" logs/backend.log
# 输出: INFO:     Application startup complete.
```

### 查找所有错误

```bash
grep "ERROR" logs/backend.log logs/frontend.log
```

### 查找特定任务的所有操作

```bash
TASK_ID="550e8400-e29b-41d4-a716-446655440000"
grep "$TASK_ID" logs/backend.log logs/frontend.log
```

### 查看 GPU 使用情况

```bash
grep -i "gpu\|cuda\|torch" logs/backend.log
```

### 查看 API 请求历史

```bash
grep "HTTP" logs/backend.log
```

### 监控实时日志

```bash
# 同时查看两个日志
tail -f logs/backend.log logs/frontend.log

# 或分别查看
tail -f logs/backend.log  # 一个终端
tail -f logs/frontend.log # 另一个终端
```

## 日志配置位置

如需修改日志配置，请编辑以下文件：

### 后端日志配置
文件：`emo_hallo/backend/app.py`
函数：`setup_logging()`

```python
log_file = os.path.join(logs_dir, "backend.log")
logging.basicConfig(
    level=logging.INFO,  # 修改此处改变日志级别
    format="...",        # 修改此处改变日志格式
)
```

### 前端日志配置
文件：`emo_hallo/Main.py`
代码位置：20-36 行

```python
logger.add(
    frontend_log_file,
    format="<level>{time:...}</level>",  # 修改日志格式
    level="INFO",                          # 修改日志级别
)
```

### 启动脚本日志配置
文件：`emohallo.sh`

```bash
BACKEND_LOG="$SCRIPT_DIR/logs/backend.log"
FRONTEND_LOG="$SCRIPT_DIR/logs/frontend.log"
```

## 故障排查

### 问题：日志文件不存在

**原因：** 日志目录未创建或应用未正确启动

**解决：**
```bash
# 创建日志目录
mkdir -p logs/logs/uploads

# 检查权限
ls -la logs/
chmod -R 755 logs/
```

### 问题：无法写入日志

**原因：** 权限不足

**解决：**
```bash
# 检查权限
ls -la logs/backend.log

# 修改权限
chmod 644 logs/*.log
chmod 755 logs/

# 或者以 root 运行（在开发环境中）
sudo chown -R $(whoami) logs/
```

### 问题：日志文件过大

**原因：** 长期运行产生的日志累积

**解决：**
```bash
# 压缩旧日志
gzip logs/backend.log.20241227

# 或删除旧日志
rm logs/*.log.20241227
```

### 问题：找不到特定错误

**原因：** 日志级别设置过高或日志已被清空

**解决：**
```bash
# 检查日志文件是否为空
wc -l logs/backend.log
wc -l logs/frontend.log

# 重新启动应用以生成新日志
bash emohallo.sh
```

## 日志格式示例

### 后端日志示例

```
2024-12-28 10:30:15 - emo_hallo.backend.app - INFO - [app.py:60] - Starting Hallo2 backend service...
2024-12-28 10:30:16 - emo_hallo.backend.app - INFO - [app.py:65] - Configuration: {...}
2024-12-28 10:30:17 - emo_hallo.backend.services.registry.model_registry - INFO - [model_registry.py:50] - Registering Hallo2 model...
2024-12-28 10:30:25 - emo_hallo.backend.app - INFO - [app.py:72] - Successfully registered Hallo2 model
2024-12-28 10:30:30 - emo_hallo.backend.app - INFO - [app.py:76] - Task manager initialized (max concurrent: 1)
2024-12-28 10:30:30 - emo_hallo.backend.app - INFO - [app.py:78] - Hallo2 backend service started successfully
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8001 (Press CTRL+C to quit)
2024-12-28 10:30:31 - emo_hallo.backend.app - INFO - [app.py:60] - Starting Hallo2 backend service...
```

### 前端日志示例

```
2024-12-28 10:30:35 | INFO     | __main__ - Streamlit app started
2024-12-28 10:30:40 | INFO     | emo_hallo.client.hallo2_client - Connecting to http://localhost:8001
2024-12-28 10:30:45 | INFO     | emo_hallo.client.hallo2_client - Task submitted: 550e8400-e29b-41d4-a716-446655440000
2024-12-28 10:30:50 | INFO     | __main__ - Monitoring task: 550e8400-e29b-41d4-a716-446655440000
2024-12-28 10:31:00 | INFO     | __main__ - Progress: 25% - Loading models...
2024-12-28 10:31:30 | INFO     | __main__ - Progress: 50% - Running inference...
2024-12-28 10:32:00 | INFO     | __main__ - Progress: 100% - Task completed!
```

## 最佳实践

### 开发阶段

```bash
# 同时监控前后端日志
tail -f logs/backend.log &
tail -f logs/frontend.log &
```

### 生产环境

```bash
# 定期备份日志
tar -czf logs-backup-$(date +%Y%m%d).tar.gz logs/

# 定期清理旧日志（可选）
find logs/ -name "*.log" -mtime +7 -delete
```

### 故障排查

```bash
# 导出所有日志供分析
cat logs/backend.log logs/frontend.log > all_logs.txt

# 按时间戳过滤日志
grep "2024-12-28 10:3[0-5]" logs/backend.log
```

## 相关文档

- [开发指南](emo_hallo/docs/DEVELOPMENT.md) - 开发环境配置
- [测试指南](emo_hallo/docs/TESTING.md) - 运行测试和检查日志
- [API 文档](emo_hallo/docs/API.md) - API 端点和请求日志

## 获取帮助

如有日志相关问题，请：
1. 查看相关日志文件
2. 搜索错误消息
3. 在 GitHub 上创建 Issue
4. 提供完整的日志输出
