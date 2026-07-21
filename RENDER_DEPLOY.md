# Render 部署指南

本指南说明如何将 CLIProxyAPI 部署到 Render 云平台。

## 前置准备

1. 注册 [Render](https://render.com) 账号
2. Fork 本仓库到你的 GitHub 账号
3. 准备一个强随机管理密钥(用于访问管理面板)

生成管理密钥:
```bash
openssl rand -hex 32
```

## 部署步骤

### 方式一:通过 render.yaml 自动部署(推荐)

1. **连接 GitHub 仓库**
   - 登录 Render Dashboard
   - 点击 "New +" → "Blueprint"
   - 选择你 fork 的仓库
   - Render 会自动识别 `render.yaml` 并创建服务

2. **配置环境变量**
   
   在服务创建后,进入服务设置页面,添加以下环境变量:

   **必需的环境变量:**
   ```
   MANAGEMENT_PASSWORD=你生成的强随机密钥
   ```

   **可选的环境变量(使用外部存储时):**
   ```
   PGSTORE_DSN=postgres://user:pass@host:5432/db
   GITSTORE_GIT_TOKEN=ghp_xxxxx
   OBJECTSTORE_ACCESS_KEY=xxxxx
   OBJECTSTORE_SECRET_KEY=xxxxx
   ```

3. **等待部署完成**
   - Render 会自动构建 Docker 镜像并部署
   - 部署成功后,你会获得一个 `.onrender.com` 域名

### 方式二:手动创建服务

1. **创建 Web Service**
   - Dashboard → "New +" → "Web Service"
   - 选择你的 GitHub 仓库
   - 配置如下:

   | 配置项 | 值 |
   |--------|-----|
   | Name | cli-proxy-api |
   | Runtime | Docker |
   | Branch | main |
   | Dockerfile Path | ./Dockerfile.render |
   | Instance Type | Free 或 Starter(推荐) |

2. **添加持久化磁盘**
   - 在服务设置中,找到 "Disks" 部分
   - 点击 "Add Disk"
   - Name: `cli-proxy-data`
   - Mount Path: `/data`
   - Size: 1 GB(可根据需要调整)

3. **配置环境变量**(同方式一)

## 访问服务

部署完成后:

1. **管理面板地址**: `https://你的服务名.onrender.com:8317/`
2. **API 端点**: `https://你的服务名.onrender.com:8317/v1/chat/completions`

> **注意**: Render 免费版会在无流量时休眠,首次访问需要等待服务唤醒(约 30-60 秒)

## 登录管理面板

1. 打开管理面板地址
2. 输入你设置的 `MANAGEMENT_PASSWORD`
3. 成功登录后即可:
   - 添加 OAuth 提供商账号
   - 配置 API 密钥
   - 管理插件
   - 查看日志

## OAuth 登录注意事项

由于 Render 分配的域名和端口是固定的,OAuth 回调需要特殊处理:

1. **方式 A**: 使用管理面板内的 OAuth 流程(推荐)
   - 面板内置的 OAuth 登录会自动处理回调

2. **方式 B**: 本地登录后上传凭据
   - 在本地运行 `./CLIProxyAPI` 进行 OAuth 登录
   - 登录完成后,将 `auths/` 目录下的凭据文件手动上传到 Render
   - 使用 Render Shell 或 SFTP 上传到 `/data/auths/`

## 数据持久化

Render 的持久化磁盘会保留以下数据:

- `/data/auths/` - OAuth 认证凭据
- `/data/logs/` - 应用日志

**重要**: 免费版磁盘可能在长时间不活动后被清理,建议定期备份 `/data/auths/` 目录。

## 自定义配置

如果需要修改 `config.yaml`:

1. 将你的 `config.yaml` 提交到仓库根目录
2. Render 部署时会优先使用仓库中的 `config.yaml`
3. 如果不存在,会从 `config.example.yaml` 自动生成并应用生产环境优化

## 故障排查

### 服务无法启动

1. 检查 Render 日志(Dashboard → 你的服务 → Logs)
2. 确认 `MANAGEMENT_PASSWORD` 已设置
3. 确认持久化磁盘已正确挂载

### 管理面板无法访问

1. 确认服务已完全启动(查看日志)
2. 检查 URL 是否正确(需要包含端口 `:8317`)
3. 确认防火墙没有拦截

### OAuth 登录失败

1. 使用本地登录方式(见上文"OAuth 登录注意事项")
2. 或联系项目维护者了解 Render 环境的 OAuth 适配方案

## 成本估算

| 方案 | 月费用 | 说明 |
|------|--------|------|
| Free | $0 | 512 MB RAM, 休眠机制, 适合测试 |
| Starter | $7 | 512 MB RAM, 不休眠, 适合个人使用 |
| Standard | $25+ | 更高配置, 适合团队使用 |

持久化磁盘: 1 GB 免费, 超出部分 $0.25/GB/月

## 更新部署

Render 支持自动部署:

- 每次向 GitHub 仓库推送代码, Render 会自动重新部署
- 或在 Dashboard 手动触发 "Manual Deploy"

## 相关链接

- [Render 文档](https://render.com/docs)
- [CLIProxyAPI 项目主页](https://github.com/router-for-me/CLIProxyAPI)
- [配置说明](./README_CN.md)
