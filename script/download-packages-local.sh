#!/bin/bash
set -e
set -euo pipefail
trap 'echo "错误发生在第 $LINENO 行。退出脚本。"; exit 1' ERR
# 注意脚本的执行位置
BASE_DIR="packages/"
##### 科学地址
export http_proxy="http://127.0.0.1:7890"
export https_proxy="http://127.0.0.1:7890"
export all_proxy="socks://127.0.0.1:7890"
export no_proxy="localhost,127.0.0.1,local.domain"

declare -a CRI_DOCKER_VERSIONS=("v0.3.17" "v0.3.16")
# 定义要下载的 Kubernetes 版本
declare -a KUBE_VERSIONS=("v1.32.2" "v1.32.3")
# 定义要下载的 Docker 版本
declare -a DOCKER_VERSIONS=("28.1.1" "27.5.1")
# 定义要下载的 CFSSL 版本
declare -a CFSSL_VERSIONS=("v1.6.5" "v1.6.4")
# 定义要下载的 containerd 版本
declare -a CONTAINERD_VERSIONS=("v2.0.5" "v2.0.4" "v1.7.27")
# 定义要下载的 runc 版本
declare -a RUNC_VERSIONS=("v1.2.5" "v1.2.6")
# 定义要下载的 CNI 插件版本
declare -a CNI_PLUGINS_VERSIONS=("v1.6.2" "v1.5.1")
# 定义要下载的 nerdctl 版本
declare -a NERDCTL_VERSIONS=("v2.0.4" "v2.0.3")
# 定义要下载的 crictl 版本
declare -a CRICTL_VERSIONS=("v1.32.0" "v1.31.1")
# 定义要下载的 buildkit 版本
declare -a BUILDKIT_VERSIONS=("v0.21.0" "v0.20.2")
# 定义要下载的 calicoctl 版本
declare -a CALICO_VERSIONS=("v3.29.3" "v3.28.3")
# 定义要下载的 helm 版本
declare -a HELM_VERSIONS=("v3.17.3" "v3.17.1")
# 定义要下载的 cilium 版本
declare -a CILIUM_VERSIONS=("v0.18.3" "v0.18.2")

# 初始化错误计数
ERROR_COUNT=0

# 需要下载的 Kubernetes 组件
KUBE_COMPONENTS=(
    "kubectl"
    "kube-proxy"
    "kube-scheduler"
    "kubelet"
    "kube-apiserver"
    "kube-controller-manager"
)


