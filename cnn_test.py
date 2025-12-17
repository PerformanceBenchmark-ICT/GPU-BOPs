import torch

def run_calculations(device, dtype, B, M, N, K):
    """
    在指定设备和数据类型上执行矩阵乘法和加法。
    
    执行的运算是: C = A @ B + D
    - A: (B, M, K)
    - B: (B, K, N)
    - C, D: (B, M, N)
    """
    print(f"\n--- 正在执行 {str(dtype)} 精度的计算 ---")
    
    # 创建输入张量
    a = torch.randn(B, M, K, device=device, dtype=dtype)
    b = torch.randn(B, K, N, device=device, dtype=dtype)
    d = torch.randn(B, M, N, device=device, dtype=dtype)
    
    # 核心运算：矩阵乘法后跟一个加法
    # 矩阵乘法的FLOPs约等于 2 * B * M * N * K
    # 矩阵加法的FLOPs约等于 B * M * N
    c = torch.matmul(a, b) + d
    
    # 确保GPU操作完成，以便ncu可以捕获它们
    torch.cuda.synchronize()
    
    print(f"计算完成。张量 c 的形状: {c.shape}")

def main():
    """主函数，检查CUDA并执行不同精度的计算。"""
    if not torch.cuda.is_available():
        print("错误：此脚本需要一个可用的 NVIDIA GPU 和 PyTorch CUDA 版本。")
        return

    device = torch.device("cuda")
    print(f"找到 GPU: {torch.cuda.get_device_name(0)}")

    # 定义矩阵维度
    B, M, N, K = 32, 1024, 2048, 512

    # --- 执行单精度 (FP32) 计算 ---
    # 理论FLOPs = 2 * 32 * 1024 * 2048 * 512 (matmul) + 32 * 1024 * 2048 (add)
    # 约 68,786,526,208 FLOPs
    run_calculations(device, torch.float32, B, M, N, K)
    
    # --- 执行半精度 (FP16) 计算 ---
    # 某些GPU（如Ampere及以后架构）在执行FP16运算时会使用Tensor Cores，
    # ncu会将其正确地统计为hfma指令。
    # 理论FLOPs与FP32相同
    run_calculations(device, torch.float16, B, M, N, K)
    
    print("\n所有计算已执行完毕。")

if __name__ == "__main__":
    main()