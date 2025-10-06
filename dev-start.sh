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
        echo -e "${GREEN}启动 PostgreSQL (带 pgvector 扩展)...${NC}"
        # 使用带 pgvector 扩展的镜像
        docker run -d \
            --name postgres-dev \
            -e POSTGRES_USER=root \
            -e POSTGRES_PASSWORD=Password123@pg \
            -e POSTGRES_DB=sqlbot \
            -p 5432:5432 \
            pgvector/pgvector:pg13
        sleep 10
    else
        echo -e "${GREEN}PostgreSQL 已在运行${NC}"
    fi
fi

# 2. 启动后端服务
echo -e "${YELLOW}启动后端服务...${NC}"
cd backend

# 检查 Python 3.11
if ! command -v python3.11 &> /dev/null; then
    echo -e "${RED}错误：需要 Python 3.11，请先安装${NC}"
    echo -e "${YELLOW}安装命令：${NC}"
    echo -e "  sudo add-apt-repository ppa:deadsnakes/ppa"
    echo -e "  sudo apt-get update"
    echo -e "  sudo apt-get install python3.11 python3.11-venv"
    exit 1
fi

# 检查 uv 工具
if ! command -v uv &> /dev/null; then
    echo -e "${RED}错误：需要 uv 包管理器，正在安装...${NC}"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source $HOME/.local/bin/env
fi

# 确保 uv 在 PATH 中
if [ -f "$HOME/.local/bin/env" ]; then
    source $HOME/.local/bin/env
fi

# 检查虚拟环境
if [ ! -d ".venv" ]; then
    echo -e "${YELLOW}虚拟环境不存在，使用 uv 创建并安装依赖...${NC}"
    uv sync --extra cpu
    echo -e "${GREEN}虚拟环境创建完成${NC}"
else
    echo -e "${GREEN}虚拟环境已存在${NC}"
    # 激活虚拟环境
    source .venv/bin/activate

    # 检查关键依赖是否存在
    if ! python -c "import sqlbot_xpack" 2>/dev/null; then
        echo -e "${YELLOW}检测到依赖缺失，重新安装...${NC}"
        uv sync --extra cpu
    fi
fi

# 激活虚拟环境
source .venv/bin/activate

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

    # 检查 node_modules 是否存在
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}G2-SSR 依赖未安装，尝试安装...${NC}"
        npm install 2>&1 | tee ../logs/g2ssr-install.log
        if [ $? -ne 0 ]; then
            echo -e "${RED}G2-SSR 依赖安装失败（可能是 node-canvas 编译问题）${NC}"
            echo -e "${YELLOW}跳过 G2-SSR 服务，核心功能不受影响${NC}"
            cd ..
        else
            if check_port 3000; then
                echo -e "${YELLOW}端口 3000 已被占用，跳过 G2-SSR${NC}"
            else
                echo -e "${GREEN}启动 G2-SSR（端口 3000）...${NC}"
                nohup node app.js > ../logs/g2ssr.log 2>&1 &
                echo $! > ../logs/g2ssr.pid
            fi
            cd ..
        fi
    else
        if check_port 3000; then
            echo -e "${YELLOW}端口 3000 已被占用，跳过 G2-SSR${NC}"
        else
            echo -e "${GREEN}启动 G2-SSR（端口 3000）...${NC}"
            nohup node app.js > ../logs/g2ssr.log 2>&1 &
            echo $! > ../logs/g2ssr.pid
        fi
        cd ..
    fi
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