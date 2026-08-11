#!/usr/bin/env bash
# 挖 1 块成熟 coinbase 后,向目标地址转账 50 SPACE
set -e
CONF=/mnt/d/Project/Sample/microvisionchain/local-dev/mvcd.conf
DATADIR=$HOME/mvclocal/data
MINER_ADDR=n3yvJDx83gERHFdxUy2rqgxbVShfjEZbFY
TARGET=mp9LTAMVsqJyHMkCDG72sZQghbb22sPHjH
cd ~/mvclocal
cli() { ./bin/mvc-cli -conf="$CONF" -datadir="$DATADIR" "$@"; }

echo "[1/3] 当前余额: $(cli getbalance)"
echo "[2/3] 挖 1 块使第 2 块 coinbase 成熟 ..."
cli generatetoaddress 1 "$MINER_ADDR" >/dev/null
echo "      挖块后余额: $(cli getbalance)"
echo "[3/3] 转账 50 SPACE 到 $TARGET ..."
TXID=$(cli sendtoaddress "$TARGET" 50)
echo "      TXID: $TXID"
echo "--- 转账后余额 ---"
cli getbalance
