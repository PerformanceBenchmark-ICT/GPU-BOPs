# 交付说明
1. `makeself ./measure_tool measure_tool.run "Measure Tool" ./ncu_script.sh`生成`measure_tool.run`
2. 将`measure_tool.run` copy 到`./measure_tool_installer/`
3. `makeself ./measure_tool_installer/  install.run "Installer" ./install.sh`生成`install.run`
4. 交付文件: `install.run` + `guide.md`

# 文件说明
- `setup.sh`是离线安装依赖的逻辑，目前只写了CUDA以及Python3，但是这两个也可能有依赖，具体看他们的环境，后续如果还有需要离线安装的，都可以填充在此处
- `ncu_script.sh`是ncu的测量逻辑，整体逻辑是先使用ncu执行测量生成结果文件，再用Python3对结果文件中的结果进行统计汇总
- `install.sh`的逻辑是先执行`setup.sh`，然后把提前生成的`measure_tool.run`复制到用户指定目录
    > `measure_tool.run`就是`ncu_script.sh`，只不过打包了一下，这样实现了封装。提前在我们的环境打包，防止还需要离线安装makeself。

# 离线安装
1. 需要的文件 copy 到`./measure_tool_installer/`
2. 在`setup.sh`中添加安装逻辑