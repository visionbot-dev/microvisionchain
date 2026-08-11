#!/usr/bin/env bash
# 本地开发节点完整启动入口(wrapper,避免 wsl 参数转义问题)
set -e

cd /mnt/d/Project/Sample/microvisionchain/local-dev

# 测试地址(WIF + 地址)—— 替换成你自己的
export WIF=cNue3Kp9zC99i5ZK45hoFJzPFbv5cejiwLCoeBLbmDnmz22p5VQL
export ADDRESS=n3yvJDx83gERHFdxUy2rqgxbVShfjEZbFY

# 二进制与数据目录
export MVCD_BIN=$HOME/mvclocal/bin/mvcd
export MVC_CLI_BIN=$HOME/mvclocal/bin/mvc-cli
export DATADIR=$HOME/mvclocal/data

bash start-node.sh