# 部署私有镜像仓库
deploy_registry() {
    print_separator
    echo -e "${BOLD}${BLUE}部署私有镜像仓库...${NC}"
    
    if [ "$DEPLOY_REGISTRY" != "true" ]; then
        echo -e "${YELLOW}DEPLOY_REGISTRY 未设置为 true，跳过私有仓库部署${NC}"
        return 0
    fi
    
    # 判断系统架构并加载对应的镜像
    local arch=$(uname -m)
    local image_file=""
    
    if [ "$arch" = "x86_64" ]; then
        echo -e "${CYAN}检测到 AMD64 架构${NC}"
        image_file="image/registry-amd64.tar.gz"
    elif [ "$arch" = "aarch64" ]; then
        echo -e "${CYAN}检测到 ARM64 架构${NC}"
        image_file="image/registry-arm64.tar.gz"
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
    REGISTRY_LOCAL_DIR="/opt/registry/data"
    if ! execute_cmd mkdir -p "$REGISTRY_LOCAL_DIR"; then
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
      - \${REGISTRY_LOCAL_DIR}:/var/lib/registry
    restart: always
EOF
    
    # 切换到 docker-compose 目录
    cd /opt/docker-compose/registry
    
    # 停止现有的 registry 容器
    echo -e "${CYAN}停止现有的 Registry 容器...${NC}"
    REGISTRY_LOCAL_DIR=$REGISTRY_LOCAL_DIR $DOCKER_COMPOSE down
    
    # 启动 registry 容器
    echo -e "${CYAN}启动 Registry 容器...${NC}"
    if ! execute_cmd REGISTRY_LOCAL_DIR=$REGISTRY_LOCAL_DIR $DOCKER_COMPOSE up -d; then
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


# 下载 Kubernetes 组件的函数
download_kubernetes_version() {
    local version=$1
    echo "======================================================"
    echo "开始下载 Kubernetes ${version} 二进制文件"
    echo "======================================================"
    
    # 下载 amd64 和 arm64 架构组件
    for arch in "amd64" "arm64"; do
        echo "** 下载 ${arch} 架构组件 **"
        
        # 创建目标目录
        local target_dir="${BASE_DIR}/kubernetes/${version}/${arch}"
        mkdir -p "${target_dir}"
        
        # 下载每个组件
        for component in "${KUBE_COMPONENTS[@]}"; do
            local download_url="https://dl.k8s.io/${version}/bin/linux/${arch}/${component}"
            local output_file="${target_dir}/${component}"
            
            echo "正在下载 ${component} (${arch}) 版本 ${version}..."
            wget -q --show-progress "${download_url}" -O "${output_file}" || {
                echo "× 下载失败 ${component} (${arch}) 版本 ${version}"
                rm -f "${output_file}"
                ((ERROR_COUNT++))
                continue
            }
            
            chmod +x "${output_file}"
            echo "√ 成功下载 ${component} (${arch}) 版本 ${version}"
        done
    done
    
    echo "======================================================"
    echo "Kubernetes ${version} 下载完成"
    echo "======================================================"
}

# 下载 CFSSL 工具的函数
download_cfssl_version() {
    local version=$1
    echo "======================================================"
    echo "开始下载 CFSSL ${version} 二进制文件"
    echo "======================================================"
    
    # 下载 amd64 和 arm64 架构
    for arch in "amd64" "arm64"; do
        echo "** 下载 ${arch} 架构组件 **"
        
        # 创建目标目录
        local target_dir="${BASE_DIR}/bin/cfssl/${version}/${arch}"
        mkdir -p "${target_dir}"
        
        # 下载 cfssl
        if [ "${arch}" == "amd64" ]; then
            local cfssl_url="https://github.com/cloudflare/cfssl/releases/download/${version}/cfssl_${version#v}_linux_amd64"
        else
            local cfssl_url="https://github.com/cloudflare/cfssl/releases/download/${version}/cfssl_${version#v}_linux_arm64"
        fi
        local cfssl_output="${target_dir}/cfssl"
        
        echo "正在下载 cfssl ${version} (${arch})..."
        wget -q --show-progress "${cfssl_url}" -O "${cfssl_output}" || {
            echo "× 下载失败 cfssl ${version} (${arch})"
            rm -f "${cfssl_output}"
            ((ERROR_COUNT++))
            continue
        }
        
        chmod +x "${cfssl_output}"
        echo "√ 成功下载 cfssl ${version} (${arch})"
        
        # 下载 cfssl-certinfo
        if [ "${arch}" == "amd64" ]; then
            local certinfo_url="https://github.com/cloudflare/cfssl/releases/download/${version}/cfssl-certinfo_${version#v}_linux_amd64"
        else
            local certinfo_url="https://github.com/cloudflare/cfssl/releases/download/${version}/cfssl-certinfo_${version#v}_linux_arm64"
        fi
        local certinfo_output="${target_dir}/cfssl-certinfo"
        
        echo "正在下载 cfssl-certinfo ${version} (${arch})..."
        wget -q --show-progress "${certinfo_url}" -O "${certinfo_output}" || {
            echo "× 下载失败 cfssl-certinfo ${version} (${arch})"
            rm -f "${certinfo_output}"
            ((ERROR_COUNT++))
            continue
        }
        
        chmod +x "${certinfo_output}"
        echo "√ 成功下载 cfssl-certinfo ${version} (${arch})"
        
        # 下载 cfssljson
        if [ "${arch}" == "amd64" ]; then
            local cfssljson_url="https://github.com/cloudflare/cfssl/releases/download/${version}/cfssljson_${version#v}_linux_amd64"
        else
            local cfssljson_url="https://github.com/cloudflare/cfssl/releases/download/${version}/cfssljson_${version#v}_linux_arm64"
        fi
        local cfssljson_output="${target_dir}/cfssljson"
        
        echo "正在下载 cfssljson ${version} (${arch})..."
        wget -q --show-progress "${cfssljson_url}" -O "${cfssljson_output}" || {
            echo "× 下载失败 cfssljson ${version} (${arch})"
            rm -f "${cfssljson_output}"
            ((ERROR_COUNT++))
            continue
        }
        
        chmod +x "${cfssljson_output}"
        echo "√ 成功下载 cfssljson ${version} (${arch})"
    done
    
    echo "======================================================"
    echo "CFSSL ${version} 下载完成"
    echo "======================================================"
}
# 下载 Docker 的函数
download_docker_version() {
    local version=$1
    echo "======================================================"
    echo "开始下载 Docker ${version} 二进制文件"
    echo "======================================================"
    
    for arch in "amd64" "arm64"; do
        echo "** 下载 ${arch} 架构组件 **"
        case "$arch" in
            "amd64") url_arch="x86_64" ;;
            "arm64") url_arch="aarch64" ;;
            *) url_arch="$arch" ;;
        esac
        # 创建目标目录
        local target_dir="${BASE_DIR}/runtime/docker/${version}/${arch}"
        mkdir -p "${target_dir}"
        
        # Docker 下载 URL
        local download_url="https://download.docker.com/linux/static/stable/${url_arch}/docker-${version}.tgz"
        local output_file="${target_dir}/docker-${version}.tgz"
        
        echo "正在下载 Docker ${version} (${arch})..."
        wget -q --show-progress "${download_url}" -O "${output_file}" || {
            echo "× 下载失败 Docker ${version} (${arch})"
            rm -f "${output_file}"
            ((ERROR_COUNT++))
            continue
        }
        
        echo "√ 成功下载 Docker ${version} (${arch})"
    done
    
    echo "======================================================"
    echo "Docker ${version} 下载完成"
    echo "======================================================"
}
# 下载 Docker 的函数
download_cri_docker_version() {
    local version=$1
    echo "======================================================"
    echo "开始下载 CRI-Docker ${version} 二进制文件"
    echo "======================================================"
    
    for arch in "amd64" "arm64"; do
        echo "** 下载 ${arch} 架构组件 **"
        # 创建目标目录
        local target_dir="${BASE_DIR}/runtime/cri-docker/${version}/${arch}"
        mkdir -p "${target_dir}"
        # Docker 下载 URL
        download_version=$(echo "$version" | sed 's/^v//')
        local download_url="https://github.com/Mirantis/cri-dockerd/releases/download/${version}/cri-dockerd-${download_version}.$arch.tgz"
        local output_file="${target_dir}/cri-dockerd-${download_version}.$arch.tgz"
        echo "下载地址：${download_url}"
        echo "正在下载 CRI Docker ${version} (${arch})..."
        wget -q --show-progress "${download_url}" -O "${output_file}" || {
            echo "× 下载失败 CRI Docker ${version} (${arch})"
            rm -f "${output_file}"
            ((ERROR_COUNT++))
            continue
        }
        
        echo "√ 成功下载 Docker ${version} (${arch})"
    done
    
    echo "======================================================"
    echo "Docker ${version} 下载完成"
    echo "======================================================"
}
# 下载 Containerd 的函数
download_containerd_version() {
    local version=$1
    echo "======================================================"
    echo "开始下载 Containerd ${version} 二进制文件"
    echo "======================================================"
    
    # 下载 amd64 和 arm64 架构
    for arch in "amd64" "arm64"; do
        echo "** 下载 ${arch} 架构组件 **"
        
        # 创建目标目录
        local target_dir="${BASE_DIR}/runtime/containerd"
        mkdir -p "${target_dir}"
        
        # Containerd 下载 URL
        local download_url="https://github.com/containerd/containerd/releases/download/${version}/containerd-${version#v}-linux-${arch}.tar.gz"
        local output_file="${target_dir}/containerd-${version#v}-linux-${arch}.tar.gz"
        
        echo "正在下载 Containerd ${version} (${arch})..."
        wget -q --show-progress "${download_url}" -O "${output_file}" || {
            echo "× 下载失败 Containerd ${version} (${arch})"
            rm -f "${output_file}"
            ((ERROR_COUNT++))
            continue
        }
        
        echo "√ 成功下载 Containerd ${version} (${arch})"
    done
    
    echo "======================================================"
    echo "Containerd ${version} 下载完成"
    echo "======================================================"
}

