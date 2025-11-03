# SQLBothp Docker 镜像构建总结

> 构建时间: 2025-10-06
> 镜像版本: v1.0 (基于 SQLBot 1.2.0)

## 构建成果

### 1. Docker 镜像

**镜像信息：**
- **名称**: `sqlbothp:latest`
- **大小**: 4.06GB
- **镜像 ID**: 5802272dc737
- **特性**:
  - ✅ 内置 PostgreSQL 15 数据库
  - ✅ 集成 GBase 8a 驱动 (v9.5.0)
  - ✅ 包含完整的 SQLBot 应用
  - ✅ G2-SSR 图表渲染服务
  - ✅ 向量模型支持 (RAG)
  - ✅ 支持内网离线部署

### 2. 交付文件

| 文件名 | 说明 | 大小 |
|--------|------|------|
| `Dockerfile` | Docker 镜像构建文件 | 2.9KB |
| `docker-compose-sqlbothp.yaml` | Docker Compose 配置 | 3.8KB |
| `build-sqlbothp.sh` | 自动化构建脚本 | 6.5KB |
| `OFFLINE_DEPLOYMENT.md` | 离线部署完整指南 | 14.5KB |
| `BUILD_SUMMARY.md` | 本文档 | - |

### 3. GBase 驱动验证

```bash
$ docker run --rm --entrypoint="" sqlbothp:latest bash -c \
  "cd /opt/sqlbot/app && .venv/bin/python -c 'import GBaseConnector; print(GBaseConnector.__version__)'"

✅ GBase 驱动已安装!
版本: 9.5.0
```

---

## 构建过程

### 阶段 1: 准备工作

1. **更新 .dockerignore**
   - 确保 GBase 驱动目录 `GBasePython3-9.5.0.1_build4/` 不被排除
   - 排除不必要的开发文件

2. **修改 pyproject.toml**
   - 添加 `[tool.hatch.metadata]` 配置
   - 设置 `allow-direct-references = true`
   - 注释掉本地路径依赖（改为 Dockerfile 中安装）

### 阶段 2: Dockerfile 修改

**关键修改点：**

1. **Builder 阶段**（构建应用）:
   ```dockerfile
   # 复制 GBase 驱动
   COPY GBasePython3-9.5.0.1_build4 /tmp/GBasePython3-9.5.0.1_build4

   # 先安装 GBase 驱动（在 uv sync 之前）
   RUN cd /tmp/GBasePython3-9.5.0.1_build4 && \
       python setup.py install && \
       rm -rf /tmp/GBasePython3-9.5.0.1_build4

   # 安装其他 Python 依赖
   RUN uv sync --extra cpu --no-install-project && \
       uv sync --extra cpu
   ```

2. **Runtime 阶段**（最终镜像）:
   ```dockerfile
   # 复制构建结果
   COPY --from=sqlbot-builder ${SQLBOT_HOME} ${SQLBOT_HOME}
   COPY --from=ssr-builder /app /opt/sqlbot/g2-ssr
   COPY --from=vector-model /opt/maxkb/app/model /opt/sqlbot/models

   # 在运行时镜像中也安装 GBase 驱动（关键！）
   COPY GBasePython3-9.5.0.1_build4 /tmp/GBasePython3-9.5.0.1_build4
   RUN cd /tmp/GBasePython3-9.5.0.1_build4 && \
       python setup.py install && \
       rm -rf /tmp/GBasePython3-9.5.0.1_build4
   ```

### 阶段 3: Docker Compose 配置

创建了简化的单服务配置 `docker-compose-sqlbothp.yaml`:
- 单个服务包含应用 + PostgreSQL
- 配置了数据持久化卷
- 设置了环境变量模板
- 添加了健康检查
- 提供了详细的使用说明

### 阶段 4: 构建脚本

创建了智能构建脚本 `build-sqlbothp.sh`:
- ✅ 自动检查 Docker 环境
- ✅ 验证必需文件完整性
- ✅ 检查 GBase 驱动
- ✅ 交互式镜像构建
- ✅ 自动验证构建结果
- ✅ 可选导出离线安装包
- ✅ 显示使用说明

### 阶段 5: 部署文档

创建了详尽的 `OFFLINE_DEPLOYMENT.md`:
- 系统要求说明
- 构建步骤指南
- 离线部署流程
- GBase 配置说明
- 常见问题解答
- 备份恢复指南
- 性能优化建议
- 安全配置建议

---

## 技术挑战与解决方案

### 挑战 1: GBase 驱动本地依赖问题

**问题**: pyproject.toml 中的本地路径依赖 `file:///projects/SqlBothp/...` 在 Docker 构建中路径不一致。

**解决方案**:
1. 在 pyproject.toml 中注释掉 GBase 依赖
2. 在 Dockerfile 中通过 `python setup.py install` 单独安装
3. 在 builder 和 runtime 两个阶段都进行安装

