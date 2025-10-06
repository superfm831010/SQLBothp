#!/bin/bash

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}🔄 SQLBot 上游仓库同步工具${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# 检查是否有未提交的更改
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}❌ 错误: 工作区有未提交的更改${NC}"
    echo -e "${YELLOW}请先提交或暂存更改:${NC}"
    git status --short
    exit 1
fi

# 保存当前分支
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${YELLOW}当前分支: ${CURRENT_BRANCH}${NC}"
echo ""

# 1. 获取上游更新
echo -e "${YELLOW}📥 步骤 1/5: 获取上游更新...${NC}"
if git fetch upstream; then
    echo -e "${GREEN}✅ 上游更新获取成功${NC}"
else
    echo -e "${RED}❌ 获取上游更新失败${NC}"
    exit 1
fi
echo ""

# 2. 更新 main 分支
echo -e "${YELLOW}🔀 步骤 2/5: 更新 main 分支...${NC}"
git checkout main

# 显示将要合并的提交
echo -e "${BLUE}上游新增提交:${NC}"
git log --oneline main..upstream/main | head -10

echo ""
read -p "是否继续合并? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if git merge upstream/main; then
        echo -e "${GREEN}✅ main 分支更新成功${NC}"
        git push origin main
    else
        echo -e "${RED}❌ 合并失败，请手动解决冲突${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  跳过 main 分支更新${NC}"
    git checkout $CURRENT_BRANCH
    exit 0
fi
echo ""

# 3. 更新 feature/gbase-support 分支
echo -e "${YELLOW}🔀 步骤 3/5: 更新 feature/gbase-support 分支...${NC}"
git checkout feature/gbase-support

# 显示将要合并的提交
echo -e "${BLUE}main 分支新增提交:${NC}"
git log --oneline feature/gbase-support..main | head -10

echo ""
echo -e "${YELLOW}准备将 main 合并到 feature/gbase-support...${NC}"
if git merge main; then
    echo -e "${GREEN}✅ feature/gbase-support 分支更新成功${NC}"
    git push origin feature/gbase-support
else
    echo -e "${RED}❌ 发现合并冲突！${NC}"
    echo ""
    echo -e "${YELLOW}冲突文件列表:${NC}"
    git diff --name-only --diff-filter=U
    echo ""
    echo -e "${YELLOW}请按以下步骤解决冲突:${NC}"
    echo "1. 手动编辑冲突文件"
    echo "2. git add <已解决的文件>"
    echo "3. git commit"
    echo "4. git push origin feature/gbase-support"
    echo ""
    echo -e "${BLUE}GBase 关键修改文件:${NC}"
    echo "  - backend/apps/db/db.py (保留所有 'gbase' 类型的代码块)"
    echo "  - backend/pyproject.toml (保留 gbase-connector-python 依赖)"
    echo "  - backend/apps/datasource/crud/datasource.py (保留 GBase SQL 逻辑)"
    exit 1
fi
echo ""

# 4. 返回原分支
echo -e "${YELLOW}🔙 步骤 4/5: 返回原分支 ${CURRENT_BRANCH}...${NC}"
git checkout $CURRENT_BRANCH
echo -e "${GREEN}✅ 已返回${NC}"
echo ""

# 5. 总结
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}✅ 步骤 5/5: 同步完成！${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "${YELLOW}更新摘要:${NC}"
git log --oneline upstream/main -5
echo ""
echo -e "${YELLOW}建议执行:${NC}"
echo "1. 测试 GBase 功能是否正常"
echo "2. 运行完整测试套件"
echo "3. 更新 GBASE_MAINTENANCE.md 文档"
echo ""