# 下载 Runc 的函数
download_runc_version() {
    local version=$1
    echo "======================================================"
    echo "开始下载 Runc ${version} 二进制文件"
    echo "======================================================"
    
    # 下载 amd64 和 arm64 架构
    for arch in "amd64" "arm64"; do
        echo "** 下载 ${arch} 架构组件 **"
        
        # 创建目标目录
        local target_dir="${BASE_DIR}/runtime/runc/${version}"
        mkdir -p "${target_dir}"
        
        # Runc 下载 URL
        local download_url="https://github.com/opencontainers/runc/releases/download/${version}/runc.${arch}"
        local output_file="${target_dir}/runc.${arch}"
        
        echo "正在下载 Runc ${version} (${arch})..."
        wget -q --show-progress "${download_url}" -O "${output_file}" || {
            echo "× 下载失败 Runc ${version} (${arch})"
            rm -f "${output_file}"
            ((ERROR_COUNT++))
            continue
        }
        
        chmod +x "${output_file}"
        echo "√ 成功下载 Runc ${version} (${arch})"
    done
    
    echo "======================================================"
    echo "Runc ${version} 下载完成"
    echo "======================================================"
}

# 下载 CNI Plugins 的函数
download_cni_plugins_version() {
    local version=$1
    echo "======================================================"
    echo "开始下载 CNI Plugins ${version} 二进制文件"
    echo "======================================================"
    
    # 下载 amd64 和 arm64 架构
    for arch in "amd64" "arm64"; do
        echo "** 下载 ${arch} 架构组件 **"
        
        # 创建目标目录
        local target_dir="${BASE_DIR}/runtime/cni-plugins"
        mkdir -p "${target_dir}"
        
        # CNI Plugins 下载 URL
        local download_url="https://github.com/containernetworking/plugins/releases/download/${version}/cni-plugins-linux-${arch}-${version}.tgz"
        local output_file="${target_dir}/cni-plugins-linux-${arch}-${version}.tgz"
        
        echo "正在下载 CNI Plugins ${version} (${arch})..."
        wget -q --show-progress "${download_url}" -O "${output_file}" || {
            echo "× 下载失败 CNI Plugins ${version} (${arch})"
            rm -f "${output_file}"
            ((ERROR_COUNT++))
            continue
        }
        
        echo "√ 成功下载 CNI Plugins ${version} (${arch})"
    done
    
    echo "======================================================"
    echo "CNI Plugins ${version} 下载完成"
    echo "======================================================"
}


