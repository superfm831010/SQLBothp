# Git 推送指南

## 当前状态

- ✅ 本地同步完成（v1.3.0-gbase）
- ✅ 所有修改已提交
- ⏳ 等待推送到 GitHub

## 需要推送的内容

### 1. main 分支
```bash
cd /projects/BI/SqlBothp
git checkout main
git push origin main
```

### 2. feature/gbase-support 分支（当前分支）
```bash
cd /projects/BI/SqlBothp
git checkout feature/gbase-support
git push origin feature/gbase-support
```

### 3. 版本标签
```bash
cd /projects/BI/SqlBothp
git push origin --tags
# 或推送单个标签：
git push origin v1.3.0-gbase
```

## 推送失败原因

当前推送失败是因为无法进行 GitHub 认证。有以下几种解决方案：

---

## 解决方案 1：使用 GitHub Personal Access Token (推荐)

### 步骤 1：创建 Personal Access Token

1. 访问 GitHub: https://github.com/settings/tokens
2. 点击 "Generate new token" → "Generate new token (classic)"
3. 设置权限：
   - ✅ `repo` (Full control of private repositories)
4. 点击 "Generate token"
5. **复制并保存** 生成的 token（只显示一次）

### 步骤 2：配置 Git Credential Helper

```bash
# 配置 credential helper（缓存凭据 1 小时）
git config --global credential.helper 'cache --timeout=3600'

# 或永久存储（不推荐，安全性较低）
git config --global credential.helper store
```

### 步骤 3：推送时输入凭据

```bash
cd /projects/BI/SqlBothp

# 第一次推送时会要求输入：
git push origin main

# Username: your_github_username
# Password: [粘贴刚才的 Personal Access Token]
```

**注意**：密码处输入的是 PAT，不是 GitHub 登录密码！

---

## 解决方案 2：切换到 SSH (推荐长期使用)

### 步骤 1：生成 SSH 密钥（如果还没有）

```bash
# 生成新的 SSH 密钥
ssh-keygen -t ed25519 -C "your_email@example.com"

# 按 Enter 使用默认路径
# 可以设置密码短语（推荐）或留空

# 启动 ssh-agent
eval "$(ssh-agent -s)"

# 添加私钥
ssh-add ~/.ssh/id_ed25519
```

### 步骤 2：添加公钥到 GitHub

```bash
# 显示公钥内容
cat ~/.ssh/id_ed25519.pub
```

1. 复制输出的公钥内容
2. 访问 GitHub: https://github.com/settings/keys
3. 点击 "New SSH key"
4. 粘贴公钥，点击 "Add SSH key"

### 步骤 3：切换远程仓库 URL

```bash
cd /projects/BI/SqlBothp

# 查看当前 URL（HTTPS）
git remote -v
# origin  https://github.com/superfm831010/SqlBothp (fetch)

# 切换到 SSH URL
git remote set-url origin git@github.com:superfm831010/SqlBothp.git

# 验证切换成功
git remote -v
# origin  git@github.com:superfm831010/SqlBothp.git (fetch)

# 测试连接
ssh -T git@github.com
# 应该看到: Hi superfm831010! You've successfully authenticated...
```

### 步骤 4：推送

```bash
# 现在可以直接推送，无需密码
git push origin main
git push origin feature/gbase-support
git push origin --tags
```

---

## 解决方案 3：临时禁用 SSL 验证（不推荐，仅用于测试）

```bash
# 仅在无法解决 SSL 问题时使用
git config --global http.sslVerify false

# 推送
git push origin main

# 推送后记得恢复
git config --global http.sslVerify true
```

---

## 解决方案 4：使用 GitHub CLI (gh)

如果安装了 GitHub CLI：

```bash
# 登录
gh auth login

# 推送
cd /projects/BI/SqlBothp
git push origin main
git push origin feature/gbase-support
git push origin --tags
```

---

## 验证推送成功

推送完成后，访问以下 URL 验证：

1. **main 分支**: https://github.com/superfm831010/SqlBothp/tree/main
2. **GBase 分支**: https://github.com/superfm831010/SqlBothp/tree/feature/gbase-support
3. **标签**: https://github.com/superfm831010/SqlBothp/tags

应该看到：
- ✅ v1.3.0-gbase 标签
- ✅ main 分支更新到 v1.3.0
- ✅ feature/gbase-support 分支包含 v1.3.0 + GBase 支持

---

## 快速推送命令（配置认证后）

```bash
cd /projects/BI/SqlBothp

# 一次性推送所有分支和标签
git push origin main feature/gbase-support --tags

# 或分别推送
git checkout main && git push origin main
git checkout feature/gbase-support && git push origin feature/gbase-support
git push origin --tags
```

---

## 常见问题

### Q1: 推送时提示 "Permission denied"
**A**: 检查 SSH 密钥是否正确添加到 GitHub，或者使用 PAT 认证。

### Q2: 推送时提示 "Authentication failed"
**A**: 如果使用 HTTPS，确保密码处输入的是 Personal Access Token，不是 GitHub 登录密码。

### Q3: 推送时卡住不动
**A**: 可能是网络问题，尝试：
```bash
# 增加 Git 缓冲区大小
git config --global http.postBuffer 524288000

# 使用 SSH 而不是 HTTPS
```

### Q4: 如何查看推送了哪些提交？
**A**:
```bash
# 查看待推送的提交
git log origin/main..main --oneline

# 查看待推送的标签
git tag -l | grep -v "$(git ls-remote --tags origin | awk '{print $2}' | sed 's|refs/tags/||')"
```

---

## 推送后的验证

```bash
# 确认远程状态
git fetch origin
git status

# 应该看到: Your branch is up to date with 'origin/...'

# 查看远程标签
git ls-remote --tags origin | grep v1.3.0-gbase
```

---

**推荐方案**: 使用 **Personal Access Token** 或 **SSH** 认证，这是最安全和稳定的方式。
