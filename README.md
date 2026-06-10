# Flarum Docker

自定义 Flarum Docker 部署，包含翻译插件和翻译后端服务。

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
# 编辑 .env 文件，修改数据库密码和 API Key
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
| Translator | http://localhost:8001 | 内部访问 |
| MariaDB | localhost:3307 | 内部访问 |

## 服务架构

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Flarum    │────▶│  Translator │────▶│ DeepSeek API│
│  (PHP/Nginx)│     │  (FastAPI)  │     │             │
└──────┬──────┘     └──────┬──────┘     └─────────────┘
       │                   │
       ▼                   ▼
┌─────────────┐     ┌─────────────┐
│   MariaDB   │◀────│    Redis    │
│             │     │   (Cache)   │
└─────────────┘     └─────────────┘
```

所有服务通过 `flarum-network` 网络连接，容器间使用服务名访问。

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
| `DEEPSEEK_API_KEY` | DeepSeek API Key | - |

## 插件配置

Flarum 启动后，需要在 Admin 面板配置翻译插件：

1. 访问 Flarum Admin 面板
2. 找到 "Translate" 插件
3. 配置 "FastAPI Base URL" 为 `http://translator:8000`
4. 根据需要配置其他选项

## 常见问题

### Q: 如何重置数据库？

```bash
make dev-down
sudo rm -rf mysql-dev/*
make dev-up
```

### Q: 如何查看翻译日志？

```bash
# 访问 Translator 的日志页面
curl http://localhost:8001/logs

# 或查看容器日志
make dev-logs
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