# 下载 nerdctl 的函数
download_nerdctl_version() {
    local version=$1
    echo "======================================================"
    echo "开始下载 nerdctl ${version} 二进制文件"
    echo "======================================================"
    
    # 下载 amd64 和 arm64 架构
    for arch in "amd64" "arm64"; do
        echo "** 下载 ${arch} 架构组件 **"
        
        # 创建目标目录
        local target_dir="${BASE_DIR}/runtime/nerdctl"
        mkdir -p "${target_dir}"
        
        # nerdctl 下载 URL
        local download_url="https://github.com/containerd/nerdctl/releases/download/${version}/nerdctl-${version#v}-linux-${arch}.tar.gz"
        local output_file="${target_dir}/nerdctl-${version#v}-linux-${arch}.tar.gz"
        
        echo "正在下载 nerdctl ${version} (${arch})..."
        wget -q --show-progress "${download_url}" -O "${output_file}" || {
            echo "× 下载失败 nerdctl ${version} (${arch})"
            rm -f "${output_file}"
            ((ERROR_COUNT++))
            continue
        }
        
        echo "√ 成功下载 nerdctl ${version} (${arch})"
    done
    
    echo "======================================================"
    echo "nerdctl ${version} 下载完成"
    echo "======================================================"
}


# 下载 crictl 的函数
download_crictl_version() {
    local version=$1
    echo "======================================================"
    echo "开始下载 crictl ${version} 二进制文件"
    echo "======================================================"
    
    # 下载 amd64 和 arm64 架构
    for arch in "amd64" "arm64"; do
        echo "** 下载 ${arch} 架构组件 **"
        
        # 创建目标目录
        local target_dir="${BASE_DIR}/runtime/crictl"
        mkdir -p "${target_dir}"
        
        # crictl 下载 URL
        local download_url="https://github.com/kubernetes-sigs/cri-tools/releases/download/${version}/crictl-${version}-linux-${arch}.tar.gz"
        local output_file="${target_dir}/crictl-${version}-linux-${arch}.tar.gz"
        
        echo "正在下载 crictl ${version} (${arch})..."
        wget -q --show-progress "${download_url}" -O "${output_file}" || {
            echo "× 下载失败 crictl ${version} (${arch})"
            rm -f "${output_file}"
            ((ERROR_COUNT++))
            continue
        }
        
        echo "√ 成功下载 crictl ${version} (${arch})"
    done
    
    echo "======================================================"
    echo "crictl ${version} 下载完成"
    echo "======================================================"
}

