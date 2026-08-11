#!/usr/bin/env bash
# 生成测试地址与 WIF(临时节点,数据目录 $HOME/mvc-gen-data)
set -e
CONF=/mnt/d/Project/Sample/microvisionchain/local-dev/mvcd.conf
DATADIR=$HOME/mvc-gen-data
cd ~/mvclocal

# 清理上次残留并重建目录(mvcd 要求数据目录已存在)
rm -rf "$DATADIR"
mkdir -p "$DATADIR"

./bin/mvcd -conf="$CONF" -datadir="$DATADIR" -daemon

for i in $(seq 1 40); do
  if ./bin/mvc-cli -conf="$CONF" -datadir="$DATADIR" getblockcount >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

ADDR=$(./bin/mvc-cli -conf="$CONF" -datadir="$DATADIR" getnewaddress)
WIF=$(./bin/mvc-cli -conf="$CONF" -datadir="$DATADIR" dumpprivkey "$ADDR")
echo "GENERATED_ADDR=$ADDR"
echo "GENERATED_WIF=$WIF"

./bin/mvc-cli -conf="$CONF" -datadir="$DATADIR" stop
