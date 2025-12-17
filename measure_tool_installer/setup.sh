#!/usr/bin/env bash

# 检查依赖命令是否存在
echo "检查依赖命令..."
required_commands=("ncu" "python3")
missing_commands=()

# 收集缺失的命令
for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        missing_commands+=("$cmd")
    fi
done

# 根据检查结果执行不同操作
if [ ${#missing_commands[@]} -eq 0 ]; then
    echo "依赖命令检查完成，所需命令已安装"
else
    echo "开始安装缺失命令..."
    BASHRC_FILE="~/.bashrc"
    BASHRC_FILE=$(eval echo "$BASHRC_FILE")
    for cmd in "${missing_commands[@]}"; do
        if [ "$cmd" == "ncu" ]; then
            # 安装 CUDA (包含 ncu)
            # 检查是否安装了NVIDIA驱动（依赖nvidia-smi命令）
            if ! command -v nvidia-smi &> /dev/null; then
                echo "错误：未检测到NVIDIA驱动程序"
                echo "请先安装NVIDIA驱动，然后再尝试运行此脚本"
                exit 1
            fi
            # 从nvidia-smi输出中提取驱动支持的最高CUDA版本
            CUDA_SUPPORTED_VERSION=$(nvidia-smi | grep "CUDA Version" | awk '{print $9}' | cut -d '.' -f 1,2)
            if [ -z "$CUDA_SUPPORTED_VERSION" ]; then
                echo "错误：无法获取驱动支持的CUDA版本"
                exit 1
            fi

            TARGET_CUDA_VERSION="12.2"

            # 版本比较函数（判断版本1是否大于等于版本2）
            version_ge() {
                [ "$(printf '%s\n' "$@" | sort -V | tail -n 1)" = "$1" ]
            }

            # 检查兼容性
            if version_ge "$CUDA_SUPPORTED_VERSION" "$TARGET_CUDA_VERSION"; then
                chmod +x cuda_12.2.0_535.54.03_linux.run
                bash cuda_12.2.0_535.54.03_linux.run
                # 安装完成后检查 ncu 是否可用，若不可用则尝试创建符号链接
                if ! command -v ncu &> /dev/null; then
                    if [ -f "/usr/local/cuda-12.2/bin/ncu" ]; then
                        CUDA_BIN_PATH="export PATH=/usr/local/cuda-12.2/bin:$PATH"
                        CUDA_LIB_PATH="export LD_LIBRARY_PATH=/usr/local/cuda-12.2/lib64:$LD_LIBRARY_PATH"
                        # 检查并添加CUDA二进制路径
                        if ! grep -qxF "$CUDA_BIN_PATH" "$BASHRC_FILE"; then
                            echo "$CUDA_BIN_PATH" >> "$BASHRC_FILE"
                        fi
                        # 检查并添加CUDA库路径
                        if ! grep -qxF "$CUDA_LIB_PATH" "$BASHRC_FILE"; then
                            echo "$CUDA_LIB_PATH" >> "$BASHRC_FILE"
                        fi
                        source "$BASHRC_FILE"
                        ln -sf /usr/local/cuda-12.2 /usr/local/cuda
                        ln -sf /usr/local/cuda/bin/ncu /usr/local/bin/ncu
                    fi
                fi
            else
                echo "错误：当前驱动支持的CUDA版本不兼容"
                echo "需要CUDA版本: $TARGET_CUDA_VERSION，当前驱动支持最高CUDA版本: $CUDA_SUPPORTED_VERSION"
                exit 1
            fi
        elif [ "$cmd" == "python3" ]; then
            # 安装 Python3
            # 防止要安装tar，直接解压
            # tar -zxvf Python-3.10.16.tgz -C ~
            cd Python-3.10.16
            ./configure --prefix=/usr/local/python3
            make && make install
            PYTHON_PATH="export PATH=$PATH:$HOME/bin:/usr/local/python3/bin"
            if ! grep -qxF "$PYTHON_PATH" "$BASHRC_FILE"; then
                echo "$PYTHON_PATH" >> "$BASHRC_FILE"
            fi
            source "$BASHRC_FILE"
            ln -s /usr/local/python3/bin/python3.10 /usr/bin/python3
            ln -s /usr/local/python3/bin/pip3.10 /usr/bin/pip3
        fi
    done
fi