#!/usr/bin/env bash
# 检查节点 RPC 可达性(脚本文件方式,避免 wsl 参数转义)
CONF=/mnt/d/Project/Sample/microvisionchain/local-dev/mvcd.conf
DATADIR=$HOME/mvclocal/data
cd ~/mvclocal

echo "CONF=$CONF"
echo "DATADIR=$DATADIR"
ls -la "$CONF"

echo "--- getblockcount ---"
./bin/mvc-cli -conf="$CONF" -datadir="$DATADIR" getblockcount 2>&1
echo "--- getblockchaininfo ---"
./bin/mvc-cli -conf="$CONF" -datadir="$DATADIR" getblockchaininfo 2>&1 | head -14
