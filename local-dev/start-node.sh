#!/usr/bin/env bash
# ============================================================
# MVC 本地开发节点启动脚本
#
# 特性:
#   - 单机 / 完全离线(testnet 模式,不连任何外部节点)
#   - 节点启动后自动导入测试地址私钥并分发初始资金
#   - 幂等:重复执行不会重复挖块(检测到余额后跳过)
#
# 用法:
#   WIF=<测试地址私钥> ADDRESS=<对应地址> ./start-node.sh
#   或将下方 WIF / ADDRESS 直接改为固定值
#
# 可覆盖的环境变量:
#   MVCD_BIN / MVC_CLI_BIN  可执行文件路径(默认本脚本同目录)
#   DATADIR                 数据目录(默认 ./data)
#   INITIAL_BLOCKS          初始挖块数(默认 2,coinbase 每块 50 SPACE)
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------- 配置 ----------
MVCD_BIN="${MVCD_BIN:-$SCRIPT_DIR/mvcd}"
MVC_CLI_BIN="${MVC_CLI_BIN:-$SCRIPT_DIR/mvc-cli}"
CONF_FILE="$SCRIPT_DIR/mvcd.conf"
DATADIR="${DATADIR:-$SCRIPT_DIR/data}"

# 测试地址(WIF 私钥 + 对应地址),首次启动必须设置
WIF="${WIF:-}"
ADDRESS="${ADDRESS:-}"

INITIAL_BLOCKS="${INITIAL_BLOCKS:-2}"          # coinbase 每块 50 SPACE
GENERATE_MAX_TRIES="${GENERATE_MAX_TRIES:-2000000000}"
RPC_WAIT_SEC="${RPC_WAIT_SEC:-120}"
# -------------------------

# Windows 兼容:自动补 .exe 扩展名
[ -x "$MVCD_BIN" ] || MVCD_BIN="$MVCD_BIN.exe"
[ -x "$MVC_CLI_BIN" ] || MVC_CLI_BIN="$MVC_CLI_BIN.exe"

if ! [ -x "$MVCD_BIN" ] || ! [ -x "$MVC_CLI_BIN" ]; then
  echo "错误: 找不到可执行文件 mvcd / mvc-cli" >&2
  echo "      请先构建,或用 MVCD_BIN / MVC_CLI_BIN 指定路径" >&2
  exit 1
fi

# 平台检测: Windows(Git Bash / MSYS / MinGW)不支持 -daemon,
# 且调用 .exe 时路径参数必须转换为 Windows 格式
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) IS_WINDOWS=1 ;;
  *) IS_WINDOWS=0 ;;
esac

if [ "$IS_WINDOWS" = "1" ]; then
  CONF_ARG="$(cygpath -w "$CONF_FILE")"
  DATADIR_ARG="$(cygpath -w "$DATADIR")"
  MVCD_LOG="$(cygpath -w "$DATADIR/mvcd.log")"
else
  CONF_ARG="$CONF_FILE"
  DATADIR_ARG="$DATADIR"
  MVCD_LOG="$DATADIR/mvcd.log"
fi

cli() { "$MVC_CLI_BIN" -conf="$CONF_ARG" -datadir="$DATADIR_ARG" "$@"; }

if [ -z "$WIF" ] || [ -z "$ADDRESS" ]; then
  echo "错误: 未设置 WIF(私钥)或 ADDRESS(地址)" >&2
  echo "  用法: WIF=<私钥> ADDRESS=<地址> ./start-node.sh" >&2
  exit 1
fi

# 1) 启动节点(已在运行则跳过)
if cli getblockcount >/dev/null 2>&1; then
  echo "[1/4] 节点已在运行,跳过启动"
else
  echo "[1/4] 启动 MVC 节点(testnet / 离线) ..."
  mkdir -p "$DATADIR"
  if [ "$IS_WINDOWS" = "1" ]; then
    # Windows 不支持 -daemon,改为 nohup 后台运行,日志写入数据目录
    nohup "$MVCD_BIN" -conf="$CONF_ARG" -datadir="$DATADIR_ARG" >"$MVCD_LOG" 2>&1 &
  else
    "$MVCD_BIN" -conf="$CONF_ARG" -datadir="$DATADIR_ARG" -daemon
  fi
  echo "      等待 RPC 就绪(最多 ${RPC_WAIT_SEC}s) ..."
  i=0
  while [ "$i" -lt "$RPC_WAIT_SEC" ]; do
    if cli getblockcount >/dev/null 2>&1; then break; fi
    sleep 2
    i=$((i + 2))
  done
  if ! cli getblockcount >/dev/null 2>&1; then
    echo "错误: 节点 RPC 未在 ${RPC_WAIT_SEC}s 内就绪,请检查日志" >&2
    exit 1
  fi
fi

# 2) 导入测试地址私钥(已导入过则忽略错误)
echo "[2/4] 导入测试地址私钥 ..."
cli importprivkey "$WIF" "dev-fund" true || true

# 3) 若余额为 0,挖初始资金(最低难度块,CPU 每块约 1~3 分钟)
balance="$(cli getbalance 2>/dev/null || true)"
echo "[3/4] 当前余额: ${balance:-查询失败} SPACE"
if [ -z "$balance" ] || [ "$balance" = "0.00000000" ] || [ "$balance" = "0" ]; then
  echo "      挖取 $INITIAL_BLOCKS 个区块分发初始资金到 $ADDRESS ..."
  ok=0
  for attempt in $(seq 1 30); do
    hashes="$(cli generatetoaddress "$INITIAL_BLOCKS" "$ADDRESS" "$GENERATE_MAX_TRIES" 2>/dev/null || true)"
    if [ -n "$hashes" ] && [ "$hashes" != "[]" ]; then
      ok=1
      break
    fi
    echo "      第 ${attempt} 轮未挖出(难度限制),重试 ..."
  done
  if [ "$ok" != "1" ]; then
    echo "错误: 多次尝试未能挖出区块,请检查节点日志" >&2
    exit 1
  fi
fi

# 4) 输出状态
echo "[4/4] 完成"
echo "-------------------------------------------"
echo " 链模式   : testnet(离线本地链)"
echo " 区块高度 : $(cli getblockcount)"
echo " 测试地址 : $ADDRESS"
echo " 余额     : $(cli getbalance) SPACE"
echo " 停止节点 : $(basename "$MVC_CLI_BIN") -conf=$CONF_ARG -datadir=$DATADIR_ARG stop"
echo "-------------------------------------------"
