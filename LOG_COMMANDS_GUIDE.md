# 日志查看命令详细指南

## 1️⃣ 实时查看后端日志

### 命令
```bash
tail -f logs/backend.log
```

### 说明
- `tail` - 显示文件末尾的内容
- `-f` - "follow" 的意思，持续监听文件更新
- 每当有新日志写入时，自动显示新内容
- 按 `Ctrl+C` 停止查看

### 实际使用
```bash
$ tail -f logs/backend.log
2025-12-28 09:13:45 - emo_hallo.backend.app - INFO - [app.py:81] - Starting Hallo2 backend service...
2025-12-28 09:13:45 - emo_hallo.backend.config.settings - INFO - [settings.py:45] - Found config file...
2025-12-28 09:13:51 - emo_hallo.backend.app - INFO - [app.py:99] - Hallo2 backend service started successfully
INFO:     Application startup complete.
^C  # 按 Ctrl+C 退出
```

### 何时使用
- ✅ 调试后端问题
- ✅ 监控服务启动
- ✅ 实时查看任务执行进度

---

## 2️⃣ 实时查看前端日志

### 命令
```bash
tail -f logs/frontend.log
```

### 说明
- 同 `tail -f logs/backend.log`
- 监听前端（Streamlit）的日志更新
- 按 `Ctrl+C` 停止查看

### 实际使用
```bash
$ tail -f logs/frontend.log
2025-12-28 09:13:45 | INFO     | load config from file: /remote-home/JJHe/MoneyPrinterTurbo/config.toml
2025-12-28 09:13:45 | INFO     | MoneyPrinterTurbo v1.1.0
2025-12-28 09:13:45 | INFO     | __main__ - Streamlit app loaded
2025-12-28 09:13:50 | INFO     | backend connection successful
^C  # 按 Ctrl+C 退出
```

### 何时使用
- ✅ 调试前端问题
- ✅ 查看用户操作日志
- ✅ 监控前端与后端的通信

---

## 3️⃣ 同时查看两个日志

### 命令
```bash
tail -f logs/*.log
```

### 说明
- `*` 是通配符，表示 logs/ 目录下所有 `.log` 文件
- 同时监听多个日志文件
- 新日志会带有文件名前缀区分
- 按 `Ctrl+C` 停止查看

### 实际使用
```bash
$ tail -f logs/*.log
==> logs/backend.log <==
2025-12-28 09:13:45 - emo_hallo.backend.app - INFO - [app.py:81] - Starting...

==> logs/frontend.log <==
2025-12-28 09:13:45 | INFO     | load config from file...

2025-12-28 09:13:50 - emo_hallo.backend.app - INFO - [app.py:99] - Hallo2 started...

2025-12-28 09:13:50 | INFO     | backend connection successful
^C  # 按 Ctrl+C 退出
```

### 优势
- ✅ 一个终端同时看到前后端日志
- ✅ 便于调试前后端的交互问题
- ✅ 清晰的文件名标记区分来源

### 何时使用
- ✅ 整体系统调试
- ✅ 追踪完整的请求/响应流程
- ✅ 快速定位问题来源

---

## 4️⃣ 查找所有错误

### 命令
```bash
grep "ERROR" logs/backend.log logs/frontend.log
```

### 说明
- `grep` - 搜索文本的命令
- `"ERROR"` - 要搜索的关键词（大小写敏感）
- 列出两个日志文件中所有包含 "ERROR" 的行
- 显示文件名和完整的日志行

### 实际使用
```bash
$ grep "ERROR" logs/backend.log logs/frontend.log
logs/backend.log:ERROR:    [Errno 98] error while attempting to bind on address ('0.0.0.0', 8001): address already in use
logs/backend.log:2025-12-28 09:13:51 - emo_hallo.backend.app - ERROR - [app.py:108] - Shutdown error: connection lost
```

### 搜索多个关键词
```bash
# 搜索 ERROR 或 CRITICAL
grep -E "ERROR|CRITICAL" logs/backend.log logs/frontend.log

# 不区分大小写搜索 error
grep -i "error" logs/backend.log logs/frontend.log

# 显示行号
grep -n "ERROR" logs/backend.log logs/frontend.log
```

### 输出说明
```
logs/backend.log:ERROR:    [Errno 98] ...
└─ 文件名      └─ 日志内容
```

### 何时使用
- ✅ 快速找出所有错误
- ✅ 故障排查
- ✅ 生成错误报告