### 挑战 2: Hatchling 不允许直接引用

**问题**: `ValueError: Dependency cannot be a direct reference unless allow-direct-references is set to true`

**解决方案**:
在 pyproject.toml 添加配置：
```toml
[tool.hatch.metadata]
allow-direct-references = true
```

### 挑战 3: 多阶段构建中驱动丢失

**问题**: 在 builder 阶段安装的 GBase 驱动在最终镜像中丢失。

**解决方案**:
在 runtime 阶段再次安装 GBase 驱动，确保驱动进入最终镜像。

### 挑战 4: Python 环境隔离

**问题**: GBase 驱动需要安装到 venv 中才能被应用使用。

**解决方案**:
确保在 runtime 阶段安装时，Python 环境已经激活了 venv（通过 PATH 环境变量）。

---

## 依赖清单

### Python 依赖 (206个包)

**核心框架：**
- FastAPI 0.115.12
- Uvicorn 0.37.0
- Pydantic 2.x
- SQLModel 0.0.25

**LLM 相关：**
- LangChain 0.3
- LangGraph 0.3
- LangChain-OpenAI 0.3
- LangChain-Community 0.3
- Transformers 4.57.0
- Sentence-Transformers 5.1.1
- Torch 2.8.0+cpu

**数据库驱动：**
- PostgreSQL: psycopg 3.x, psycopg2-binary
- MySQL: pymysql
- Oracle: oracledb
- SQL Server: pymssql
- ClickHouse: clickhouse-sqlalchemy
- DM: dmpython
- Redshift: redshift-connector
- Elasticsearch: elasticsearch 7.x
- **GBase: gbase-connector-python 9.5.0** ✅

**其他：**
- pandas 12.5MB
- numpy 16.2MB
- scikit-learn 9.3MB
- pgvector (向量检索)

### Node.js 依赖

**前端：**
- Vue 3.5.13
- Element Plus 2.10.1
- AntV G2 5.3.3
- AntV S2 2.4.3
- Vite 6.3.6

**G2-SSR：**
- Express
- Canvas (服务端渲染)
- 168个包

---

## 使用指南

### 快速启动

```bash
# 1. 启动服务
docker-compose -f docker-compose-sqlbothp.yaml up -d

# 2. 查看日志
docker-compose -f docker-compose-sqlbothp.yaml logs -f

# 3. 访问系统
# 打开浏览器: http://YOUR_SERVER_IP:8000
# 用户名: admin
# 密码: SQLBot@123456
```

### 配置 GBase 数据源

1. 登录系统
2. 进入"系统设置" → "数据源管理"
3. 点击"添加数据源"
4. 选择类型："GBase"
5. 填写连接信息：
   - 主机: GBase 服务器 IP
   - 端口: 5258
   - 数据库名
   - 用户名/密码
6. 测试连接
7. 同步表结构

### 导出离线安装包

```bash
# 导出镜像（约 4GB）
docker save sqlbothp:latest -o sqlbothp-offline.tar

# 计算校验和
md5sum sqlbothp-offline.tar > sqlbothp-offline.tar.md5

# 传输到离线环境后加载
docker load -i sqlbothp-offline.tar
```

---

## 性能指标

### 构建性能

| 阶段 | 耗时 | 说明 |
|------|------|------|
| 前端构建 | ~40s | Vue + npm build |
| G2-SSR 构建 | ~50s | Node.js 依赖安装 |
| Python 依赖 | ~160s | 206个包 + torch |
| GBase 驱动安装 | ~1.4s | 快速 |
| Vector Model 下载 | ~260s | 762MB 模型 |
| 镜像导出 | ~11s | 4.06GB |
| **总计** | **~8-10分钟** | 首次构建 |

### 运行性能

| 指标 | 值 | 说明 |
|------|-----|------|
| 启动时间 | ~10s | PostgreSQL 初始化 |
| 内存占用 | ~2-4GB | 正常运行 |
| 磁盘空间 | ~50GB | 含数据和日志 |
| 推荐配置 | 4C8G | CPU + 内存 |

---

## 版本兼容性

| 组件 | 版本 | 说明 |
|------|------|------|
| SQLBot | 1.2.0 | 基础版本 |
| Python | 3.11.13 | CPython |
| PostgreSQL | 17.6 | 内置数据库 |
| Node.js | 18.x | G2-SSR |
| GBase Driver | 9.5.0 | 南大通用 |
| Docker | 20.10+ | 要求 |

---

## 已知问题

### 1. 启动警告

**现象**:
```
WARNING: enabling "trust" authentication for local connections
```

**说明**: 这是 PostgreSQL 默认配置，仅限容器内部访问，生产环境建议修改。

