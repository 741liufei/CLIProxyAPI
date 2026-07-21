# Render 部署配置文件说明

为了让 CLIProxyAPI 能在 Render 上运行,我创建了以下文件:

## 新增文件

### 1. `render.yaml` - Render 部署配置
定义了服务类型、环境变量、持久化磁盘等 Render 平台配置。

**关键配置:**
- 使用 `Dockerfile.render` 构建
- 挂载 `/data` 持久化磁盘(1GB)用于保存认证凭据和日志
- 环境变量 `MANAGEMENT_PASSWORD` 需在 Render Dashboard 手动配置

### 2. `Dockerfile.render` - Render 专用 Dockerfile
在原 Dockerfile 基础上:
- 创建 `/data/auths` 和 `/data/logs` 持久化目录
- 使用 `render-entrypoint.sh` 作为启动入口
- 处理 Render 环境的特殊配置

### 3. `render-entrypoint.sh` - Render 启动脚本
**自动处理:**
- 如果不存在 `config.yaml`,从 `config.example.yaml` 自动生成
- 自动调整生产环境配置:
  - `allow-remote: true` (允许公网访问管理面板)
  - `commercial-mode: true` (生产模式)
  - `logging-to-file: true` (日志写文件)
- 创建符号链接,将 `auths` 和 `logs` 指向持久化磁盘 `/data`
- 检查 `MANAGEMENT_PASSWORD` 是否设置

### 4. `RENDER_DEPLOY.md` - 部署文档
详细的 Render 部署步骤说明,包括:
- 两种部署方式(Blueprint 自动 / 手动创建)
- 环境变量配置清单
- OAuth 登录注意事项
- 故障排查指南
- 成本估算

## 与 Docker Compose 部署的区别

| 项目 | Docker Compose | Render |
|------|----------------|--------|
| 配置方式 | `docker-compose.yml` + `.env` | `render.yaml` + Dashboard 环境变量 |
| 持久化 | Volume 挂载本地目录 | 持久化磁盘(/data) |
| 端口映射 | 手动映射 6 个端口 | 自动处理,主端口 8317 |
| 配置文件 | 手动挂载 `config.yaml` | 自动生成或使用仓库中的 |
| 环境变量 | `.env` 文件 | Render Dashboard 设置 |

## 部署前检查清单

在推送到 GitHub 并连接 Render 之前:

- [x] ✅ 已创建 `render.yaml`
- [x] ✅ 已创建 `Dockerfile.render`
- [x] ✅ 已创建 `render-entrypoint.sh`
- [x] ✅ 已创建 `RENDER_DEPLOY.md` 文档
- [ ] 🔧 需要生成管理密钥: `openssl rand -hex 32`
- [ ] 🔧 需要 fork 本仓库到你的 GitHub
- [ ] 🔧 需要在 Render Dashboard 设置 `MANAGEMENT_PASSWORD`

## 快速部署步骤

1. **提交文件到 Git**
```bash
git add render.yaml Dockerfile.render render-entrypoint.sh RENDER_DEPLOY.md
git commit -m "feat: add Render deployment configuration"
git push
```

2. **生成管理密钥**
```bash
openssl rand -hex 32
```
保存输出结果,稍后要用。

3. **在 Render 创建服务**
- 登录 https://render.com
- New + → Blueprint
- 选择你的仓库
- 会自动读取 `render.yaml`

4. **设置环境变量**
- 进入服务设置
- Environment 标签
- 添加 `MANAGEMENT_PASSWORD` = 上面生成的密钥

5. **等待部署完成**
- 查看 Logs 确认启动成功
- 访问 `https://你的服务名.onrender.com:8317/`

## 注意事项

### 管理密钥安全
- **绝对不要**把 `MANAGEMENT_PASSWORD` 写进 `render.yaml` 或任何提交到 Git 的文件
- 只在 Render Dashboard 的 Environment Variables 里设置
- 设置时勾选 "Secret" 选项

### OAuth 登录问题
Render 环境下 OAuth 回调端口固定,推荐两种方式:
1. 使用管理面板内置的 OAuth 流程(如果支持)
2. 本地登录后,手动上传 `auths/` 目录到 Render 的 `/data/auths/`

### 免费版限制
- 512 MB 内存
- 无流量 15 分钟后休眠
- 首次访问需要 30-60 秒唤醒
- 建议升级到 Starter ($7/月) 避免休眠

## 后续优化建议

1. **自定义域名**: 在 Render Settings → Custom Domain 添加
2. **监控告警**: 配置 Render 的健康检查和通知
3. **备份策略**: 定期备份 `/data/auths/` 目录(可通过 Render Shell 或 API)
4. **配置版本管理**: 将自定义 `config.yaml` 提交到仓库(移除敏感信息)

## 遇到问题?

参考 `RENDER_DEPLOY.md` 的故障排查章节,或查看:
- Render 日志: Dashboard → Logs
- Shell 访问: Dashboard → Shell (需要付费套餐)
- 项目 Issues: https://github.com/router-for-me/CLIProxyAPI/issues
