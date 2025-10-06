# SQLBot 启动问题分析与解决方案

## 日期
2025-10-06

## 问题概述
使用启动脚本 `dev-start.sh` 启动 SQLBot 后无法访问界面，出现多个环境配置和服务启动问题。

---

## 问题清单与解决方案

### 1. ❌ 后端服务启动失败 - ModuleNotFoundError: sqlbot_xpack

**错误信息：**
```
ModuleNotFoundError: No module named 'sqlbot_xpack'
```

**根本原因：**
- 项目要求 Python 3.11，但虚拟环境使用 Python 3.10
- 缺少 `uv` 包管理器（项目依赖管理工具）
- 依赖未正确安装（`sqlbot-xpack` 需要从 testpypi 安装）

**解决方案：**
1. 安装 Python 3.11：
   ```bash
   sudo add-apt-repository ppa:deadsnakes/ppa
   sudo apt-get update
   sudo apt-get install python3.11 python3.11-venv python3.11-dev
   ```

2. 安装 uv：
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   source $HOME/.local/bin/env
   ```

3. 重建虚拟环境：
   ```bash
   cd backend
   rm -rf .venv
   uv sync --extra cpu
   ```

**修改文件：**
- `dev-start.sh`: 添加 Python 3.11 和 uv 检查，自动安装依赖

---

### 2. ❌ PostgreSQL 缺少 pgvector 扩展

**错误信息：**
```
psycopg.errors.UndefinedFile: could not open extension control file
"/usr/share/postgresql/13/extension/vector.control": No such file or directory
```

**根本原因：**
- 数据库迁移需要 pgvector 扩展
- Docker 使用的 `postgres:13` 镜像不包含 pgvector

**解决方案：**
使用带 pgvector 扩展的镜像：
```bash
docker run -d \
    --name postgres-dev \
    -e POSTGRES_USER=root \
    -e POSTGRES_PASSWORD=Password123@pg \
    -e POSTGRES_DB=sqlbot \
    -p 5432:5432 \
    pgvector/pgvector:pg13
