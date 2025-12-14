# SQLBot v1.4.0 上游同步日志

## 同步概要

| 项目 | 内容 |
|------|------|
| **同步日期** | 2025-12-14 |
| **上游版本** | v1.4.0 (代码版本 1.5.0) |
| **本地版本** | v1.4.0-gbase |
| **合并提交数** | 145 个 |
| **文件变更** | 146 个文件 (+7973/-2189 行) |
| **冲突文件** | 3 个 |

---

## 上游主要更新内容

### 新功能

1. **API 文档国际化** (#615)
   - 后端 API 文档支持多语言
   - 新增 `backend/apps/swagger/` 模块
   - 支持中英文切换

2. **API 权限控制** (#613)
   - 新增权限管理功能
   - `backend/apps/system/schemas/permission.py`

3. **表格字段更新功能**
   - 支持单表字段同步
   - `backend/apps/datasource/crud/datasource.py` 新增 `sync_single_fields`

4. **参数配置功能**
   - 新增系统参数管理
   - `backend/apps/system/api/parameter.py`
   - `frontend/src/views/system/parameter/`

5. **X-Pack 第三方平台支持**
   - 支持第三方平台作为默认登录方式
   - 新增 LDAP、OAuth2、OIDC 登录组件
   - `frontend/src/views/login/xpack/` 新增多个组件

6. **推荐问题功能**
   - `backend/apps/datasource/api/recommended_problem.py`
   - `frontend/src/views/ds/RecommendedProblemConfigDialog.vue`

7. **快速提问功能**
   - `frontend/src/views/chat/QuickQuestion.vue`
   - `frontend/src/views/chat/RecentQuestion.vue`

### Bug 修复

1. **饼图显示修复** - 修复饼图视觉比例显示不正确问题
2. **License 到期后重新上传错误** - 修复 license 过期后的上传问题
3. **template.yaml 语法格式修复** - 修正模板文件中的语法问题

### 依赖更新

- `sqlbot-xpack`: 0.0.3.44 → 0.0.4.0
- `dmpython`: >=2.5.22 → ==2.5.22 (固定版本)
- 新增: `ldap3>=2.9.1`

---

## 冲突解决记录

### 1. backend/apps/db/db.py

**冲突原因**: 上游大幅简化了 `check_connection` 函数，移除了大量重复代码，统一使用 `get_out_ds_conf` 处理 `AssistantOutDsSchema`。

**解决方案**:
- 采用上游的新结构（简化的开头逻辑）
- 在 else 分支中保留 GBase 的 elif 分支代码
- 保持 GBase 连接检查的完整性

**关键代码位置**: 第 174-285 行

### 2. backend/apps/system/crud/assistant.py

**冲突原因**:
- 导入语句: 上游添加了 `Trans`，我们添加了 `SQLBotLogUtil`
- `get_ds_from_api`: 上游添加了 `get_complete_endpoint` 逻辑

**解决方案**:
- 合并两个导入语句
- 在 `get_ds_from_api` 中先调用 `get_complete_endpoint`，然后保留本地的内网地址替换逻辑
- 保留 certificate 为 None 时的处理逻辑

### 3. backend/pyproject.toml

**冲突原因**: 版本号和依赖变更

**解决方案**:
- 接受上游版本号: 1.5.0
- 接受新依赖: `ldap3>=2.9.1`
- 保留 GBase 驱动注释: `# "gbase-connector-python @ file:///../GBasePython3-9.5.0.1_build4"`

---

## GBase 8a 支持状态

合并后 GBase 功能完整保留：

| 功能 | 状态 | 文件位置 |
|------|------|----------|
| 连接检查 | ✅ | `backend/apps/db/db.py:247-277` |
| 版本查询 | ✅ | `backend/apps/db/db.py:513-533` |
| Schema 获取 | ✅ | `backend/apps/db/db.py:584-604` |
| 表列表获取 | ✅ | `backend/apps/db/db.py:652-673` |
| 字段信息获取 | ✅ | `backend/apps/db/db.py:725-749` |
| SQL 执行 | ✅ | `backend/apps/db/db.py:857-905` |
| 不支持语法检测 | ✅ | `backend/apps/db/db.py:862-873` |

---

## 版本标签

```
v1.4.0-gbase   # 当前版本：v1.4.0 + GBase 支持
v1.3.0-gbase   # 上一版本：v1.3.0 + GBase 支持
v1.2.0-gbase   # GBase 支持初始版本
```

---

## 待办事项

- [ ] 推送 main 和 feature/gbase-support 分支到远程
- [ ] 推送 v1.4.0-gbase 标签到远程
- [ ] 运行完整测试验证 GBase 功能

### 推送命令

```bash
# 推送分支
git push origin main feature/gbase-support

# 推送标签
git push origin v1.4.0-gbase
```

---

## 相关文档

- [GBASE_MAINTENANCE.md](./GBASE_MAINTENANCE.md) - GBase 维护指南
- [SYNC_QUICKSTART.md](./SYNC_QUICKSTART.md) - 同步快速参考
- [UPSTREAM_SYNC_IMPLEMENTATION.md](./UPSTREAM_SYNC_IMPLEMENTATION.md) - 同步体系实施报告
