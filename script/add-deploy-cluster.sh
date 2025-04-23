#!/bin/bash

# Function to display script usage
usage() {
    echo "使用方法: $0 -n <name>"
    echo "  -n <name>  部署的名称"
    exit 1
}

# Function to display error messages
error() {
    echo -e "\033[0;31m错误: $1\033[0m" >&2
    exit 1
}

# Function to display success messages
success() {
    echo -e "\033[0;32m$1\033[0m"
}

# Function to display information messages
info() {
    echo -e "\033[0;34m$1\033[0m"
}

# Process command line arguments
while getopts "n:" opt; do
    case ${opt} in
        n)
            name=$OPTARG
            ;;
        *)
            usage
            ;;
    esac
done

# Check if name parameter is provided
if [ -z "$name" ]; then
    error "必须提供部署名称。请使用 -n 选项。"
    usage
fi

# Check if name contains valid characters
if [[ ! $name =~ ^[a-zA-Z0-9_-]+$ ]]; then
    error "部署名称只能包含字母、数字、下划线和连字符。"
fi

# Define paths
deploy_path="deploy/$name"
example_path="deploy/example"

# Check if the example directory exists
if [ ! -d "$example_path" ]; then
    error "示例部署目录不存在: $example_path"
fi

# Check if the target directory already exists
if [ -d "$deploy_path" ]; then
    error "部署 '$name' 已经存在于 $deploy_path"
fi

# Copy the example directory to the new deployment directory
info "正在创建新部署 '$name'..."
if ! cp -r "$example_path" "$deploy_path"; then
    error "复制示例部署到 $deploy_path 失败"
fi

# Update the config.yml file
config_file="$deploy_path/config.yml"
if [ ! -f "$config_file" ]; then
    error "配置文件不存在: $config_file"
fi

info "正在更新配置文件..."
# Create a backup of the original file
cp "$config_file" "${config_file}.bak" || error "创建配置文件备份失败"

# Use sed to replace the deploy_name in config.yml, preserving quotes
sed "s/deploy_name: \"example\"/deploy_name: \"$name\"/" "${config_file}.bak" > "$config_file"
if [ $? -ne 0 ]; then
    error "更新配置文件中的 deploy_name 失败"
    # Restore the backup
    mv "${config_file}.bak" "$config_file"
    exit 1
fi

# Verify the replacement worked
if ! grep -q "deploy_name: \"$name\"" "$config_file"; then
    info "警告: 无法验证配置更新。配置文件可能没有预期的格式。"
    info "您可能需要手动将 deploy_name 更新为 \"$name\" 在 $config_file 中"
else
    # Remove the backup file if everything worked
    rm "${config_file}.bak"
fi

# Success message and next steps
success "\n部署 '$name' 已成功创建！"
echo ""
info "后续步骤:"
echo "1. 修改主配置文件: $config_file"
echo "2. 配置主机相关信息: $deploy_path/hosts"
echo ""
info "准备好后，请从主目录执行以下命令开始部署:"
echo "ansible-playbook -e @deploy/$name/config.yml -i deploy/$name/hosts playbooks/00.deploy-kubernetes.yml"
echo ""

exit 0