---

## 5️⃣ 查找特定任务

### 命令
```bash
grep "task_id" logs/backend.log logs/frontend.log
```

### 说明
- 搜索包含 "task_id" 的所有日志行
- 用于追踪特定任务的执行全过程
- 显示任务从创建到完成的所有步骤

### 实际使用
假设你的任务 ID 是 `550e8400-e29b-41d4-a716-446655440000`

```bash
$ grep "550e8400" logs/backend.log logs/frontend.log
logs/frontend.log:2025-12-28 10:30:45 | INFO     | Task submitted: 550e8400-e29b-41d4-a716-446655440000
logs/backend.log:2025-12-28 10:30:46 - emo_hallo.backend.controllers.inference - INFO - Creating inference task 550e8400
logs/backend.log:2025-12-28 10:30:47 - emo_hallo.backend.services.task_manager - INFO - Task 550e8400 started
logs/backend.log:2025-12-28 10:31:30 - emo_hallo.backend.services.hallo2 - INFO - Task 550e8400 progress: 50%
logs/frontend.log:2025-12-28 10:31:30 | INFO     | Progress: 50% - Running inference...
logs/backend.log:2025-12-28 10:32:00 - emo_hallo.backend.services.hallo2 - INFO - Task 550e8400 completed
logs/frontend.log:2025-12-28 10:32:00 | INFO     | Task completed successfully
```

### 完整追踪流程
```bash
# 方法 1: 搜索完整任务 ID
TASK_ID="550e8400-e29b-41d4-a716-446655440000"
grep "$TASK_ID" logs/backend.log logs/frontend.log

# 方法 2: 搜索任务 ID 的前 8 个字符
grep "550e8400" logs/backend.log logs/frontend.log

# 方法 3: 搜索并显示行号
grep -n "550e8400" logs/backend.log logs/frontend.log
```

### 何时使用
- ✅ 调试特定的生成任务
- ✅ 追踪任务从提交到完成的整个过程
- ✅ 找出任务失败的原因

---

## 6️⃣ 查找 GPU 相关信息

### 命令
```bash
grep -i "gpu\|cuda" logs/backend.log
```

### 说明
- `-i` - 不区分大小写（GPU、gpu、Gpu 都能搜到）
- `|` - 或操作符，搜索包含 "gpu" **或** "cuda" 的行
- 用于确认 GPU 是否正确初始化

### 实际使用
```bash
$ grep -i "gpu\|cuda" logs/backend.log
2025-12-28 09:13:45 - emo_hallo.backend.utils.torch_utils - INFO - GPU available: True
2025-12-28 09:13:46 - emo_hallo.backend.utils.torch_utils - INFO - GPU count: 1
2025-12-28 09:13:46 - emo_hallo.backend.utils.torch_utils - INFO - GPU name: NVIDIA GeForce RTX 3090
2025-12-28 09:13:47 - emo_hallo.backend.services.hallo2 - INFO - CUDA device: cuda:0
2025-12-28 09:13:50 - emo_hallo.backend.services.hallo2 - INFO - Model loaded on GPU successfully
```

### 相关搜索
```bash
# 搜索 CUDA 错误
grep -i "cuda.*error\|out of memory" logs/backend.log

# 搜索 GPU 内存使用
grep -i "memory\|device" logs/backend.log

# 搜索 Torch 相关信息
grep -i "torch\|pytorch" logs/backend.log
```

### 何时使用
- ✅ 确认 GPU 是否可用
- ✅ 检查 GPU 初始化是否成功
- ✅ 诊断 GPU 相关问题（OOM 等）

---

## 💡 高级用法

### 组合搜索 - 查找错误的任务
```bash
# 搜索包含特定任务 ID 的所有 ERROR 日志
TASK_ID="550e8400"
grep "$TASK_ID" logs/*.log | grep -i "error"
```

### 搜索时间范围内的日志
```bash
# 查找 09:13 分钟内的日志
grep "2025-12-28 09:13" logs/backend.log

# 查找特定时间段
grep "2025-12-28 0[89]:" logs/backend.log
```

### 显示上下文
```bash
# 显示匹配行的前后 3 行
grep -C 3 "ERROR" logs/backend.log

# 只显示前 2 行
grep -B 2 "ERROR" logs/backend.log

# 只显示后 2 行
grep -A 2 "ERROR" logs/backend.log
```

