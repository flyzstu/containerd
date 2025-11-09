#!/bin/bash

# Containerd 多架构构建测试脚本
# 用于本地测试构建过程

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印信息函数
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    print_info "检查构建依赖..."
    
    if ! command -v go &> /dev/null; then
        print_error "Go 未安装"
        exit 1
    fi
    
    if ! command -v make &> /dev/null; then
        print_error "Make 未安装"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        print_error "Git 未安装"
        exit 1
    fi
    
    print_info "依赖检查完成"
}

# 获取版本信息
get_version_info() {
    COMMIT_ID=$(git rev-parse --short HEAD)
    COMMIT_ID_LONG=$(git rev-parse HEAD)
    
    print_info "Commit ID: $COMMIT_ID"
    print_info "Long Commit ID: $COMMIT_ID_LONG"
}

# 构建指定架构
build_arch() {
    local os=$1
    local arch=$2
    local arch_suffix=$3
    
    print_info "开始构建 $os/$arch..."
    
    # 清理之前的构建
    make clean
    
    # 设置环境变量
    export GOOS=$os
    export GOARCH=$arch
    export VERSION=$COMMIT_ID
    export REVISION=$COMMIT_ID_LONG
    export CGO_ENABLED=0
    export GODEBUG=x509ignoreCN=0
    
    # 构建
    if make binaries; then
        # 验证二进制文件
        if [ -f "bin/ctr" ] && [ -f "bin/containerd" ]; then
            print_info "二进制文件构建成功"
            
            # 检查是否为当前架构
            current_goos=$(go env GOOS)
            current_goarch=$(go env GOARCH)
            
            if [[ "$os" == "$current_goos" && "$arch" == "$current_goarch" ]]; then
                print_info "测试当前架构二进制文件..."
                ./bin/ctr --version || print_warning "ctr 版本测试失败"
                ./bin/containerd --version || print_warning "containerd 版本测试失败"
            else
                print_info "跨架构构建，跳过本地执行测试"
            fi
            
            # 创建包
            create_package $arch_suffix
        else
            print_error "构建失败: 二进制文件缺失"
        fi
    else
        print_error "构建命令执行失败"
    fi
    
    print_info "$os/$arch 构建完成"
}

# 创建包
create_package() {
    local arch_suffix=$1
    local package_name="containerd-$COMMIT_ID-linux-$arch_suffix"
    
    print_info "创建包: $package_name"
    
    # 创建目录结构
    mkdir -p "$package_name/bin"
    mkdir -p "$package_name/etc/containerd"
    
    # 复制二进制文件
    cp bin/* "$package_name/bin/"
    
    # 生成默认配置
    ./bin/containerd config default > "$package_name/etc/containerd/config.toml"
    
    # 创建压缩包
    tar -czf "$package_name.tar.gz" "$package_name/"
    
    # 生成校验和
    sha256sum "$package_name.tar.gz" > "$package_name.tar.gz.sha256"
    
    # 显示结果
    ls -la "$package_name"*
    
    # 清理临时目录
    rm -rf "$package_name"
    
    print_info "包创建完成: $package_name.tar.gz"
}

# 主函数
main() {
    print_info "Containerd 多架构构建测试"
    print_info "=================================="
    
    # 检查依赖
    check_dependencies
    
    # 获取版本信息
    get_version_info
    
    # 获取当前架构信息
    current_goos=$(go env GOOS)
    current_goarch=$(go env GOARCH)
    
    print_info "当前系统架构: $current_goos/$current_goarch"
    
    # 构建的架构列表
    architectures=(
        "darwin:arm64:arm64"
    )
    
    # 逐个构建架构
    for arch_info in "${architectures[@]}"; do
        IFS=':' read -r os arch suffix <<< "$arch_info"
        build_arch $os $arch $suffix
    done
    
    print_info "所有架构构建完成!"
    print_info "生成的包:"
    ls -la containerd-*-linux-*.tar.gz
}

# 运行主函数
main "$@"