# 下载 buildkit 的函数
download_buildkit_version() {
    local version=$1
    echo "======================================================"
    echo "开始下载 buildkit ${version} 二进制文件"
    echo "======================================================"
    
    # 下载 amd64 和 arm64 架构
    for arch in "amd64" "arm64"; do
        echo "** 下载 ${arch} 架构组件 **"
        
        # 创建目标目录
        local target_dir="${BASE_DIR}/runtime/buildkit"
        mkdir -p "${target_dir}"
        
        # buildkit 下载 URL
        local download_url="https://github.com/moby/buildkit/releases/download/${version}/buildkit-${version}.linux-${arch}.tar.gz"
        local output_file="${target_dir}/buildkit-${version}.linux-${arch}.tar.gz"
        
        echo "正在下载 buildkit ${version} (${arch})..."
        wget -q --show-progress "${download_url}" -O "${output_file}" || {
            echo "× 下载失败 buildkit ${version} (${arch})"
            rm -f "${output_file}"
            ((ERROR_COUNT++))
            continue
        }
        
        echo "√ 成功下载 buildkit ${version} (${arch})"
    done
    
    echo "======================================================"
    echo "buildkit ${version} 下载完成"
    echo "======================================================"
}

# 下载 calico 的函数
download_calico_version() {
    local version=$1
    echo "======================================================"
    echo "开始下载 calicoctl ${version} 二进制文件"
    echo "======================================================"
    
    # 下载 amd64 和 arm64 架构
    for arch in "amd64" "arm64"; do
        echo "** 下载 ${arch} 架构组件 **"
        
        # 创建目标目录
        local target_dir="${BASE_DIR}/cni/calico/${version}/${arch}"
        mkdir -p "${target_dir}"
        
        # calicoctl 下载 URL
        local download_url="https://github.com/projectcalico/calico/releases/download/${version}/calicoctl-linux-${arch}"
        local output_file="${target_dir}/calicoctl"
        
        echo "正在下载 calicoctl ${version} (${arch})..."
        wget -q --show-progress "${download_url}" -O "${output_file}" || {
            echo "× 下载失败 calicoctl ${version} (${arch})"
            rm -f "${output_file}"
            ((ERROR_COUNT++))
            continue
        }
        
        chmod +x "${output_file}"
        echo "√ 成功下载 calicoctl ${version} (${arch})"
    done
    
    echo "======================================================"
    echo "calicoctl ${version} 下载完成"
    echo "======================================================"
}

# 下载 helm 的函数
download_helm_version() {
    local version=$1
    echo "======================================================"
    echo "开始下载 helm ${version} 二进制文件"
    echo "======================================================"
    
    # 下载 amd64 和 arm64 架构
    for arch in "amd64" "arm64"; do
        echo "** 下载 ${arch} 架构组件 **"
        
        # 创建目标目录
        local target_dir="${BASE_DIR}/helm/${version}/${arch}"
        mkdir -p "${target_dir}"
        
        # helm 下载 URL
        local download_url="https://get.helm.sh/helm-${version}-linux-${arch}.tar.gz"
        local output_file="${target_dir}/helm-${version}-linux-${arch}.tar.gz"
        local extract_dir="${target_dir}/tmp"
        
        echo "正在下载 helm ${version} (${arch})..."
        wget -q --show-progress "${download_url}" -O "${output_file}" || {
            echo "× 下载失败 helm ${version} (${arch})"
            rm -f "${output_file}"
            ((ERROR_COUNT++))
            continue
        }
        
        echo "正在解压 helm ${version} (${arch})..."
        mkdir -p "${extract_dir}"
        tar -xzf "${output_file}" -C "${extract_dir}" || {
            echo "× 解压失败 helm ${version} (${arch})"
            rm -rf "${extract_dir}"
            ((ERROR_COUNT++))
            continue
        }
        
        mv "${extract_dir}/linux-${arch}/helm" "${target_dir}/helm" || {
            echo "× 移动文件失败 helm ${version} (${arch})"
            rm -rf "${extract_dir}"
            ((ERROR_COUNT++))
            continue
        }
        
        chmod +x "${target_dir}/helm"
        rm -rf "${extract_dir}"
        echo "√ 成功下载并解压 helm ${version} (${arch})"
    done
    
    echo "======================================================"
    echo "helm ${version} 下载完成"
    echo "======================================================"
}