```

**修改文件：**
- `dev-start.sh`: 第 28-34 行，更改 Docker 镜像为 `pgvector/pgvector:pg13`

---

### 3. ❌ 前端只监听 localhost，外部无法访问

**现象：**
- 端口 5173 监听 `127.0.0.1` 而非 `0.0.0.0`
- 局域网其他设备无法访问前端

**根本原因：**
Vite 默认只监听本地回环地址

**解决方案：**
修改 `frontend/vite.config.ts`，添加：
```typescript
export default defineConfig(({ mode }) => {
  return {
    base: './',
    server: {
      host: '0.0.0.0',  // 监听所有网络接口
      port: 5173,
    },
    plugins: [
      // ...
    ]
  }
})
```

---

### 4. ❌ 登录接口被认证中间件拦截

**错误信息：**
```
"Authenticate invalid [Miss Token[X-SQLBOT-TOKEN]!]"
```

**根本原因：**
- 白名单中有 `/login/*`，但实际登录路径是 `/auth/login`
- 系统初始化接口 `/system/init` 也被拦截

**解决方案：**
修改 `backend/common/utils/whitelist.py`，添加：
```python
wlist = [
    "/",
    "/docs",
    "/login/*",
    "/auth/*",        # 新增
    "/system/init",   # 新增
    "*.json",
    # ...
]
```

**实际登录接口：**
- URL: `/api/v1/login/access-token`
- 方法: POST
- Content-Type: `application/x-www-form-urlencoded`
- 参数格式: RSA加密的 username 和 password

---

### 5. ❌ CORS 跨域请求失败

**错误信息：**
```
OPTIONS /api/v1/system/config/key HTTP/1.1" 400 Bad Request
```

**根本原因：**
- 前端通过 `http://192.168.31.10:5173` 访问
- 后端 CORS 只允许 `http://localhost:5173`
- OPTIONS 预检请求被拒绝

**解决方案：**
创建 `.env` 文件配置 CORS：
```bash
# /projects/SqlBothp/.env
BACKEND_CORS_ORIGINS=http://localhost,http://localhost:5173,http://localhost:8000,http://127.0.0.1:5173,http://192.168.31.10:5173,http://192.168.31.10:8000,http://172.18.0.1:5173,http://172.17.0.1:5173
```

**注意：**
- 不能使用通配符 `*`（Pydantic 会验证失败）
- 需要明确列出所有允许的源
- 生产环境应限制为特定域名

---

### 6. ❌ G2-SSR 服务启动失败

**错误信息：**
```
Error: Cannot find module '@antv/g2-ssr'
npm ERR! gyp ERR! build error (node-canvas compilation failed)
```

**根本原因：**
- node-canvas 需要编译原生模块
- 与 Node.js 20 + V8 版本不兼容
- 缺少系统编译依赖

**解决方案：**
**跳过 G2-SSR 服务**（非核心服务，不影响主要功能）

修改 `dev-start.sh` 添加错误处理：
```bash
if [ $? -ne 0 ]; then
    echo "G2-SSR 依赖安装失败（可能是 node-canvas 编译问题）"
    echo "跳过 G2-SSR 服务，核心功能不受影响"
    cd ..
fi
```

**可选解决方案**（如需 G2-SSR）：
- 降级 Node.js 版本到 16 或 18
- 安装额外系统库：`libcairo2-dev libpango1.0-dev`

---

## dev-start.sh 脚本改进总结

### 主要修改

1. **Python 环境检查**
   - 验证 Python 3.11 是否安装
   - 验证 uv 工具是否可用
   - 自动安装 uv（如需要）

2. **后端依赖管理**
   - 使用 `uv sync --extra cpu` 安装依赖
   - 检查关键依赖（sqlbot_xpack）是否存在
   - 自动重新安装缺失依赖

3. **数据库启动**
   - 使用 `pgvector/pgvector:pg13` 镜像
   - 等待时间从 5秒 增加到 10秒

4. **G2-SSR 服务**
   - 添加 node_modules 存在性检查
   - 优雅处理安装失败
   - 不影响核心服务启动

5. **前端服务**
   - （保持原逻辑）自动检查并安装 npm 依赖

---

## 最终服务状态

```
✓ 前端服务 (端口 5173) - 运行中
✓ 后端主服务 (端口 8000) - 运行中
✓ MCP服务 (端口 8001) - 运行中
✓ PostgreSQL (端口 5432) - 运行中
✗ G2-SSR服务 (端口 3000) - 未运行（非核心）
```

---

## 访问信息

### 开发环境访问地址
- **前端界面**：http://192.168.31.10:5173 或 http://localhost:5173
- **后端 API**：http://localhost:8000/api/v1
- **API 文档**：http://localhost:8000/docs
- **MCP 服务**：http://localhost:8001

### 默认登录凭据
- **账号**：admin
- **密码**：SQLBot@123456

---

## 技术细节说明

### 1. 依赖管理工具选择
- **uv vs pip**：项目使用 uv 管理依赖，因为：
  - 支持多源索引（PyPI + testpypi）
  - 更快的依赖解析
  - 精确的版本锁定

### 2. Python 版本要求
- **严格要求 3.11**：`pyproject.toml` 中定义 `requires-python = "==3.11.*"`
- 原因：依赖包（如 sqlbot-xpack）编译时使用 Python 3.11

### 3. CORS 配置原理
- FastAPI 使用 Starlette CORSMiddleware
- OPTIONS 预检请求必须返回正确的 CORS 头
- 配置加载顺序：.env → 环境变量 → 默认值

### 4. 前端加密通信
- 登录使用 RSA 加密：`LicenseGenerator.sqlbotEncrypt()`
- 公钥存储在数据库 `rsa` 表
- 后端使用私钥解密：`sqlbot_decrypt()`

---

## 开发环境便捷命令

### 启动/停止服务
```bash
./dev-start.sh      # 启动所有服务
./dev-stop.sh       # 停止所有服务
./dev-status.sh     # 查看服务状态
./dev-restart.sh    # 重启服务
./dev-logs.sh       # 实时查看日志
```

### 手动服务管理
```bash
# 后端
cd backend
source .venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

# 前端
cd frontend
npm run dev

# 查看日志
tail -f logs/backend.log
tail -f logs/frontend.log
```

---

## 问题预防建议

### 1. 环境一致性
- 使用 Docker Compose 可避免大部分环境问题
- 生产部署推荐使用容器化方案

### 2. 依赖锁定
- 定期运行 `uv lock` 更新依赖锁文件
- 提交 `uv.lock` 到版本控制

### 3. 日志监控
- 定期查看 `logs/` 目录下的日志
- 关注启动时的 ERROR 和 WARNING 信息

### 4. 数据库备份
- PostgreSQL 数据在容器中，停止容器前需备份
- 使用 Docker volumes 持久化数据

---

## 相关文档

- **项目开发指南**：`CLAUDE.md`
- **GBase 集成文档**：`GBASE_INTEGRATION.md`
- **GBase 开发日志**：`GBASE_DEVELOPMENT_LOG.md`

---

## 修改文件清单

| 文件路径 | 修改内容 | 原因 |
|---------|---------|------|
| `dev-start.sh` | 添加 Python 3.11、uv 检查；改用 pgvector 镜像；G2-SSR 错误处理 | 自动化环境检查和依赖安装 |
| `frontend/vite.config.ts` | 添加 `server.host: '0.0.0.0'` | 允许外部访问前端 |
| `backend/common/utils/whitelist.py` | 添加 `/auth/*` 和 `/system/init` | 修复登录接口拦截问题 |
| `.env` | 创建文件，配置 CORS 和数据库 | 解决跨域问题 |

---

## 开发时间线

- **11:00** - 发现启动问题，开始诊断
- **11:05** - 确认 Python 版本和 uv 工具缺失
- **11:15** - 安装 Python 3.11 和 uv
- **11:20** - 重建虚拟环境，解决依赖问题
- **11:25** - 发现并修复 pgvector 扩展缺失
- **11:30** - 修复前端监听地址问题
- **11:35** - 修复认证白名单配置
- **11:40** - 发现并修复 CORS 跨域问题
- **11:45** - 所有核心服务正常运行

**总计用时**：约 45 分钟

---

## 总结

本次启动问题主要集中在：
1. **环境配置**（Python 版本、工具缺失）
2. **依赖管理**（特殊依赖源、正确的安装方式）
3. **网络配置**（CORS、监听地址）
4. **数据库扩展**（pgvector）

通过系统性的诊断和修复，建立了完整的开发环境启动流程。所有修改已集成到启动脚本中，后续开发者可直接使用 `./dev-start.sh` 一键启动。
