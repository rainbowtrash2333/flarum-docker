# Flarum Docker

自定义 Flarum Docker 部署，包含翻译插件 Flarum 纯插件实现。

## 项目结构

```
.
├── .env                      # 环境变量配置（不提交到版本控制）
├── .env.example              # 环境变量模板
├── .gitignore
├── Dockerfile                # 生产镜像
├── Dockerfile.dev            # 开发镜像
├── Makefile                  # 构建和管理命令
├── docker-compose.prod.yml   # 生产环境配置
├── docker-compose.dev.yml    # 开发环境配置
├── extensions/               # 本地插件目录（需要手动克隆）
├── data/                     # 生产 Flarum 数据
├── data-dev/                 # 开发 Flarum 数据
├── mysql/                    # 生产 MariaDB 数据
├── mysql-dev/                # 开发 MariaDB 数据
├── redis/                    # 生产 Redis 数据
└── redis-dev/                # 开发 Redis 数据
```

## 快速开始

### 1. 克隆插件仓库

```bash
git clone https://github.com/rainbowtrash2333/translate_flarum.git ./extensions/translate_flarum
```

### 2. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env 文件，修改数据库密码
# LLM API Key 在 Flarum Admin 后台配置（见下方"插件配置"）
```

### 3. 启动服务

**开发环境**：

```bash
make dev-build
make dev-up
```

**生产环境**：

```bash
make build
make up
```

### 4. 访问服务

| 服务 | 开发环境 | 生产环境 |
|------|----------|----------|
| Flarum | http://localhost:8080 | http://localhost:8888 |
| MariaDB | localhost:3307 | 内部访问 |
| Translator Worker | 内部访问 | 内部访问 |

## 服务架构

```
┌─────────────────────────────┐
│  Flarum Web Container       │
│  (Nginx + PHP-FPM)          │
│  - 论坛 UI + PostSerializer │
│  - Admin 后台               │
│  - 翻译 API 路由             │
│  事件: PostCreated /        │
│        PostRevised → pending│
└──────────┬──────────────────┘
           │ 共享 MariaDB
           ▼
┌─────────────────────────────┐
│  MariaDB                     │
│  - post_translations        │
│  - translation_logs         │
│  - posts (Flarum 原表)      │
└─────────────────────────────┘
           ▲
           │ 共享 MariaDB
┌──────────┴──────────────────┐
│  Translator Worker (PHP)    │
│  command: php flarum        │
│           translate:run     │
│  - 5s 轮询 pending 行       │
│  - 流式 SSE 调 opencode-go  │
│  - stdout → docker logs     │
└──────────┬──────────────────┘
           │ HTTPS SSE (流式)
           ▼
┌─────────────────────────────┐
│  opencode-go (外部)          │
│  OpenAI 兼容 API 网关        │
│  流式响应 (规避 60s 超时)    │
└─────────────────────────────┘
```

所有服务通过 `flarum-network` 网络连接，容器间使用服务名访问。translator-worker 与 flarum web 使用同一镜像，仅启动命令不同。

## Makefile 命令

### 开发环境

| 命令 | 说明 |
|------|------|
| `make dev-build` | 构建开发镜像 |
| `make dev-rebuild` | 重建开发镜像（无缓存） |
| `make dev-up` | 启动开发服务 |
| `make dev-down` | 停止开发服务 |
| `make dev-logs` | 查看开发日志 |
| `make dev-ps` | 查看开发服务状态 |
| `make dev-shell` | 进入开发容器 |
| `make dev-clean` | 清理开发环境 |

### 生产环境

| 命令 | 说明 |
|------|------|
| `make build` | 构建生产镜像 |
| `make rebuild` | 重建生产镜像（无缓存） |
| `make up` | 启动生产服务 |
| `make down` | 停止生产服务 |
| `make logs` | 查看生产日志 |
| `make ps` | 查看生产服务状态 |
| `make shell` | 进入生产容器 |
| `make clean` | 清理生产环境 |

## 更新插件

```bash
# 1. 拉取最新代码
cd extensions/translate_flarum
git pull

# 2. 重新构建镜像
cd /mnt/d/dockers/flarum
make dev-rebuild  # 开发环境
# 或
make rebuild      # 生产环境
```

## 环境变量说明

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `FLARUM_BASE_URL` | Flarum 访问地址 | `http://localhost:8080` |
| `FLARUM_FORCE_HTTPS` | 强制 HTTPS | `false` |
| `DB_ROOT_PASSWORD` | MariaDB root 密码 | - |
| `DB_NAME` | 数据库名 | `flarum` |
| `DB_USER` | 数据库用户 | `flarum_user` |
| `DB_PASSWORD` | 数据库密码 | - |
| `REDIS_HOST` | Redis 主机 | `cache` |
| `REDIS_PORT` | Redis 端口 | `6379` |

LLM API Key 不再通过环境变量传递，改为在 Flarum Admin 后台配置。

## 插件配置

Flarum 启动后，需要在 Admin 面板配置翻译插件。

进入 Admin → Extensions → Translate → Settings，配置以下项：

| Setting | 类型 | 默认值 | 说明 |
|---------|------|--------|------|
| `Auto Translate` | 开关 | 开启 | 自动翻译开关（发帖/编辑帖时自动触发） |
| `LLM Base URL` | 文本 | `http://opencode-go:3000` | opencode-go API base URL |
| `LLM API Key` | 密码 | 空 | opencode-go API 密钥 |
| `LLM Model` | 文本 | `deepseek-v4-flash` | 模型 ID |
| `LLM Timeout` | 数字 | `120` | 整体超时秒数 |
| `LLM Max Retries` | 数字 | `1` | 同 provider 重试次数 |
| `Lang Map` | 多行文本 | `zh:Simplified Chinese\nja:Japanese\nen:English\n...` | 目标语言映射（一行 `code:name`） |
| `System Prompt` | 多行文本 | ACGN 翻译规则模板 | 系统提示词模板（`{lang_name}` 占位符自动替换） |
| `Allow Guests` | 开关 | 开启 | 游客可见译文 + 可触发重试 |

### 管理员翻译管理页面

此外，Admin 后台提供专用的翻译管理页面（路径: Admin → Translate）：

- **Logs**: 翻译日志，分页查看每篇帖子的翻译记录，可展开查看完整 prompt / response
- **Prompt**: 当前 system prompt 只读预览
- **Backfill**: 批量补译 — 选择目标语言，扫描全站缺译帖子，一键触发翻译

## 常见问题

### Q: 如何重置数据库？

```bash
make dev-down
sudo rm -rf mysql-dev/*
make dev-up
```

### Q: 如何查看翻译日志？

```bash
# 方式一：Admin 后台 → Translate → Logs tab
# 方式二：查看 translator-worker 容器日志
docker logs -f flarum-docker-translator-worker-1

# 或快捷命令
make dev-logs
```

### Q: 如何批量补译已有帖子？

1. 进入 Admin 后台 → Translate → Backfill tab
2. 选择目标语言，点击"扫描并补译"
3. 系统自动扫描全站缺译帖子并加入翻译队列
4. 页面实时显示翻译进度

### Q: translator-worker 是否正常运行？

```bash
# 查看 health check 状态
docker ps | grep translator-worker

# 查看 worker 日志
docker logs -f flarum-docker-translator-worker-1
# 正常运行时可见流式翻译输出（每个 token 实时打印）
```

### Q: 如何备份数据？

```bash
# 备份数据库
docker exec flarum-dev-db-1 mysqldump -u root -p flarum > backup.sql

# 备份 Flarum 数据
tar -czf data-backup.tar.gz data-dev/
```

## License

MIT
