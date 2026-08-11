#!/usr/bin/env bash
# 验证节点交易处理能力:发一笔转账
CONF=/mnt/d/Project/Sample/microvisionchain/local-dev/mvcd.conf
DATADIR=$HOME/mvclocal/data
cd ~/mvclocal

A2=$(./bin/mvc-cli -conf="$CONF" -datadir="$DATADIR" getnewaddress)
echo "第二地址: $A2"
TXID=$(./bin/mvc-cli -conf="$CONF" -datadir="$DATADIR" sendtoaddress "$A2" 5)
echo "交易 TXID: $TXID"
echo "--- 发送方余额 ---"
./bin/mvc-cli -conf="$CONF" -datadir="$DATADIR" getbalance
echo "--- mempool ---"
./bin/mvc-cli -conf="$CONF" -datadir="$DATADIR" getmempoolinfo