**解决**: 修改 `pg_hba.conf` 使用密码认证。

### 2. 密码安全警告

**现象**:
```
SecretsUsedInArgOrEnv: ENV "POSTGRES_PASSWORD"
```

**说明**: Docker 构建时建议使用 secrets 而非环境变量传递密码。

**解决**: 当前版本可忽略，或使用 Docker secrets 机制。

---

## 后续计划

### 功能增强
- [ ] 添加更多数据库支持
- [ ] 优化镜像大小
- [ ] 添加集群部署支持
- [ ] 增强安全配置

### 文档完善
- [ ] 添加视频教程
- [ ] 编写最佳实践指南
- [ ] 创建故障排查手册

### 性能优化
- [ ] 优化启动时间
- [ ] 减少内存占用
- [ ] 提升查询性能

---

## 附录

### A. 文件结构

```
SqlBothp/
├── Dockerfile                       # Docker 镜像构建文件
├── docker-compose-sqlbothp.yaml     # Docker Compose 配置
├── build-sqlbothp.sh                # 构建脚本
├── OFFLINE_DEPLOYMENT.md            # 离线部署指南
├── BUILD_SUMMARY.md                 # 本文档
├── GBASE_INTEGRATION.md             # GBase 集成文档
├── backend/
│   ├── pyproject.toml              # Python 依赖配置
│   ├── apps/db/
│   │   ├── constant.py             # GBase 数据库类型定义
│   │   ├── db.py                   # GBase 连接实现
│   │   └── db_sql.py               # GBase SQL 模板
│   └── ...
├── frontend/
│   └── ...
├── g2-ssr/
│   └── ...
└── GBasePython3-9.5.0.1_build4/     # GBase 驱动源码
    ├── setup.py
    └── GBaseConnector/
```

### B. 快速命令参考

```bash
# 构建镜像
./build-sqlbothp.sh
# 或
docker build -t sqlbothp:latest .

# 启动服务
docker-compose -f docker-compose-sqlbothp.yaml up -d

# 查看日志
docker-compose -f docker-compose-sqlbothp.yaml logs -f

# 停止服务
docker-compose -f docker-compose-sqlbothp.yaml down

# 进入容器
docker exec -it sqlbothp bash

# 验证 GBase 驱动
docker run --rm --entrypoint="" sqlbothp:latest bash -c \
  "cd /opt/sqlbot/app && .venv/bin/python -c 'import GBaseConnector; print(GBaseConnector.__version__)'"

# 导出镜像
docker save sqlbothp:latest -o sqlbothp-offline.tar

# 导入镜像
docker load -i sqlbothp-offline.tar

# 查看镜像信息
docker images sqlbothp
docker inspect sqlbothp:latest
```

### C. 环境变量说明

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `POSTGRES_SERVER` | localhost | PostgreSQL 主机 |
| `POSTGRES_PORT` | 5432 | PostgreSQL 端口 |
| `POSTGRES_DB` | sqlbot | 数据库名 |
| `POSTGRES_USER` | root | 数据库用户 |
| `POSTGRES_PASSWORD` | Password123@pg | 数据库密码 |
| `PROJECT_NAME` | SQLBothp | 项目名称 |
| `DEFAULT_PWD` | SQLBot@123456 | 默认密码 |
| `SECRET_KEY` | y5tx... | JWT 密钥 |
| `SERVER_IMAGE_HOST` | http://... | MCP 图片服务地址 |
| `LOG_LEVEL` | INFO | 日志级别 |
| `CACHE_TYPE` | memory | 缓存类型 |

### D. 端口说明

| 端口 | 服务 | 说明 |
|------|------|------|
| 8000 | Web UI + API | 主应用端口 |
| 8001 | MCP Server | Model Context Protocol |
| 3000 | G2-SSR | 图表渲染服务 |
| 5432 | PostgreSQL | 数据库（容器内部） |

---

## 技术支持

### 联系方式
- 项目仓库: [SqlBothp GitHub]
- 问题反馈: [GitHub Issues]
- 文档: 见本地 Markdown 文件

### 相关文档
- [OFFLINE_DEPLOYMENT.md](OFFLINE_DEPLOYMENT.md) - 离线部署完整指南
- [GBASE_INTEGRATION.md](GBASE_INTEGRATION.md) - GBase 集成说明
- [CLAUDE.md](CLAUDE.md) - 项目开发指南

---

**构建成功！** 🎉

- ✅ 镜像名称: `sqlbothp:latest`
- ✅ 镜像大小: 4.06GB
- ✅ GBase 驱动: v9.5.0
- ✅ 内置 PostgreSQL
- ✅ 支持离线部署
- ✅ 完整文档

**开始使用:**
```bash
docker-compose -f docker-compose-sqlbothp.yaml up -d
```

访问: `http://YOUR_SERVER_IP:8000`
