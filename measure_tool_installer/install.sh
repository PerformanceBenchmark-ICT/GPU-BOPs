
#!/usr/bin/env bash

if [ $# -eq 0 ]; then
    echo "用法: sudo bash install.run [output_directory]"
    exit 1
elif [ $# -eq 1 ]; then
    # 判断 $1 是否为绝对路径（以 / 开头）
    if [ "${1:0:1}" != "/" ]; then
        echo "检测到输出目录非绝对路径，请检查后重新运行"
        exit 1
    fi
    OUTPUT_DIR=$1
fi

# 去掉目录路径末尾的斜杠
OUTPUT_DIR=$(echo "$OUTPUT_DIR" | sed 's:/*$::')

# 检查输出目录是否存在
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "指定输出目录不存在，请检查后重新运行"
    exit 1
fi

chmod +x setup.sh
bash setup.sh
# setup.sh执行如果失败则退出
if [ $? -ne 0 ]; then
    echo "安装失败，请重试"
    exit 1
fi

chmod +x measure_tool.run
cp measure_tool.run "$OUTPUT_DIR/measure.run"
if [ $? -eq 0 ]; then
    echo "安装成功：$OUTPUT_DIR/measure.run"
else
    echo "安装失败，请重试"
    exit 1
fi

exit 0
