# SQLBot v1.5.0 上游同步日志

## 同步概要

| 项目 | 内容 |
|------|------|
| **同步日期** | 2026-01-04 |
| **上游版本** | v1.5.0 |
| **本地版本** | v1.5.0-gbase |
| **合并提交数** | 134 个 |
| **文件变更** | 145 个文件 |
| **代码增减** | +91,595 行, -998 行 |
| **冲突文件** | 1 个 |

## 上游主要更新内容

### 新功能
1. **MCP 数据源功能** - MCP provide datasource
2. **审计日志功能** - `frontend/src/views/system/audit/` (+632 行)
3. **参数管理页面** - `frontend/src/views/system/parameter/` (新增)
4. **API Key 管理** - `backend/apps/system/api/apikey.py` (新增)
5. **Excel 上传备注** - `UploaderRemark.vue` (+347 行)
6. **用户批量导入增强** - `UserImport.vue` 重构

### Bug 修复
1. API 安全漏洞修复 (#714)
2. 嵌入管理弹窗关闭问题修复
3. API Key 删除提示信息修正
4. 数据源分页显示问题
5. 登录页面欢迎语显示问题
6. 数据源页面刷新白屏问题

### 依赖更新
- `sqlbot-xpack`: 0.0.3.59 → 0.0.4.0
- `version`: 1.4.0 → 1.5.0
- PyPI 镜像源: 清华 → 华科

### 数据库迁移
- `055_add_system_logs.py` - 系统日志表
- `056_api_key_ddl.py` - API Key 表
- `057_update_sys_log.py` - 更新系统日志
- `058_update_chat.py` - 更新聊天表
- `059_chat_log_resource.py` - 聊天日志资源

## 冲突解决记录

### 冲突文件 1: `backend/apps/system/crud/assistant.py`

**冲突位置**: 第 22-26 行，导入语句

**冲突原因**:
- GBase 分支添加了 `SQLBotLogUtil` 导入
- 上游添加了 `get_domain_list` 导入

**解决方案**: 合并两边的导入语句
```python
# 合并后
from common.utils.utils import equals_ignore_case, get_domain_list, string_to_numeric_hash, SQLBotLogUtil
```

### 恢复 stash 时的冲突: `backend/pyproject.toml`

**冲突原因**: PyPI 镜像源不同
- 上游: 华科镜像 `https://mirrors.hust.edu.cn/pypi/web/simple`
- 本地: 阿里云镜像 `https://mirrors.aliyun.com/pypi/simple/`

**解决方案**: 保留阿里云镜像（本地化需求）

## GBase 8a 支持状态

所有 GBase 功能完整保留：

| 检查项 | 文件 | 数量 | 状态 |
|--------|------|------|------|
| db.py GBase 分支 | `backend/apps/db/db.py` | 11 处 | ✅ |
| db_sql.py SQL 模板 | `backend/apps/db/db_sql.py` | 6 处 | ✅ |
| constant.py 枚举 | `backend/apps/db/constant.py` | 2 处 | ✅ |
| 前端类型定义 | `frontend/src/views/ds/js/ds-type.ts` | 7 处 | ✅ |
| SQL 示例模板 | `backend/templates/sql_examples/GBase.yaml` | 5.0 KB | ✅ |
| 数据源图标 | `frontend/src/assets/datasource/icon_gbase.png` | 1.4 KB | ✅ |

## Docker 镜像构建

### 构建信息
- 镜像名称: `sqlbothp:v1.5.0-gbase`, `sqlbothp:latest`
- 镜像大小: 6.73 GB
- 构建时间: 约 3 分钟（大部分缓存命中）
- GBase 驱动: 已验证安装成功

### Dockerfile 修改
修复了时间同步问题导致的 apt-get 失败：
```dockerfile
# 添加 -o Acquire::Check-Valid-Until=false 跳过时间验证
RUN apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update && ...
```

### 端口映射调整
`docker-compose-sqlbothp.yaml` 中 G2-SSR 端口从 3000 改为 3100（避免与其他服务冲突）：
```yaml
ports:
  - "8090:8000"   # Web UI
  - "8001:8001"   # MCP 服务
  - "3100:3000"   # G2-SSR（宿主机 3100）
```

## 版本标签

已创建本地标签：
```
v1.5.0-gbase - SQLBot v1.5.0 with GBase 8a support
```

推送到远程需要手动执行：
```bash
git push origin feature/gbase-support
git push origin main
git push origin v1.5.0-gbase
```

## 访问信息

- **Web UI**: http://localhost:8090
- **MCP 服务**: http://localhost:8001
- **G2-SSR**: http://localhost:3100
- **默认账号**: admin / SQLBot@123456

## 后续工作

1. [ ] 推送分支和标签到远程仓库
2. [ ] 完整功能测试
3. [ ] GBase 数据源连接测试
4. [ ] 新功能（审计日志、API Key）测试