# 下载 cilium 的函数
download_cilium_version() {
    local version=$1
    echo "======================================================"
    echo "开始下载 cilium ${version} 二进制文件"
    echo "======================================================"
    
    # 下载 amd64 和 arm64 架构
    for arch in "amd64" "arm64"; do
        echo "** 下载 ${arch} 架构组件 **"
        
        # 创建目标目录
        local target_dir="${BASE_DIR}/cni/cilium/${version}/${arch}"
        mkdir -p "${target_dir}"
        
        # cilium 下载 URL
        local download_url="https://github.com/cilium/cilium-cli/releases/download/${version}/cilium-linux-${arch}.tar.gz"
        local output_file="${target_dir}/cilium-linux-${arch}.tar.gz"
        local extract_dir="${target_dir}/tmp"
        
        echo "正在下载 cilium ${version} (${arch})..."
        wget -q --show-progress "${download_url}" -O "${output_file}" || {
            echo "× 下载失败 cilium ${version} (${arch})"
            rm -f "${output_file}"
            ((ERROR_COUNT++))
            continue
        }
        
        echo "正在解压 cilium ${version} (${arch})..."
        mkdir -p "${extract_dir}"
        tar -xzf "${output_file}" -C "${extract_dir}" || {
            echo "× 解压失败 cilium ${version} (${arch})"
            rm -rf "${extract_dir}"
            ((ERROR_COUNT++))
            continue
        }
        
        mv "${extract_dir}/cilium" "${target_dir}/cilium" || {
            echo "× 移动文件失败 cilium ${version} (${arch})"
            rm -rf "${extract_dir}"
            ((ERROR_COUNT++))
            continue
        }
        
        chmod +x "${target_dir}/cilium"
        rm -rf "${extract_dir}"
        echo "√ 成功下载并解压 cilium ${version} (${arch})"
    done
    
    echo "======================================================"
    echo "cilium ${version} 下载完成"
    echo "======================================================"
}

# 主函数
main() {
    echo "开始下载所有组件..."
    
    # 创建基础目录
    mkdir -p "${BASE_DIR}"
    
    set +e
    
    # 下载所有定义的 CFSSL 版本
    for version in "${CFSSL_VERSIONS[@]}"; do
        download_cfssl_version "${version}"
    done

    # 下载所有定义的 Kubernetes 版本
    for version in "${KUBE_VERSIONS[@]}"; do
        download_kubernetes_version "${version}"
    done

    # 下载 docker 
    for version in "${DOCKER_VERSIONS[@]}"; do
        download_docker_version "${version}"
    done
    # 下载 cri-docker
    for version in "${CRI_DOCKER_VERSIONS[@]}"; do
        download_cri_docker_version "${version}"
    done
    下载 containerd 
    for version in "${CONTAINERD_VERSIONS[@]}"; do
        download_containerd_version "${version}"
    done

    # 下载 runc 
    for version in "${RUNC_VERSIONS[@]}"; do
        download_runc_version "${version}"
    done
    
    # 下载 cni 
    for version in "${CNI_PLUGINS_VERSIONS[@]}"; do
        download_cni_plugins_version "${version}"
    done
    
    # 下载所有 nerdctl 版本
    for version in "${NERDCTL_VERSIONS[@]}"; do
        download_nerdctl_version "${version}"
    done
    
    # 下载所有 crictl 版本
    for version in "${CRICTL_VERSIONS[@]}"; do
        download_crictl_version "${version}"
    done
    
    # 下载所有 buildkit 版本
    for version in "${BUILDKIT_VERSIONS[@]}"; do
        download_buildkit_version "${version}"
    done
    
    # 下载所有 calico 版本
    for version in "${CALICO_VERSIONS[@]}"; do
        download_calico_version "${version}"
    done
    
    # 下载所有 helm 版本
    for version in "${HELM_VERSIONS[@]}"; do
        download_helm_version "${version}"
    done
    
    # 下载所有 cilium 版本
    for version in "${CILIUM_VERSIONS[@]}"; do
        download_cilium_version "${version}"
    done
    
    # 恢复 set -e
    set -e
    
    echo "======================================================"
    echo "所有组件下载任务已完成！"
    if [ $ERROR_COUNT -gt 0 ]; then
        echo "警告：有 $ERROR_COUNT 个组件下载失败，请查看日志了解详情。"
    else
        echo "所有组件下载成功！"
    fi
    echo "======================================================"
}

# 执行主函数
main