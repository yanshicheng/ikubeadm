#!/bin/bash
# 脚本功能：下载 ARM 和 AMD 架构镜像并上传到私有仓库，创建多架构清单
# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

DOCKER_COMPOSE=""
ENABLE_DEPLOY_REGISTRY="true"
REGISTRY_DATA_DIR="/tmp/registry/data"
# 使用关联数组定义镜像和其对应的目标子仓库
# 格式: "源镜像"="目标子仓库"
declare -A image_mapping=(
    # Kubernetes 核心组件
    ["registry.aliyuncs.com/google_containers/etcd:3.5.16-0"]="ikubeops"
    ["registry.aliyuncs.com/google_containers/kube-apiserver:v1.32.3"]="ikubeops"
    ["registry.aliyuncs.com/google_containers/kube-controller-manager:v1.32.3"]="ikubeops"
    ["registry.aliyuncs.com/google_containers/kube-scheduler:v1.32.3"]="ikubeops"
    ["registry.aliyuncs.com/google_containers/pause:3.10"]="ikubeops"
    ["registry.aliyuncs.com/google_containers/kube-proxy:v1.32.3"]="ikubeops"
    ["registry.aliyuncs.com/google_containers/coredns:v1.11.3"]="ikubeops"
    ["registry.k8s.io/dns/k8s-dns-node-cache:1.25.0"]="ikubeops"
    # 网络相关
    ["ghcr.io/kube-vip/kube-vip:v0.8.9"]="ikubeops"
    
    # Calico 相关
    ["docker.io/calico/cni:v3.29.3"]="calico"
    ["docker.io/calico/node:v3.29.3"]="calico"
    ["docker.io/calico/typha:v3.29.3"]="calico"
    ["docker.io/calico/kube-controllers:v3.29.3"]="calico"
    
    # 监控相关
    ["registry.k8s.io/metrics-server/metrics-server:v0.7.2"]="ikubeops"
    
    # NFS 存储相关
    ["registry.k8s.io/sig-storage/csi-resizer:v1.13.1"]="nfs-storage"
    ["registry.k8s.io/sig-storage/csi-snapshotter:v8.2.0"]="nfs-storage"
    ["registry.k8s.io/sig-storage/livenessprobe:v2.15.0"]="nfs-storage"
    ["registry.k8s.io/sig-storage/nfsplugin:v4.11.0"]="nfs-storage"
    ["registry.k8s.io/sig-storage/csi-provisioner:v5.2.0"]="nfs-storage"
    ["registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.13.0"]="nfs-storage"
    ["registry.k8s.io/sig-storage/snapshot-controller:v8.2.0"]="nfs-storage"

    # MetalLB 相关
    ["quay.io/metallb/controller:v0.14.9"]="metallb"
    ["quay.io/metallb/speaker:v0.14.9"]="metallb"
    ["quay.io/frrouting/frr:9.1.0"]="metallb"
    # nginx-ingress
    ["registry.k8s.io/ingress-nginx/controller:v1.12.1"]="ingress-nginx"
    ["registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.5.2"]="ingress-nginx"
)

# 从关联数组中获取所有镜像列表
images=("${!image_mapping[@]}")

harbor_registry="registry.ikubeops.local:5000"
platforms=("linux/amd64" "linux/arm64")

export DOCKER_CLI_EXPERIMENTAL=enabled

# 全局计数器
total_images=0
processed_images=0
success_count=0
failed_count=0

# 打印分隔线的函数
print_separator() {
    echo -e "${PURPLE}=====================================================${NC}"
}

# 定义执行命令的函数，出错时会等待3秒再继续
execute_cmd() {
    echo -e "${CYAN}执行命令: $@${NC}"
    output=$("$@" 2>&1)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}[ 错误 ] 命令执行失败:${NC}"
        echo -e "${RED}$output${NC}"
        echo -e "${YELLOW}等待3秒后继续...${NC}"
        sleep 3
        return 1
    else
        echo -e "${GREEN}[ 成功 ]${NC}"
        return 0
    fi
}

# 显示进度的函数
show_progress() {
    echo -e "\n${BOLD}${BLUE}处理进度: $processed_images/$total_images 完成 (成功: ${GREEN}$success_count${BLUE}, 失败: ${RED}$failed_count${BLUE})${NC}\n"
}

