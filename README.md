# GPU-BOPs

GPU-BOPs 是一组用于测试 GPU 平台上深度学习负载程序消耗的 BOPs 值（基本操作数）的实验脚本。

该项目运行在 Linux 环境下，
对目标负载程序进行指令级追踪，采集并聚合核心算术指令（如 FADD, FMUL, HFMA 等）的执行计数，
用于分析深度学习模型在硬件层面的真实计算成本和行为表现。

---

## 这个项目解决什么问题

在 GPU 性能与算力评估实验中，常常需要回答以下问题：

- 某个深度学习模型在特定 GPU 架构上的真实计算负载（而非理论 FLOPs）
- 区分不同精度（FP16/FP32/FP64）指令在实际运行中的分布情况
- 提供一个比“运行时间”更稳定、比“理论算力”更精准的硬件架构无关度量指标

GPU-BOPs 提供了一种自动化的、环境自适应的方式来完成上述指标的采集与计算。

---

## 当前限制

目前该项目存在以下限制：

- **性能开销较大**：由于使用了 Kernel Replay（内核重放）技术进行全指令追踪，测量过程的耗时会显著高于程序的正常运行时间。
- **硬件限制**：仅支持 NVIDIA GPU，且计算能力需 >= 3.0（Kepler 架构及以上）。

---

## 目录结构

```text
GPU-BOPs/
├── measure_tool/
│   └── ncu_script.sh       # 核心测量引擎，封装 ncu 命令并负责 BOPs 聚合计算
│
├── measure_tool_installer/
│   └── setup.sh            # 环境初始化脚本，负责自动检测并在线安装 Python3、ncu 等依赖
│
├── cnn_test.py             # 示例负载脚本（基于 PyTorch 的卷积运算测试）
│
└── README.md
```
## 运行环境
+ Linux (推荐 Ubuntu 20.04 / 22.04)
+ NVIDIA GPU Driver (需已安装)
+ Python 3 (脚本可自动安装)
+ NVIDIA Nsight Compute (脚本可自动安装)
+ 需要 sudo 权限


## 使用示例
1. 环境初始化（首次运行前）使用提供的安装脚本一键检查并配置依赖环境（支持在线安装缺失工具）：
```bash
cd measure_tool_installer
sudo bash setup.sh
```
2. 执行测量下面的示例展示了如何对一个给定的 Python 脚本进行测试：
```Bash
# 回到项目根目录
cd ..

# 语法：./measure_tool/ncu_script.sh <您的运行命令>
./measure_tool/ncu_script.sh python3 cnn_test.py
```
3. 测量自定义负载如果您有自己的训练脚本 `train_resnet.py`，只需将其作为参数传入：
```Bash
sudo ./measure_tool/ncu_script.sh python3 train_resnet.py --batch-size 32
```
输出结果实验结束后，工具会直接在标准输出（stdout）中打印统计信息，核心包含：Nsight Compute 原始数据：各类型指令（如 ffma, hadd）的原始执行次数以及BOPs 指标输出示例片段：
```Plaintext
...
[INFO] 正在统计 BOPs...

==== Nsight Compute 指令统计结果 ====

基本运算总次数 (BOPs): 137,573,052,416
```
