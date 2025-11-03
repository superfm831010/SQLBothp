# SQLBothp 离线部署指南

> **SQLBothp**: 支持 GBase 8a 数据库的 SQLBot 内网离线版本

本文档介绍如何在内网离线环境部署 SQLBothp 系统。

## 📋 目录

- [系统要求](#系统要求)
- [准备工作](#准备工作)
- [构建镜像](#构建镜像)
- [导出镜像](#导出镜像)
- [离线部署](#离线部署)
- [GBase 数据源配置](#gbase-数据源配置)
- [常见问题](#常见问题)
- [备份与恢复](#备份与恢复)

---

## 系统要求

### 硬件要求
- CPU: 4 核心及以上
- 内存: 8GB 及以上（推荐 16GB）
- 磁盘: 50GB 可用空间

### 软件要求
- 操作系统: Linux (推荐 Ubuntu 20.04+, CentOS 7+)
- Docker: 20.10 及以上版本
- Docker Compose: 1.29 及以上版本

### 网络要求
- **构建环境**: 需要互联网连接（下载基础镜像和依赖）
- **部署环境**: 无需互联网连接（纯离线环境）

---

## 准备工作

### 1. 确认项目完整性

确保项目包含以下关键文件和目录：

```bash
SqlBothp/
├── Dockerfile                          # Docker 镜像构建文件
├── docker-compose-sqlbothp.yaml        # Docker Compose 配置
├── build-sqlbothp.sh                   # 构建脚本
├── start.sh                            # 容器启动脚本
├── backend/                            # 后端代码
│   ├── pyproject.toml                 # Python 依赖配置
│   └── ...
├── frontend/                           # 前端代码
│   ├── package.json                   # Node.js 依赖配置
│   └── ...
├── g2-ssr/                            # 图表渲染服务
├── GBasePython3-9.5.0.1_build4/       # GBase 驱动（重要！）
│   ├── setup.py
│   └── GBaseConnector/
└── OFFLINE_DEPLOYMENT.md              # 本文档
```

### 2. 检查 GBase 驱动

```bash
# 确认 GBase 驱动目录存在
ls -lh GBasePython3-9.5.0.1_build4/

# 应该看到类似输出：
# total 68K
# drwxr-xr-x 5 root root 4.0K GBaseConnector
# -rw-r--r-- 1 root root 1.3K setup.py
# ...
```

---

## 构建镜像

### 方式一：使用自动化脚本（推荐）

```bash
# 进入项目目录
cd /projects/SqlBothp

# 执行构建脚本
./build-sqlbothp.sh
```

脚本会自动完成：
1. 检查 Docker 环境
2. 验证必需文件
3. 检查 GBase 驱动
4. 构建 Docker 镜像
5. 验证镜像完整性
6. 可选：导出离线安装包

### 方式二：手动构建

```bash
# 进入项目目录
cd /projects/SqlBothp

# 构建镜像
docker build -t sqlbothp:latest .

# 验证镜像
docker images | grep sqlbothp
```

**构建时间**: 约 10-30 分钟（取决于网络速度和机器性能）

**镜像大小**: 约 4-5 GB

---

## 导出镜像

在有网络的环境构建完镜像后，导出为 tar 文件以便传输到离线环境。

### 导出镜像

```bash
# 导出镜像到文件
docker save sqlbothp:latest -o sqlbothp-offline.tar

# 查看文件大小
ls -lh sqlbothp-offline.tar

# 计算 MD5（可选，用于验证传输完整性）
md5sum sqlbothp-offline.tar > sqlbothp-offline.tar.md5
```

### 传输文件

将以下文件传输到离线环境：

1. **sqlbothp-offline.tar** - Docker 镜像文件（约 4GB）
2. **docker-compose-sqlbothp.yaml** - Docker Compose 配置文件
3. **sqlbothp-offline.tar.md5** - MD5 校验文件（可选）

传输方式：
- USB 存储设备
- 内部文件服务器
- SCP/SFTP（如果内网可达）

---

## 离线部署

### 1. 加载镜像

在离线环境的目标服务器上：

```bash
# 验证 MD5（可选）
md5sum -c sqlbothp-offline.tar.md5

# 加载镜像到 Docker
docker load -i sqlbothp-offline.tar

# 验证镜像加载成功
docker images | grep sqlbothp
# 应该看到: sqlbothp   latest   xxxxx   xxxxx   4.xGB
```

### 2. 准备配置文件

```bash
# 创建部署目录
mkdir -p ~/sqlbothp-deploy
cd ~/sqlbothp-deploy

# 复制 docker-compose 配置文件到此目录
# (或者创建新的配置文件，内容见下文)
```

### 3. 修改配置

编辑 `docker-compose-sqlbothp.yaml`，修改以下关键配置：

```yaml
environment:
  # 修改 MCP 服务地址为实际服务器 IP
  SERVER_IMAGE_HOST: http://YOUR_SERVER_IP:8001/images/

  # 生产环境建议修改数据库密码
  POSTGRES_PASSWORD: YOUR_STRONG_PASSWORD

  # 建议修改密钥
  SECRET_KEY: YOUR_SECRET_KEY

  # 修改 CORS 配置（如果需要）
  BACKEND_CORS_ORIGINS: "http://YOUR_DOMAIN"
```

### 4. 创建数据目录

```bash
# 创建持久化数据目录
mkdir -p data/sqlbothp/{excel,file,images,logs,postgresql}

# 设置权限（重要！）
chmod -R 755 data/
```

### 5. 启动服务

```bash
# 启动服务
docker-compose -f docker-compose-sqlbothp.yaml up -d

# 查看服务状态
docker-compose -f docker-compose-sqlbothp.yaml ps

# 查看启动日志
docker-compose -f docker-compose-sqlbothp.yaml logs -f

# 等待服务就绪（约 1-2 分钟）
# 看到类似 "Application startup complete" 表示启动成功
```

### 6. 验证部署

```bash
# 检查端口监听
netstat -tlnp | grep -E '8000|8001|3000'

# 测试 API 访问
curl http://localhost:8000/api/health

# 浏览器访问
# http://YOUR_SERVER_IP:8000
```

### 7. 登录系统

- **访问地址**: `http://YOUR_SERVER_IP:8000`
- **默认账号**: `admin`
- **默认密码**: `SQLBot@123456`

**⚠️ 重要**: 首次登录后请立即修改默认密码！

---

## GBase 数据源配置

### 1. 登录系统

使用默认账号登录 SQLBothp Web 界面。

### 2. 添加 GBase 数据源

1. 进入 **"系统设置"** → **"数据源管理"**
2. 点击 **"添加数据源"**
3. 选择数据源类型: **"GBase"**
4. 填写连接信息：

| 配置项 | 说明 | 示例值 |
|--------|------|--------|
| 数据源名称 | 自定义名称 | `GBase生产库` |
| 主机地址 | GBase 服务器 IP | `192.168.1.100` |
| 端口 | GBase 端口 | `5258` |
| 数据库名 | 数据库名称 | `mydb` |
| 用户名 | GBase 用户 | `gbase` |
| 密码 | GBase 密码 | `******` |
| Schema | Schema 名称（可选） | `dbo` |

### 3. 测试连接

点击 **"测试连接"** 按钮，确保连接成功。

### 4. 同步表结构

连接成功后，点击 **"同步表结构"**，系统会自动获取数据库中的表和字段信息。

### 5. 开始使用

配置完成后，即可在聊天界面使用自然语言查询 GBase 数据库。

---

## 常见问题

### Q1: 容器启动失败

**症状**: `docker-compose up` 失败或容器反复重启

**解决方案**:
```bash
# 查看详细日志
docker-compose -f docker-compose-sqlbothp.yaml logs

# 检查常见问题：
# 1. 端口被占用
netstat -tlnp | grep -E '8000|8001|3000|5432'

# 2. 数据目录权限问题
chmod -R 755 data/

# 3. 磁盘空间不足
df -h
```

### Q2: 数据库初始化失败

**症状**: 日志显示 PostgreSQL 初始化错误

**解决方案**:
```bash
# 停止服务
docker-compose -f docker-compose-sqlbothp.yaml down

# 清空数据库目录（⚠️ 会丢失数据）
rm -rf data/sqlbothp/postgresql/*

# 重新启动
docker-compose -f docker-compose-sqlbothp.yaml up -d
```

### Q3: GBase 连接失败

**可能原因**:
1. GBase 服务未启动
2. 网络不通（防火墙/安全组）
3. 用户名密码错误
4. GBase 未授权远程连接

**诊断步骤**:
```bash
# 从容器内测试连接
docker exec -it sqlbothp bash

# 安装 telnet 测试端口连通性
apt-get update && apt-get install -y telnet
telnet GBASE_HOST 5258

# 查看应用日志
tail -f data/sqlbothp/logs/app.log
```

### Q4: 前端页面无法访问

**检查清单**:
1. 确认容器正在运行: `docker ps | grep sqlbothp`
2. 确认端口映射正确: `docker port sqlbothp`
3. 检查防火墙规则: `iptables -L | grep 8000`
4. 查看 nginx 日志（如果使用反向代理）

### Q5: 镜像加载失败

**症状**: `docker load` 报错

**解决方案**:
```bash
# 1. 验证文件完整性
md5sum -c sqlbothp-offline.tar.md5

# 2. 检查磁盘空间（需要约 2 倍镜像大小的空间）
df -h

# 3. 检查 Docker 根目录空间
docker info | grep "Docker Root Dir"

# 4. 清理旧镜像释放空间
docker system prune -a
```

---

## 备份与恢复

### 数据备份

**重要数据目录**:
- `data/sqlbothp/postgresql/` - 数据库文件（⭐ 最重要）
- `data/sqlbothp/images/` - 生成的图表图片
- `data/sqlbothp/logs/` - 应用日志

**备份命令**:
```bash
# 停止服务（推荐，确保数据一致性）
docker-compose -f docker-compose-sqlbothp.yaml stop

# 备份数据目录
tar -czf sqlbothp-backup-$(date +%Y%m%d).tar.gz data/

# 恢复服务
docker-compose -f docker-compose-sqlbothp.yaml start

# 或使用 PostgreSQL 导出（服务可以继续运行）
docker exec sqlbothp pg_dump -U root sqlbot > backup-$(date +%Y%m%d).sql
```

### 数据恢复

```bash
# 停止服务
docker-compose -f docker-compose-sqlbothp.yaml down

# 恢复数据目录
tar -xzf sqlbothp-backup-YYYYMMDD.tar.gz

# 启动服务
docker-compose -f docker-compose-sqlbothp.yaml up -d

# 或使用 SQL 文件恢复
docker exec -i sqlbothp psql -U root -d sqlbot < backup-YYYYMMDD.sql
```

---

## 服务管理命令

```bash
# 启动服务
docker-compose -f docker-compose-sqlbothp.yaml up -d

# 停止服务
docker-compose -f docker-compose-sqlbothp.yaml stop

# 重启服务
docker-compose -f docker-compose-sqlbothp.yaml restart

# 停止并删除容器（不删除数据）
docker-compose -f docker-compose-sqlbothp.yaml down

# 查看服务状态
docker-compose -f docker-compose-sqlbothp.yaml ps

# 查看实时日志
docker-compose -f docker-compose-sqlbothp.yaml logs -f

# 查看特定服务日志
docker-compose -f docker-compose-sqlbothp.yaml logs sqlbothp

# 进入容器
docker exec -it sqlbothp bash
```

---

## 版本升级

### 升级步骤

1. **备份数据**（重要！）
```bash
docker-compose -f docker-compose-sqlbothp.yaml stop
tar -czf sqlbothp-backup-before-upgrade.tar.gz data/
```

2. **获取新镜像**
```bash
# 在联网环境构建新版本镜像
# 或从其他途径获取新版本的 tar 文件

# 加载新镜像
docker load -i sqlbothp-new-version.tar
```

3. **更新服务**
```bash
# 停止旧容器
docker-compose -f docker-compose-sqlbothp.yaml down

# 修改 docker-compose.yaml 中的镜像标签（如果需要）

# 启动新容器
docker-compose -f docker-compose-sqlbothp.yaml up -d
```

4. **验证升级**
```bash
# 查看日志
docker-compose -f docker-compose-sqlbothp.yaml logs -f

# 登录系统验证功能
```

---

## 性能优化建议

### 1. 资源限制

编辑 `docker-compose-sqlbothp.yaml`，取消注释 `deploy` 部分：

```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 8G
    reservations:
      cpus: '2'
      memory: 4G
```

### 2. 数据库优化

```bash
# 进入容器
docker exec -it sqlbothp bash

# 连接数据库
psql -U root -d sqlbot

# 查看数据库大小
\l+

# 定期清理（可选）
VACUUM ANALYZE;
```

### 3. 日志清理

```bash
# 清理旧日志
find data/sqlbothp/logs/ -name "*.log" -mtime +30 -delete

# 配置日志轮转
# 编辑 docker-compose-sqlbothp.yaml，添加：
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

---

## 安全建议

1. **修改默认密码**: 首次登录后立即修改 admin 密码
2. **修改数据库密码**: 修改 `POSTGRES_PASSWORD` 环境变量
3. **修改密钥**: 修改 `SECRET_KEY` 环境变量
4. **防火墙规则**: 仅开放必要端口（8000, 8001）
5. **定期备份**: 建立定期备份机制
6. **日志审计**: 定期检查访问日志

---

## 技术支持

### 相关文档
- [GBase 集成说明](GBASE_INTEGRATION.md)
- [开发日志](GBASE_DEVELOPMENT_LOG.md)
- [维护指南](GBASE_MAINTENANCE.md)

### 问题反馈
如遇到问题，请收集以下信息：
1. 系统环境信息（OS, Docker 版本）
2. 完整的错误日志
3. 配置文件内容（脱敏后）
4. 复现步骤

---

## 附录

### A. 最小化 docker-compose.yaml 示例

```yaml
version: '3.8'
services:
  sqlbothp:
    image: sqlbothp:latest
    container_name: sqlbothp
    restart: always
    privileged: true
    ports:
      - "8000:8000"
      - "8001:8001"
    environment:
      POSTGRES_SERVER: localhost
      POSTGRES_DB: sqlbot
      POSTGRES_USER: root
      POSTGRES_PASSWORD: Password123@pg
      SECRET_KEY: y5txe1mRmS_JpOrUzFzHEu-kIQn3lf7ll0AOv9DQh0s
      SERVER_IMAGE_HOST: http://YOUR_IP:8001/images/
    volumes:
      - ./data/postgresql:/var/lib/postgresql/data
      - ./data/logs:/opt/sqlbot/app/logs
```

### B. 健康检查脚本

```bash
#!/bin/bash
# health-check.sh

echo "检查 SQLBothp 服务健康状态..."

# 检查容器运行
if ! docker ps | grep -q sqlbothp; then
    echo "❌ 容器未运行"
    exit 1
fi

# 检查 API 响应
if curl -f http://localhost:8000/api/health > /dev/null 2>&1; then
    echo "✅ API 服务正常"
else
    echo "❌ API 服务异常"
    exit 1
fi

# 检查数据库连接
if docker exec sqlbothp pg_isready -U root -d sqlbot > /dev/null 2>&1; then
    echo "✅ 数据库连接正常"
else
    echo "❌ 数据库连接异常"
    exit 1
fi

echo "✅ 所有服务正常"
```

---

**文档版本**: v1.0
**最后更新**: 2025-10-06
**适用于**: SQLBothp 1.2.0+ with GBase Support