# docker 添加环境检查函数
check_docker_environment() {
    echo -e "${BOLD}${BLUE}检查 Docker 环境配置...${NC}"
    print_separator
    
    # 检查 Docker 是否在运行
    echo -e "${BOLD}[1/4] 检查 Docker 服务是否正在运行...${NC}"
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}[错误] Docker 未安装！请先安装 Docker。${NC}"
        exit 1
    fi
    
    if ! systemctl is-active --quiet docker; then
        echo -e "${RED}[错误] Docker 服务未运行！请启动 Docker 服务。${NC}"
        echo -e "${CYAN}您可以使用命令: sudo systemctl start docker${NC}"
        exit 1
    fi
    echo -e "${GREEN}[成功] Docker 服务正在运行。${NC}"
    
    # 检查 registry.ikubeops.local:5000 是否在 daemon.json 中
    echo -e "\n${BOLD}[2/4] 检查 registry.ikubeops.local:5000 是否在 daemon.json 中...${NC}"
    DAEMON_JSON="/etc/docker/daemon.json"
    
    if [ ! -f "$DAEMON_JSON" ]; then
        echo -e "${RED}[错误] daemon.json 文件不存在！需要配置 daemon.json 文件。${NC}"
        exit 1
    fi
    
    if ! grep -q "registry.ikubeops.local:5000" "$DAEMON_JSON"; then
        echo -e "${RED}[错误] registry.ikubeops.local:5000 未在 daemon.json 中配置为不安全仓库！${NC}"
        exit 1
    fi
    echo -e "${GREEN}[成功] registry.ikubeops.local:5000 已在 daemon.json 中正确配置。${NC}"
    
    # 检查 registry.ikubeops.local 是否在 hosts 文件中
    echo -e "\n${BOLD}[3/4] 检查 registry.ikubeops.local 是否在 hosts 文件中...${NC}"
    HOSTS_FILE="/etc/hosts"
    
    if ! grep -q "registry.ikubeops.local" "$HOSTS_FILE"; then
        echo -e "${CYAN}例如: 127.0.0.1 registry.ikubeops.local${NC}"
        exit 1
    fi
    echo -e "${GREEN}[成功] registry.ikubeops.local 已在 hosts 文件中配置。${NC}"
    
    # 检查 Docker Compose 是否可用
    echo -e "\n${BOLD}[4/4] 检查 Docker Compose 是否可用...${NC}"
    
    # 检查新版 Docker Compose (docker compose)
    if docker compose version &> /dev/null; then
        DOCKER_COMPOSE_VERSION=$(docker compose version --short)
        DOCKER_COMPOSE="docker compose"
        echo -e "${GREEN}[成功] Docker Compose 已安装 (新版, $DOCKER_COMPOSE_VERSION)。${NC}"
    # 检查旧版 Docker Compose (docker-compose)
    elif command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE_VERSION=$(docker-compose version --short)
        echo -e "${GREEN}[成功] Docker Compose 已安装 (旧版, $DOCKER_COMPOSE_VERSION)。${NC}"
        DOCKER_COMPOSE="docker-compose"
    else
        echo -e "${RED}[错误] Docker Compose 未安装或不可用！${NC}"
        echo -e "${CYAN}请安装 Docker Compose，可以使用以下命令安装最新版：${NC}"
        exit 1
    fi
    
    # 检查 Docker Manifest 功能是否可用
    echo -e "\n${BOLD}[额外检查] 检查 Docker Manifest 功能是否可用...${NC}"
    if ! docker manifest inspect --help &> /dev/null; then
        echo -e "${RED}[错误] Docker Manifest 功能不可用！${NC}"
        echo -e "${CYAN}请确保 Docker 版本足够新，并且已设置 DOCKER_CLI_EXPERIMENTAL=enabled${NC}"
        exit 1
    fi
    echo -e "${GREEN}[成功] Docker Manifest 功能可用。${NC}"
    
    print_separator
    echo -e "${GREEN}${BOLD}✅ Docker 环境检查通过！${NC}"
    print_separator
}

