# MVC 本地开发节点说明

在**离线/局域网环境**下运行的 MVC 单机开发节点。节点启动后自动向测试地址分发初始资金(SPACE),之后可正常处理交易(验证、广播、查询),但**不持续出块**。

## 环境

- Windows + WSL2(Ubuntu 22.04),节点在 WSL 内运行
- 二进制:`mvcd` / `mvc-cli`(v0.2.1.0,基于本仓库构建)
- 运行方式:完全离线(`testnet` 模式,`noconnect`,不连任何外部节点)

## 目录结构

```
local-dev/
├── mvcd.conf       # 节点配置:testnet / 离线 / RPC 认证 / 最低工作量
├── start-node.sh   # 核心脚本:启动节点 → 导入私钥 → 自动挖块分发初始资金(幂等)
├── run-local.sh    # 一键入口(含测试地址 WIF/ADDRESS,替换为你自己的)
├── gen-addr.sh     # 生成新的测试地址 + WIF
├── status.sh       # 查询余额 / 区块高度 / 挖矿信息
├── test-tx.sh      # 发一笔转账,验证交易处理
├── mvcd            # 节点二进制
└── mvc-cli         # RPC 客户端二进制
```

## 快速开始

```bash
# 进入 WSL
wsl -d Ubuntu-22.04

# 启动节点并分发初始资金(已在运行则跳过启动;已有余额则跳过挖块)
cd /mnt/d/Project/Sample/microvisionchain/local-dev
bash run-local.sh

# 预期输出:区块高度 2,余额 50 SPACE(第 2 块的 coinbase 成熟后为 100)
```

## 配置你自己的测试地址

编辑 `run-local.sh`,替换顶部两行:

```bash
export WIF=cNue3Kp9zC99i5ZK45hoFJzPFbv5cejiwLCoeBLbmDnmz22p5VQL   # 你的 WIF
export ADDRESS=n3yvJDx83gERHFdxUy2rqgxbVShfjEZbFY                # 对应地址
```

⚠️ **必须是 testnet 版本**:地址以 `m`/`n` 开头,WIF 以 `c` 开头(版本字节 0xef)。
生成方式:`bash gen-addr.sh`(输出 `GENERATED_ADDR` / `GENERATED_WIF`)。

## 常用操作

```bash
bash status.sh                          # 查看余额 / 高度 / 挖矿信息
bash test-tx.sh                         # 发一笔 5 SPACE 转账(验证交易处理)

# 手动操作(以 mvc-cli 为例)
./mvc-cli -conf=./mvcd.conf -datadir=$HOME/mvclocal/data getbalance
./mvc-cli -conf=./mvcd.conf -datadir=$HOME/mvclocal/data sendtoaddress <地址> <金额>
./mvc-cli -conf=./mvcd.conf -datadir=$HOME/mvclocal/data getrawtransaction <txid> true

# 把 mempool 中的交易"确认"进区块(可选,挖 1 个块)
./mvc-cli -conf=./mvcd.conf -datadir=$HOME/mvclocal/data generatetoaddress 1 <地址>

# 停止节点
./mvc-cli -conf=./mvcd.conf -datadir=$HOME/mvclocal/data stop
```

## 关键机制(为什么这样设计)

1. **必须挖块**:coinbase 交易只能在区块中;创世块 coinbase 不可花费。所以"启动即分发初始资金"在 UTXO 模型下必然等价于**本地挖 2 个最低难度块**(testnet 的 coinbase 成熟期 = 1 块,第 1 块 coinbase 在挖出第 2 块后即可花费)。
2. **不持续出块**:初始资金发放后不再挖矿,交易停留在 mempool,可通过 `generatetoaddress 1` 手动确认。
3. **幂等**:重复执行 `run-local.sh` 不会重复挖块(检测到余额非 0 即跳过)。
4. **加速**:本地构建副本将 testnet 的 `powLimit` 从 `00000000ffff...` 调低为 `0000ffff...`(哈希前缀要求 32bit → 16bit),使块 1-7 秒出。

## 数据与二进制位置

| 项 | 路径 |
|----|------|
| 数据目录 | `~/mvclocal/data`(WSL 内) |
| 运行二进制 | `~/mvclocal/bin/mvcd`、`~/mvclocal/bin/mvc-cli`(WSL 内) |
| 构建源码副本 | `~/mvc-build`(WSL 内,含 powLimit 修改) |
| 本目录备份 | `./mvcd`、`./mvc-cli`(Windows 侧,可查不可直接执行) |

## 注意事项

- **完全隔离**:`-noconnect -dnsseed=0 -listen=0`,不会连官方网络;数据与主网互不影响。
- **组网**:如需多台机器共享同一本地链,所有节点必须使用同一份修改过 powLimit 的二进制,并用 `-connect=<IP>` 相连。
- **powLimit 修改仅限测试网参数**,且只改在 `~/mvc-build` 构建副本中,**未修改 Windows 源**(`D:\Project\Sample\microvisionchain`)。
- **重启后链数据保留**(在 `~/mvclocal/data`),余额不会丢失。

## 常见问题

| 现象 | 处理 |
|------|------|
| `run-local.sh` 挖块卡住很久 | 正常时块 1-7 秒出;若超过 2 分钟,检查是否用了旧的未改难度的二进制 |
| `mvc-cli` 报 RPC 超时 | 节点未运行,先执行 `bash run-local.sh` |
| `importprivkey` 报 invalid key | WIF 不是 testnet 版本 |
| 想要全新链 | 删掉 `~/mvclocal/data` 后重新 `bash run-local.sh` |
