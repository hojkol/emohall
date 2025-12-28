# Emo Hallo 快速开始指南

## 🚀 启动服务

```bash
cd /remote-home/JJHe/MoneyPrinterTurbo
bash emohallo.sh
```

## 📋 日志位置

所有日志都保存在 `logs/` 目录中：

```
logs/
├── backend.log          # 后端服务日志 (FastAPI + Uvicorn)
├── frontend.log         # 前端应用日志 (Streamlit)
└── uploads/             # 用户文件和生成的视频
    └── {task_id}/
        ├── image_*.jpg
        ├── audio_*.wav
        └── output.mp4
```

## 🌐 访问地址

启动后，访问以下地址：

| 服务 | URL | 说明 |
|------|-----|------|
| 前端 UI | http://localhost:8501 | Streamlit 用户界面 |
| 后端 API | http://localhost:8001/docs | FastAPI 交互式文档 |
| 健康检查 | http://localhost:8001/health | 后端状态检查 |
| ReDoc | http://localhost:8001/redoc | 替代 API 文档 |

## 📊 监控日志

### 实时查看后端日志
```bash
tail -f logs/backend.log
```

### 实时查看前端日志
```bash
tail -f logs/frontend.log
```

### 查看所有日志
```bash
tail -f logs/*.log
```

### 查找错误
```bash
grep "ERROR" logs/backend.log
grep "error" logs/frontend.log
```

### 查找特定任务
```bash
grep "task_id" logs/backend.log logs/frontend.log
```

## 🔧 常见操作

### 停止服务
```bash
pkill -f "uvicorn\|streamlit"
```

### 重启服务
```bash
pkill -f "uvicorn\|streamlit"
sleep 2
bash emohallo.sh
```

### 清除日志
```bash
rm logs/*.log
rm -rf logs/uploads/*
```

### 查看日志大小
```bash
du -h logs/
ls -lh logs/*.log
```

## 📈 性能监控

### 监看 GPU 使用
```bash
nvidia-smi
# 或
watch -n 1 nvidia-smi
```

### 监看进程
```bash
ps aux | grep -E "uvicorn|streamlit"
```

### 监看端口
```bash
netstat -tuln | grep -E "8001|8501"
lsof -i :8001
lsof -i :8501
```

## 🐛 故障排查

### 问题：端口已被占用
```bash
# 查看占用端口的进程
lsof -i :8001
lsof -i :8501

# 强制杀掉进程
pkill -9 -f "uvicorn\|streamlit"
```

### 问题：后端启动失败
```bash
# 查看后端日志
tail -50 logs/backend.log

# 查看启动错误
grep "ERROR" logs/backend.log
```

### 问题：无法连接到后端
```bash
# 检查后端是否运行
ps aux | grep uvicorn

# 检查端口是否开放
netstat -tuln | grep 8001

# 测试连接
curl http://localhost:8001/health
```

### 问题：日志文件为空
```bash
# 检查权限
ls -la logs/

# 检查目录是否存在
mkdir -p logs/uploads

# 重新启动服务
bash emohallo.sh
```

## 📚 详细文档

- **日志管理**: 查看 [LOGGING.md](LOGGING.md)
- **API 文档**: 查看 [emo_hallo/docs/API.md](emo_hallo/docs/API.md)
- **开发指南**: 查看 [emo_hallo/docs/DEVELOPMENT.md](emo_hallo/docs/DEVELOPMENT.md)
- **测试指南**: 查看 [emo_hallo/docs/TESTING.md](emo_hallo/docs/TESTING.md)
- **项目总结**: 查看 [emo_hallo/PROJECT_SUMMARY.md](emo_hallo/PROJECT_SUMMARY.md)

## 🎯 典型工作流

1. **启动服务**
   ```bash
   bash emohallo.sh
   ```

2. **打开前端**
   - 访问 http://localhost:8501
   - 上传人物图像和音频文件

3. **生成视频**
   - 点击"生成"按钮
   - 实时查看进度
   - 等待完成并下载

4. **查看日志**
   ```bash
   tail -f logs/backend.log
   tail -f logs/frontend.log
   ```

5. **下载生成的视频**
   - 前端会自动显示下载按钮
   - 或从 logs/uploads/{task_id}/output.mp4 手动下载

## 💾 备份和恢复

### 备份所有文件
```bash
tar -czf backup-$(date +%Y%m%d).tar.gz logs/
```

### 恢复备份
```bash
tar -xzf backup-20241228.tar.gz
```

### 清理旧日志
```bash
# 删除 7 天前的日志
find logs/ -name "*.log" -mtime +7 -delete

# 清理旧的上传文件
find logs/uploads/ -type f -mtime +30 -delete
```

## ℹ️ 系统信息

### 查看环境信息
```bash
# Python 版本
python --version

# PyTorch 版本
python -c "import torch; print(f'PyTorch: {torch.__version__}')"

# CUDA 版本
python -c "import torch; print(f'CUDA: {torch.version.cuda}')"

# GPU 信息
nvidia-smi
python -c "import torch; print(f'GPU: {torch.cuda.get_device_name(0)}')"
```

### 检查服务状态
```bash
# 后端状态
curl -s http://localhost:8001/health | python -m json.tool

# 前端状态（检查是否响应）
curl -s http://localhost:8501 > /dev/null && echo "Frontend OK" || echo "Frontend ERROR"
```

## 🔗 相关链接

- **GitHub 仓库**: https://github.com/hojkol/emo_hallo
- **官方文档**: 查看项目目录下的 README.md
- **问题反馈**: GitHub Issues

## 📞 获取帮助

1. 查看详细日志: `tail -f logs/*.log`
2. 查看本文档中的故障排查部分
3. 查看相关的详细文档（LOGGING.md 等）
4. 在 GitHub 上提交 Issue

---

**最后更新**: 2025-12-28
**版本**: 1.0.0