# 部署私有镜像仓库
deploy_registry() {
    print_separator
    echo -e "${BOLD}${BLUE}部署私有镜像仓库...${NC}"
    
    if [ "$ENABLE_DEPLOY_REGISTRY" != "true" ]; then
        echo -e "${YELLOW}DEPLOY_REGISTRY 未设置为 true，跳过私有仓库部署${NC}"
        return 0
    fi
    
    # 判断系统架构并加载对应的镜像
    local arch=$(uname -m)
    local image_file=""
    
    if [ "$arch" = "x86_64" ]; then
        echo -e "${CYAN}检测到 AMD64 架构${NC}"
        image_file="images/registry-amd64.tar.gz"
    elif [ "$arch" = "aarch64" ]; then
        echo -e "${CYAN}检测到 ARM64 架构${NC}"
        image_file="images/registry-arm64.tar.gz"
    else
        echo -e "${RED}不支持的系统架构: $arch${NC}"
        return 1
    fi
    
    # 检查镜像文件是否存在
    if [ ! -f "$image_file" ]; then
        echo -e "${RED}镜像文件不存在: $image_file${NC}"
        return 1
    fi
    
    # 加载 registry 镜像
    echo -e "${CYAN}正在加载 Registry 镜像...${NC}"
    if ! execute_cmd docker load -i "$image_file"; then
        echo -e "${RED}加载 Registry 镜像失败${NC}"
        return 1
    fi
    
    # 创建 registry 数据目录
    echo -e "${CYAN}创建 Registry 数据目录...${NC}"
    if ! execute_cmd mkdir -p "$REGISTRY_DATA_DIR"; then
        echo -e "${RED}创建 Registry 数据目录失败${NC}"
        return 1
    fi
    
    # 创建 docker-compose 配置目录
    echo -e "${CYAN}创建 docker-compose 配置目录...${NC}"
    if ! execute_cmd mkdir -p "/opt/docker-compose/registry"; then
        echo -e "${RED}创建 docker-compose 配置目录失败${NC}"
        return 1
    fi
    
    # 创建 docker-compose.yml 文件
    echo -e "${CYAN}创建 docker-compose.yml 文件...${NC}"
    cat > /opt/docker-compose/registry/docker-compose.yml << EOF
version: '3.8'

services:
  registry:
    image: registry:2
    container_name: ikube-registry
    hostname: ikube-registry
    ports:
      - "5000:5000"
    volumes:
      - REGISTRY_DATA_DIR:/var/lib/registry
    restart: always
EOF
    echo -e "${CYAN}替换配置文件中的环境变量...${NC}"
    sed -i "s|REGISTRY_DATA_DIR|$REGISTRY_DATA_DIR|g" /opt/docker-compose/registry/docker-compose.yml  & >/dev/null
    # 切换到 docker-compose 目录
    cd /opt/docker-compose/registry
    
    # 停止现有的 registry 容器
    echo -e "${CYAN}停止现有的 Registry 容器...${NC}"
    $DOCKER_COMPOSE down
    
    # 启动 registry 容器
    echo -e "${CYAN}启动 Registry 容器...${NC}"
    if ! execute_cmd  $DOCKER_COMPOSE up -d; then
        echo -e "${RED}启动 Registry 容器失败${NC}"
        return 1
    fi
    
    # 等待 registry 启动
    echo -e "${CYAN}等待 Registry 服务启动 (5秒)...${NC}"
    sleep 5
    
    # 检查 registry 是否正常运行
    echo -e "${CYAN}检查 Registry 服务是否正常...${NC}"
    if curl -s http://registry.ikubeops.local:5000/v2/_catalog > /dev/null; then
        echo -e "${GREEN}${BOLD}✅ Registry 服务已成功部署并正常运行!${NC}"
        return 0
    else
        echo -e "${RED}Registry 服务检查失败，请检查日志!${NC}"
        return 1
    fi
}

# 处理单个平台的镜像
process_platform() {
    local image=$1
    local new_image=$2
    local platform=$3
    local current_index=$4
    
    local arch=$(echo "$platform" | cut -d'/' -f2)
    local platform_tag="$new_image-$arch"
    
    echo -e "\n${BOLD}${YELLOW}[$current_index/$total_images] ${arch}架构处理开始${NC}"
    
    echo -e "\n${BOLD}[1/3] ${arch}架构拉取${NC}"
    if ! execute_cmd docker pull --platform $platform $image; then
        return 1
    fi
    
    echo -e "\n${BOLD}[2/3] ${arch}架构标记${NC}"
    if ! execute_cmd docker tag $image $platform_tag; then
        return 1
    fi
    
    echo -e "\n${BOLD}[3/3] ${arch}架构推送${NC}"
    if ! execute_cmd docker push $platform_tag; then
        return 1
    fi
    
    echo -e "${GREEN}${BOLD}${arch}架构处理完成${NC}"
    return 0
}

