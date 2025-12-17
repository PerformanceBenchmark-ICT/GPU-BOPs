#!/usr/bin/env bash

# 检查参数，需要给出要执行的命令
if [ $# -eq 0 ]; then
    echo "错误：请提供要执行的命令作为参数" >&2
    exit 1
fi

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
    echo "缺失必要依赖，请尝试重新安装"
    exit 1
fi

# 创建临时文件
echo "正在创建临时文件..."
tmpfile=$(mktemp "${TMPDIR:-/tmp}/ncu_output.XXXXXX") || {
    echo "错误：无法创建临时文件" >&2
    exit 1
}
echo "临时文件创建成功：$tmpfile"

metrics="smsp__sass_thread_inst_executed_op_fadd_pred_on.sum,\
smsp__sass_thread_inst_executed_op_fmul_pred_on.sum,\
smsp__sass_thread_inst_executed_op_ffma_pred_on.sum,\
smsp__sass_thread_inst_executed_op_hadd_pred_on.sum,\
smsp__sass_thread_inst_executed_op_hmul_pred_on.sum,\
smsp__sass_thread_inst_executed_op_hfma_pred_on.sum,\
smsp__sass_thread_inst_executed_op_dadd_pred_on.sum,\
smsp__sass_thread_inst_executed_op_dmul_pred_on.sum,\
smsp__sass_thread_inst_executed_op_dfma_pred_on.sum"

# 使用ncu进行性能分析
echo "正在执行程序..."
ncu --metrics $metrics --target-processes all "$@" > "$tmpfile" 2>&1
ncu_exit=$?

# 处理ncu执行结果
if [ $ncu_exit -ne 0 ]; then
    echo "警告：ncu执行失败（退出码 $ncu_exit），尝试解析现有输出..." >&2
    echo "错误信息:"
    grep -i error "$tmpfile" >&2
fi

# 统计BOPs
echo "正在统计BOPs..."
if ! python3 - "$tmpfile" <<'EOF'
import re
import sys

def parse_nsight_output(file_path):
    """解析Nsight Compute的输出文件，提取ffma、fadd、fmul、hfma、hadd、hmul、dfma、dadd、dmul指令的执行次数"""
    try:
        with open(file_path, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"错误: 文件 '{file_path}' 不存在")
        return None
    
    # 用于匹配指标行的正则表达式
    metric_pattern = re.compile(r'(smsp__sass_thread_inst_executed_op_(fadd|ffma|fmul|hfma|hadd|hmul|dfma|dadd|dmul)_pred_on\.sum)\s+inst\s+(\d+)')

    total_instructions = {
        'fadd': 0,
        'ffma': 0,
        'fmul': 0,
        'hfma': 0,
        'hadd': 0,
        'hmul': 0,
        'dfma': 0,
        'dadd': 0,
        'dmul': 0
    }
    
    # 提取所有指标数据并汇总
    for match in metric_pattern.finditer(content):
        metric_name = match.group(2)
        value = int(match.group(3))
        total_instructions[metric_name] += value
    
    return total_instructions

def main():
    """
    - 统计各种类型指令的总执行次数
    - 计算估计的总浮点运算次数（BOPs）
    """
    file_path = sys.argv[1]
    
    # 解析输出文件并统计指令执行次数
    total_instructions = parse_nsight_output(file_path)
    
    # 打印结果
    print("\n==== Nsight Compute 指令统计结果 ====")
    # print("\n各类型指令总执行次数:")
    # print(f"  hfma: {total_instructions['hfma']:,}")
    # print(f"  hadd: {total_instructions['hadd']:,}")
    # print(f"  hmul: {total_instructions['hmul']:,}")
    # print(f"  ffma: {total_instructions['ffma']:,}")
    # print(f"  fadd: {total_instructions['fadd']:,}")
    # print(f"  fmul: {total_instructions['fmul']:,}")
    # print(f"  dfma: {total_instructions['dfma']:,}")
    # print(f"  dadd: {total_instructions['dadd']:,}")
    # print(f"  dmul: {total_instructions['dmul']:,}")
    
    # 计算不同精度下的浮点运算总次数并归一化到64位浮点运算
    # 单精度：ffma, fadd,fmul
    total_single_precision_bops = 2 * total_instructions['ffma'] + total_instructions['fadd'] + total_instructions['fmul']
    
    # 双精度：dfma, dadd, dmul
    total_double_precision_bops = 2 * total_instructions['dfma'] + total_instructions['dadd'] + total_instructions['dmul']
    
    # 半精度：hfma, hadd, hmul
    total_half_precision_bops = 2 * total_instructions['hfma'] + total_instructions['hadd'] + total_instructions['hmul']
    
    # 打印结果
    # print(f"\n半精度浮点运算总次数 (BOPs - 半精度): {total_half_precision_bops:,}")
    # print(f"单精度浮点运算总次数 (BOPs - 单精度): {total_single_precision_bops:,}")
    # print(f"双精度浮点运算总次数 (BOPs - 双精度): {total_double_precision_bops:,}")
    print(f"\n浮点运算总次数 (BOPs): {total_double_precision_bops+total_single_precision_bops/2+total_half_precision_bops/4:,}")

if __name__ == "__main__":
    main()
EOF
then
    echo "错误：BOPs统计失败" >&2
    rm -f "$tmpfile"
    exit 1
fi

# 清理临时文件
rm -f "$tmpfile"
exit 0