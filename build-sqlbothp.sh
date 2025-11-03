#!/bin/bash
# SQLBothp Docker 镜像构建脚本
# 支持 GBase 8a 数据库的 SQLBot 版本
#
# 功能：
# - 构建包含 PostgreSQL + GBase 驱动的完整镜像
# - 验证镜像构建成功
# - 可选：导出离线安装包

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
IMAGE_NAME="sqlbothp"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
EXPORT_FILE="sqlbothp-offline.tar"

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 打印标题
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  SQLBothp Docker 镜像构建工具${NC}"
    echo -e "${BLUE}  (支持 GBase 8a 数据库)${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# 检查 Docker 环境
check_docker() {
    print_info "检查 Docker 环境..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        print_error "Docker 服务未运行，请启动 Docker 服务"
        exit 1
    fi

    print_success "Docker 环境检查通过"
    docker --version
}

# 检查必需文件
check_required_files() {
    print_info "检查必需文件..."

    local required_files=(
        "Dockerfile"
        "docker-compose-sqlbothp.yaml"
        "backend/pyproject.toml"
        "frontend/package.json"
        "GBasePython3-9.5.0.1_build4/setup.py"
        "start.sh"
    )

    local missing_files=()

    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ] && [ ! -d "$(dirname "$file")" ]; then
            missing_files+=("$file")
        fi
    done

    if [ ${#missing_files[@]} -ne 0 ]; then
        print_error "以下必需文件缺失："
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        exit 1
    fi

    print_success "所有必需文件检查通过"
}

# 检查 GBase 驱动
check_gbase_driver() {
    print_info "检查 GBase 驱动..."

    if [ ! -d "GBasePython3-9.5.0.1_build4" ]; then
        print_error "GBase 驱动目录不存在：GBasePython3-9.5.0.1_build4"
        exit 1
    fi

    local driver_size=$(du -sh GBasePython3-9.5.0.1_build4 | cut -f1)
    print_success "GBase 驱动检查通过 (大小: ${driver_size})"
}

# 清理旧镜像（可选）
clean_old_images() {
    print_info "清理旧的 ${IMAGE_NAME} 镜像..."

    if docker images | grep -q "^${IMAGE_NAME}"; then
        print_warning "发现旧镜像，是否删除? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            docker rmi -f $(docker images -q ${IMAGE_NAME}) 2>/dev/null || true
            print_success "旧镜像已删除"
        else
            print_info "保留旧镜像"
        fi
    fi
}

# 构建镜像
build_image() {
    print_info "开始构建 Docker 镜像..."
    print_info "镜像名称: ${FULL_IMAGE_NAME}"
    echo ""

    # 显示构建命令
    print_info "执行构建命令："
    echo "docker build -t ${FULL_IMAGE_NAME} ."
    echo ""

    # 开始计时
    local start_time=$(date +%s)

    # 执行构建
    if docker build -t ${FULL_IMAGE_NAME} . ; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local minutes=$((duration / 60))
        local seconds=$((duration % 60))

        print_success "镜像构建成功！"
        print_info "构建耗时: ${minutes}分${seconds}秒"
    else
        print_error "镜像构建失败"
        exit 1
    fi
}

# 验证镜像
verify_image() {
    print_info "验证镜像..."

    if ! docker images | grep -q "^${IMAGE_NAME}.*${IMAGE_TAG}"; then
        print_error "镜像验证失败：未找到构建的镜像"
        exit 1
    fi

    local image_size=$(docker images ${FULL_IMAGE_NAME} --format "{{.Size}}")
    print_success "镜像验证通过"
    print_info "镜像大小: ${image_size}"

    # 显示镜像详细信息
    echo ""
    print_info "镜像详细信息："
    docker images ${FULL_IMAGE_NAME}
}

# 导出镜像（可选）
export_image() {
    echo ""
    print_info "是否导出离线安装包? (y/N)"
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_info "正在导出镜像到 ${EXPORT_FILE}..."

        if docker save ${FULL_IMAGE_NAME} -o ${EXPORT_FILE}; then
            local file_size=$(du -sh ${EXPORT_FILE} | cut -f1)
            print_success "镜像导出成功"
            print_info "文件位置: $(pwd)/${EXPORT_FILE}"
            print_info "文件大小: ${file_size}"
            echo ""
            print_info "导入镜像命令："
            echo "  docker load -i ${EXPORT_FILE}"
        else
            print_error "镜像导出失败"
        fi
    fi
}

# 显示使用说明
show_usage() {
    echo ""
    print_info "========================================"
    print_info "          构建完成！后续步骤"
    print_info "========================================"
    echo ""
    echo "1. 启动服务："
    echo "   docker-compose -f docker-compose-sqlbothp.yaml up -d"
    echo ""
    echo "2. 查看日志："
    echo "   docker-compose -f docker-compose-sqlbothp.yaml logs -f"
    echo ""
    echo "3. 访问系统："
    echo "   http://YOUR_SERVER_IP:8000"
    echo "   默认账号: admin / SQLBot@123456"
    echo ""
    echo "4. 配置 GBase 数据源："
    echo "   登录后在"数据源管理"中添加 GBase 数据源"
    echo ""
    echo "5. 离线部署："
    echo "   参考 OFFLINE_DEPLOYMENT.md 文档"
    echo ""
}

# 主函数
main() {
    print_header

    # 执行检查
    check_docker
    check_required_files
    check_gbase_driver

    # 询问是否清理旧镜像
    clean_old_images

    echo ""
    print_warning "开始构建镜像，此过程可能需要 10-30 分钟..."
    print_warning "请确保网络连接稳定，因为需要下载基础镜像和依赖"
    echo ""
    print_info "按 Enter 继续，或 Ctrl+C 取消..."
    read

    # 构建和验证
    build_image
    verify_image

    # 可选：导出镜像
    export_image

    # 显示使用说明
    show_usage

    print_success "所有操作完成！"
}

# 运行主函数
main