# 创建并推送多架构清单
create_manifest() {
    local new_image=$1
    local current_index=$2
    local successful=true
    
    echo -e "\n${BOLD}${YELLOW}[$current_index/$total_images] 创建多架构清单步骤${NC}"
    
    # 构建清单创建命令参数
    local manifest_args="create --amend $new_image"
    for platform in "${platforms[@]}"; do
        local arch=$(echo "$platform" | cut -d'/' -f2)
        manifest_args="$manifest_args $new_image-$arch"
    done
    
    echo -e "${BOLD}创建清单${NC}"
    if ! execute_cmd docker manifest $manifest_args --insecure; then
        return 1
    fi
    
    # 为每个平台添加架构信息
    for platform in "${platforms[@]}"; do
        local arch=$(echo "$platform" | cut -d'/' -f2)
        echo -e "${BOLD}添加${arch}架构注释${NC}"
        if ! execute_cmd docker manifest annotate $new_image $new_image-$arch --os linux --arch $arch; then
            return 1
        fi
    done
    
    echo -e "${BOLD}推送清单${NC}"
    if ! execute_cmd docker manifest push $new_image --insecure; then
        return 1
    fi
    
    return 0
}

# 处理单个镜像
process_single_image() {
    local image=$1
    local current_index=$2
    local image_success=true
    
    # 提取镜像名和标签信息
    local image_name_with_path=$(echo "$image" | awk -F':' '{print $1}')
    local image_tag=$(echo "$image" | awk -F':' '{print $2}')
    local image_name=$(echo "$image_name_with_path" | awk -F'/' '{print $NF}')
    
    # 获取镜像对应的子仓库
    local subdirectory="${image_mapping[$image]}"
    local new_image="$harbor_registry/$subdirectory/$image_name:$image_tag"
    
    print_separator
    echo -e "${BOLD}${CYAN}[$current_index/$total_images] 处理镜像: $image${NC}"
    echo -e "${BOLD}${CYAN}目标仓库: $new_image${NC}"
    print_separator
    
    # 为每个平台拉取、标记、推送
    for platform in "${platforms[@]}"; do
        if ! process_platform "$image" "$new_image" "$platform" "$current_index"; then
            image_success=false
        fi
    done
    
    if [ "$image_success" = false ]; then
        echo -e "${RED}${BOLD}镜像处理过程中出现错误，跳过多架构清单创建${NC}"
        failed_count=$((failed_count + 1))
        return 1
    fi
    
    # 创建多架构清单
    if ! create_manifest "$new_image" "$current_index"; then
        image_success=false
    fi
    
    # 清理本地镜像 (注释掉的部分保持不变)
    #echo -e "\n${BOLD}${YELLOW}[$current_index/$total_images] 清理本地镜像${NC}"
    #for platform in "${platforms[@]}"; do
    #    arch=$(echo "$platform" | cut -d'/' -f2)
    #    echo -e "${BOLD}删除${arch}架构镜像${NC}"
    #    execute_cmd docker rmi $new_image-$arch
    #done
    
    #echo -e "${BOLD}删除原始镜像${NC}"
    #execute_cmd docker rmi $image
    
    if [ "$image_success" = true ]; then
        success_count=$((success_count + 1))
        echo -e "\n${GREEN}${BOLD}[$current_index/$total_images] 镜像 $image 处理成功!${NC}"
        return 0
    else
        failed_count=$((failed_count + 1))
        echo -e "\n${RED}${BOLD}[$current_index/$total_images] 镜像 $image 处理失败!${NC}"
        return 1
    fi
}

# 处理所有镜像
process_images() {
    total_images=${#images[@]}
    processed_images=0
    success_count=0
    failed_count=0
    
    print_separator
    echo -e "${BOLD}${BLUE}开始处理 $total_images 个镜像${NC}"
    print_separator
    
    # 循环处理每个镜像
    for image in "${images[@]}"; do
        processed_images=$((processed_images + 1))
        process_single_image "$image" "$processed_images"
        
        print_separator
        show_progress
    done
    
    display_summary
}

# 显示处理摘要
display_summary() {
    print_separator
    echo -e "${BOLD}${BLUE}处理完成摘要:${NC}"
    echo -e "${BOLD}总共处理: $total_images 个镜像${NC}"
    echo -e "${BOLD}${GREEN}成功处理: $success_count 个镜像${NC}"
    echo -e "${BOLD}${RED}失败处理: $failed_count 个镜像${NC}"
    print_separator
    
    if [ $failed_count -eq 0 ]; then
        echo -e "${BOLD}${GREEN}✅ 所有镜像处理成功!${NC}"
    else
        echo -e "${BOLD}${YELLOW}⚠️ 部分镜像处理失败，请检查日志!${NC}"
    fi
}

# 主函数
main() {
    # 检查 Docker 环境
    check_docker_environment
    
    # 部署私有镜像仓库
    deploy_registry
    
    # 处理镜像
    process_images
}

# 调用主函数
main