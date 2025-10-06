#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  SQLBot 实时日志监控${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}按 Ctrl+C 退出${NC}"
echo ""

# 创建日志目录（如果不存在）
mkdir -p logs

# 检查是否有日志文件
if ! ls logs/*.log 1> /dev/null 2>&1; then
    echo -e "${RED}没有找到日志文件${NC}"
    echo -e "${YELLOW}提示：先运行 ./dev-start.sh 启动服务${NC}"
    exit 1
fi

# 显示可用的日志文件
echo -e "${BLUE}可用的日志文件：${NC}"
for log in logs/*.log; do
    if [ -f "$log" ]; then
        filename=$(basename "$log")
        size=$(du -h "$log" | cut -f1)
        echo -e "  - $filename ($size)"
    fi
done
echo ""

# 检查是否安装了 multitail
if command -v multitail &> /dev/null; then
    echo -e "${GREEN}使用 multitail 查看日志（多窗口）${NC}"
    echo -e "${YELLOW}提示：按 q 退出，按 b 选择窗口${NC}"
    multitail -i logs/backend.log -i logs/frontend.log -i logs/mcp.log -i logs/g2ssr.log 2>/dev/null
else
    echo -e "${GREEN}使用 tail 查看所有日志${NC}"
    echo -e "${YELLOW}提示：不同服务的日志会混合显示${NC}"
    echo -e "${YELLOW}建议安装 multitail: apt install multitail${NC}"
    echo ""

    # 使用 tail -f 同时监控所有日志文件
    tail -f logs/*.log 2>/dev/null | while IFS= read -r line; do
        # 根据关键词给日志着色
        if echo "$line" | grep -q "ERROR\|Error\|error"; then
            echo -e "${RED}$line${NC}"
        elif echo "$line" | grep -q "WARNING\|Warning\|warning"; then
            echo -e "${YELLOW}$line${NC}"
        elif echo "$line" | grep -q "INFO\|Info\|info"; then
            echo -e "${GREEN}$line${NC}"
        elif echo "$line" | grep -q "DEBUG\|Debug\|debug"; then
            echo -e "${BLUE}$line${NC}"
        else
            echo "$line"
        fi
    done
fi