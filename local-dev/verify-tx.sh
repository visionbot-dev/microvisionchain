#!/usr/bin/env bash
# 验证转账交易详情
CONF=/mnt/d/Project/Sample/microvisionchain/local-dev/mvcd.conf
DATADIR=$HOME/mvclocal/data
TXID=b4b3b92cebe3a6745844d138964f7ebbaf04e2c20f0ba47b929589372bebb395
cd ~/mvclocal
./bin/mvc-cli -conf="$CONF" -datadir="$DATADIR" getrawtransaction "$TXID" true 2>&1 | head -40
