# 已知环境兼容性
- **操作系统**：Ubuntu22.04
- **硬件设备**：适用于基于 NVIDIA Kepler 架构及更新架构的 GPU 设备。包括 Maxwell、Pascal、Volta 和 Turing 等 GPU 架构，即计算能力达到 3.0 及以上的 NVIDIA 设备。

# 使用步骤
**安装**
1. 通过`chmod +x install.run`为安装文件添加可执行权限，如果未能成功，尝试加上`sudo`再试。
    > 过程可能涉及CUDA安装，如遇到，按照默认选项确认即可。  
2. 通过`sudo bash install.run [output_directory]`进行安装，安装成功后会生成`measure.run`。
    > 例如`sudo bash install.run $(pwd)`，需要注意的是，`output_directory`必须是**绝对路径且不能为空**。

**使用**
1. 通过`sudo bash measure.run [cmd]`进行测量，其中`cmd`指的是程序运行命令。  
    > 例如`sudo bash measure.run python3 test.py`，其中`python3 test.py`就是`cmd`，最后得到的BOPs结果即为`test.py`中所定义的程序的测量结果。