#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}========================================${NC}"
echo -e "${RED}  停止 SQLBot 开发环境${NC}"
echo -e "${RED}========================================${NC}"

# 停止服务函数
stop_service() {
    if [ -f "logs/$1.pid" ]; then
        PID=$(cat logs/$1.pid)
        if ps -p $PID > /dev/null 2>&1; then
            echo -e "${YELLOW}停止 $1 服务 (PID: $PID)...${NC}"
            kill $PID
            rm logs/$1.pid
        else
            echo -e "${GREEN}$1 服务未运行${NC}"
            rm logs/$1.pid
        fi
    else
        echo -e "${GREEN}$1 PID 文件不存在${NC}"
    fi
}

# 停止所有服务
stop_service "frontend"
stop_service "backend"
stop_service "mcp"
stop_service "g2ssr"

# 通过端口查找并停止遗漏的进程
echo -e "${YELLOW}检查并清理端口...${NC}"

# 清理端口函数
cleanup_port() {
    PORT=$1
    SERVICE=$2
    PID=$(lsof -t -i:$PORT 2>/dev/null)
    if [ ! -z "$PID" ]; then
        echo -e "${YELLOW}发现 $SERVICE 在端口 $PORT (PID: $PID)，停止中...${NC}"
        kill $PID 2>/dev/null
    fi
}

cleanup_port 8000 "后端主服务"
cleanup_port 8001 "MCP服务"
cleanup_port 3000 "G2-SSR"
cleanup_port 5173 "前端服务"

# 停止 PostgreSQL Docker 容器（可选）
if command -v docker &> /dev/null; then
    if docker ps | grep -q "postgres-dev"; then
        echo -e "${YELLOW}停止 PostgreSQL 容器...${NC}"
        docker stop postgres-dev
        docker rm postgres-dev
    fi
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  所有服务已停止！${NC}"
echo -e "${GREEN}========================================${NC}"