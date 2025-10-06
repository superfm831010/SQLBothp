#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  SQLBot 开发环境启动脚本${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查是否已经有服务在运行
check_port() {
    lsof -i:$1 > /dev/null 2>&1
    return $?
}

# 创建日志目录
mkdir -p logs

# 1. 启动 PostgreSQL（如果使用 Docker）
if command -v docker &> /dev/null; then
    echo -e "${YELLOW}检查 PostgreSQL 容器...${NC}"
    if ! docker ps | grep -q "postgres-dev"; then
        echo -e "${GREEN}启动 PostgreSQL...${NC}"
        docker run -d \
            --name postgres-dev \
            -e POSTGRES_USER=root \
            -e POSTGRES_PASSWORD=Password123@pg \
            -e POSTGRES_DB=sqlbot \
            -p 5432:5432 \
            postgres:13
        sleep 5
    else
        echo -e "${GREEN}PostgreSQL 已在运行${NC}"
    fi
fi

# 2. 启动后端服务
echo -e "${YELLOW}启动后端服务...${NC}"
cd backend

# 检查虚拟环境
if [ ! -d ".venv" ]; then
    echo -e "${RED}虚拟环境不存在，创建中...${NC}"
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    echo -e "${GREEN}请运行 'pip install -r requirements.txt' 安装依赖${NC}"
else
    source .venv/bin/activate
fi

# 启动主服务
if check_port 8000; then
    echo -e "${YELLOW}端口 8000 已被占用，跳过后端主服务${NC}"
else
    echo -e "${GREEN}启动后端主服务（端口 8000）...${NC}"
    nohup uvicorn main:app --host 0.0.0.0 --port 8000 --reload > ../logs/backend.log 2>&1 &
    echo $! > ../logs/backend.pid
fi

# 启动 MCP 服务
if check_port 8001; then
    echo -e "${YELLOW}端口 8001 已被占用，跳过 MCP 服务${NC}"
else
    echo -e "${GREEN}启动 MCP 服务（端口 8001）...${NC}"
    nohup uvicorn main:mcp_app --host 0.0.0.0 --port 8001 > ../logs/mcp.log 2>&1 &
    echo $! > ../logs/mcp.pid
fi

cd ..

# 3. 启动 G2-SSR 服务
if [ -d "g2-ssr" ]; then
    echo -e "${YELLOW}启动 G2-SSR 服务...${NC}"
    cd g2-ssr
    if check_port 3000; then
        echo -e "${YELLOW}端口 3000 已被占用，跳过 G2-SSR${NC}"
    else
        echo -e "${GREEN}启动 G2-SSR（端口 3000）...${NC}"
        nohup node app.js > ../logs/g2ssr.log 2>&1 &
        echo $! > ../logs/g2ssr.pid
    fi
    cd ..
fi

# 4. 启动前端服务
echo -e "${YELLOW}启动前端服务...${NC}"
cd frontend

# 检查 node_modules
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}安装前端依赖...${NC}"
    npm install
fi

if check_port 5173; then
    echo -e "${YELLOW}端口 5173 已被占用，跳过前端服务${NC}"
else
    echo -e "${GREEN}启动前端开发服务器（端口 5173）...${NC}"
    nohup npm run dev > ../logs/frontend.log 2>&1 &
    echo $! > ../logs/frontend.pid
fi

cd ..

# 等待服务启动
echo -e "${YELLOW}等待服务启动...${NC}"
sleep 5

# 显示服务状态
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  服务启动完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}访问地址：${NC}"
echo -e "  前端界面: http://localhost:5173"
echo -e "  后端 API: http://localhost:8000"
echo -e "  API 文档: http://localhost:8000/docs"
echo -e "  MCP 服务: http://localhost:8001"
echo -e ""
echo -e "${YELLOW}查看日志：${NC}"
echo -e "  tail -f logs/backend.log  # 后端日志"
echo -e "  tail -f logs/frontend.log # 前端日志"
echo -e "  tail -f logs/mcp.log      # MCP 日志"
echo -e ""
echo -e "${YELLOW}停止服务请运行: ./dev-stop.sh${NC}"