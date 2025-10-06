# 上游同步快速指南

## 快速开始

### 一键同步

```bash
./sync-upstream.sh
```

脚本会自动：
1. 获取上游最新代码
2. 合并到 main 分支
3. 合并到 feature/gbase-support 分支
4. 推送到远程仓库

## 手动同步（高级）

### 1. 同步 main 分支

```bash
git checkout main
git fetch upstream
git merge upstream/main
git push origin main
```

### 2. 同步 GBase 功能分支

```bash
git checkout feature/gbase-support
git merge main
# 如有冲突，参考 GBASE_MAINTENANCE.md 解决
git push origin feature/gbase-support
```

## 冲突解决

如果出现合并冲突：

1. **查看冲突文件**
   ```bash
   git diff --name-only --diff-filter=U
   ```

2. **打开 GBASE_MAINTENANCE.md**
   - 查找对应文件的修改说明
   - 按照"冲突解决策略"处理

3. **关键原则**
   - `backend/apps/db/db.py`: 保留所有 `elif ds.type == 'gbase':` 代码块
   - `backend/pyproject.toml`: 保留 `gbase-connector-python` 依赖
   - 其他文件: 合并上游改进，保留 GBase 逻辑

4. **解决后**
   ```bash
   git add <已解决的文件>
   git commit
   git push origin feature/gbase-support
   ```

## 测试

同步后必须测试：

```bash
# 基础连接测试
python test_gbase_connection.py

# 完整功能测试
python test_gbase_live.py

# 启动服务测试
./dev-start.sh
```

## 定期维护

**建议频率**: 每月一次

**步骤**:
1. 运行 `./sync-upstream.sh`
2. 执行完整测试套件
3. 更新 GBASE_MAINTENANCE.md（如有新修改）
4. 创建新的版本标签

## 版本标签

**创建标签**:
```bash
# 上游版本标签
git tag -a v1.3.0-upstream -m "SQLBot v1.3.0 from upstream"

# GBase 版本标签
git tag -a v1.3.0-gbase -m "SQLBot v1.3.0 with GBase support"

# 推送标签
git push origin --tags
```

## 远程仓库

```bash
# 查看远程仓库
git remote -v

# 应该看到：
# origin    https://github.com/superfm831010/SQLBothp (你的 fork)
# upstream  https://github.com/dataease/SQLBot (上游仓库)
```

## 故障排查

### 问题: 同步脚本报错 "upstream 不存在"

**解决方案**:
```bash
git remote add upstream https://github.com/dataease/SQLBot.git
```

### 问题: 合并后 GBase 功能不工作

**检查清单**:
1. [ ] `backend/pyproject.toml` 中 GBase 驱动依赖是否存在
2. [ ] `backend/apps/db/db.py` 中所有 GBase 代码块是否完整
3. [ ] 运行 `uv sync --extra cpu` 重新安装依赖
4. [ ] 查看日志: `tail -f logs/backend.log`

### 问题: 测试失败

**排查步骤**:
1. 检查 GBase Docker 容器是否运行: `docker ps | grep gbase`
2. 测试数据库连接: `python test_gbase_connection.py`
3. 查看详细错误: 运行测试时添加 `-v` 参数

## 更多信息

- **详细文档**: 查看 `GBASE_MAINTENANCE.md`
- **开发日志**: 查看 `GBASE_DEVELOPMENT_LOG.md`
- **上游仓库**: https://github.com/dataease/SQLBot
- **Fork 仓库**: https://github.com/superfm831010/SQLBothp

## 需要帮助？

创建 Issue: https://github.com/superfm831010/SQLBothp/issues
