#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  SQLBot 服务状态${NC}"
echo -e "${BLUE}========================================${NC}"

# 检查端口函数
check_service() {
    PORT=$1
    SERVICE=$2
    PID=$(lsof -t -i:$PORT 2>/dev/null)
    if [ ! -z "$PID" ]; then
        echo -e "${GREEN}✓ $SERVICE (端口 $PORT) - 运行中 [PID: $PID]${NC}"
        return 0
    else
        echo -e "${RED}✗ $SERVICE (端口 $PORT) - 未运行${NC}"
        return 1
    fi
}

# 检查各服务
check_service 5173 "前端服务"
check_service 8000 "后端主服务"
check_service 8001 "MCP服务"
check_service 3000 "G2-SSR服务"
check_service 5432 "PostgreSQL"

echo -e "${BLUE}========================================${NC}"

# 检查虚拟环境
if [ -d "backend/.venv" ]; then
    echo -e "${GREEN}✓ Python 虚拟环境已创建${NC}"
    if [ "$VIRTUAL_ENV" != "" ]; then
        echo -e "${GREEN}  虚拟环境已激活: $VIRTUAL_ENV${NC}"
    else
        echo -e "${YELLOW}  虚拟环境未激活${NC}"
    fi
else
    echo -e "${RED}✗ Python 虚拟环境未创建${NC}"
fi

echo -e "${BLUE}========================================${NC}"

# 检查日志文件
if [ -d "logs" ]; then
    echo -e "${YELLOW}最近的日志（最后5行）：${NC}"
    for log in logs/*.log; do
        if [ -f "$log" ]; then
            filename=$(basename "$log")
            echo -e "${BLUE}$filename:${NC}"
            tail -n 5 "$log" 2>/dev/null | sed 's/^/  /' || echo "  [日志文件为空]"
            echo ""
        fi
    done
else
    echo -e "${YELLOW}日志目录不存在${NC}"
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}提示：${NC}"
echo -e "  启动服务: ./dev-start.sh"
echo -e "  停止服务: ./dev-stop.sh"
echo -e "  查看日志: ./dev-logs.sh"