### 统计信息
```bash
# 统计有多少行包含 ERROR
grep -c "ERROR" logs/backend.log

# 统计有多少个不同的任务
grep -o "task [a-f0-9]*" logs/backend.log | sort -u | wc -l
```

### 保存搜索结果
```bash
# 将错误日志保存到文件
grep "ERROR" logs/*.log > error_report.txt

# 将特定任务的日志保存
grep "550e8400" logs/*.log > task_550e8400.log
```

---

## 🎯 实用场景示例

### 场景 1: 监控后端启动
```bash
# 打开新终端
tail -f logs/backend.log

# 看到输出:
# 2025-12-28 09:13:45 - Starting Hallo2 backend service...
# 2025-12-28 09:13:51 - Hallo2 backend service started successfully
# INFO:     Application startup complete.
```

### 场景 2: 调试任务失败
```bash
# 第 1 步: 找到任务 ID
tail -20 logs/frontend.log | grep "Task submitted"

# 第 2 步: 搜索这个任务的所有日志
TASK_ID="abc123"
grep "$TASK_ID" logs/*.log

# 第 3 步: 查找错误信息
grep "$TASK_ID" logs/*.log | grep -i "error"

# 第 4 步: 查看完整上下文
grep -C 5 "$TASK_ID" logs/backend.log | grep -i "error" -A 5 -B 5
```

### 场景 3: GPU 内存不足
```bash
# 检查是否有 OOM 错误
grep -i "out of memory\|cuda.*error" logs/backend.log

# 查看 GPU 使用情况
grep -i "gpu\|memory" logs/backend.log | tail -20

# 查看完整的 GPU 初始化过程
grep -i "cuda\|gpu" logs/backend.log | head -20
```

### 场景 4: 前后端通信问题
```bash
# 打开两个终端分别查看
# 终端 1:
tail -f logs/backend.log | grep -i "api\|request\|response"

# 终端 2:
tail -f logs/frontend.log | grep -i "api\|connection\|backend"
```

---

## ⚠️ 常见问题

### Q: 查看后端日志时没有新内容出现？
```bash
# A: 检查后端是否真的在运行
ps aux | grep uvicorn

# 或者查看日志文件大小是否在增长
ls -lh logs/backend.log
# 不断执行这条命令，看 size 是否增加
```

### Q: 日志太多，如何只看最新的？
```bash
# 只显示最后 50 行
tail -50 logs/backend.log

# 只显示最后 100 行
tail -100 logs/frontend.log

# 然后实时查看新增
tail -f logs/backend.log
```

### Q: 如何搜索多个关键词？
```bash
# 搜索 ERROR 或 WARNING 或 CRITICAL
grep -E "ERROR|WARNING|CRITICAL" logs/backend.log

# 搜索包含 task 且包含 error 的行
grep "task" logs/backend.log | grep -i "error"
```

### Q: 日志文件很大，搜索很慢？
```bash
# 使用 grep 的二进制搜索
grep --binary-files=text "ERROR" logs/backend.log

# 或者只搜索最近的部分
tail -10000 logs/backend.log | grep "ERROR"

# 或者使用 ack（如果安装了）
ack "ERROR" logs/backend.log
```

---

## 📋 快速参考表

| 场景 | 命令 | 说明 |
|------|------|------|
| 实时查看后端 | `tail -f logs/backend.log` | 持续监听 |
| 实时查看前端 | `tail -f logs/frontend.log` | 持续监听 |
| 同时查看两个 | `tail -f logs/*.log` | 一个终端看全部 |
| 查找所有错误 | `grep "ERROR" logs/*.log` | 搜索所有错误 |
| 查找特定任务 | `grep "task_id" logs/*.log` | 追踪任务执行 |
| 查找 GPU 信息 | `grep -i "gpu" logs/backend.log` | GPU 诊断 |
| 最后 50 行 | `tail -50 logs/backend.log` | 快速浏览 |
| 首次 20 行 | `head -20 logs/backend.log` | 查看初始化 |
| 统计行数 | `wc -l logs/backend.log` | 日志大小 |
| 保存结果 | `grep "ERROR" logs/*.log > error.txt` | 导出日志 |

---

## 🔗 相关文档

- [LOGGING.md](LOGGING.md) - 完整的日志管理指南
- [QUICK_START.md](QUICK_START.md) - 快速开始指南
- [emo_hallo/docs/DEVELOPMENT.md](emo_hallo/docs/DEVELOPMENT.md) - 开发指南
