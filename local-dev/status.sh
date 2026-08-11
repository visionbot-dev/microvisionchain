#!/usr/bin/env bash
# 查询本地开发节点状态
CONF=/mnt/d/Project/Sample/microvisionchain/local-dev/mvcd.conf
DATADIR=$HOME/mvclocal/data
cd ~/mvclocal

echo "--- 区块高度 ---"
./bin/mvc-cli -conf="$CONF" -datadir="$DATADIR" getblockcount 2>&1
echo "--- 余额 ---"
./bin/mvc-cli -conf="$CONF" -datadir="$DATADIR" getbalance 2>&1
echo "--- 挖矿信息 ---"
./bin/mvc-cli -conf="$CONF" -datadir="$DATADIR" getmininginfo 2>&1 | head -12
