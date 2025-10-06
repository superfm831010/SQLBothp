#!/bin/bash

# 颜色定义
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${YELLOW}重启 SQLBot 开发环境...${NC}"
echo "======================================"

# 先停止所有服务
./dev-stop.sh

echo ""
echo -e "${YELLOW}等待服务完全停止...${NC}"
sleep 2

# 再启动所有服务
./dev-start.sh

echo ""
echo -e "${GREEN}重启完成！${NC}"