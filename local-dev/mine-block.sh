#!/usr/bin/env bash
# ============================================================
# 自动出块守护脚本:每 10 分钟挖 1 个块
#
# 用法:
#   bash mine-block.sh start    后台启动(写 PID 文件)
#   bash mine-block.sh stop     停止
#   bash mine-block.sh status   查看状态与最近日志
#   bash mine-block.sh run      前台运行(调试)
#
# 配置项见下方变量
# ============================================================

CONF=/mnt/d/Project/Sample/microvisionchain/local-dev/mvcd.conf
DATADIR=$HOME/mvclocal/data
BIN_DIR=$HOME/mvclocal/bin
MINER_ADDR=n3yvJDx83gERHFdxUy2rqgxbVShfjEZbFY   # coinbase 收款地址
INTERVAL=600                                     # 出块间隔(秒)= 10 分钟
PID_FILE=$HOME/mvclocal/mine-block.pid
LOG_FILE=$HOME/mvclocal/mine-block.log

cli() { "$BIN_DIR/mvc-cli" -conf="$CONF" -datadir="$DATADIR" "$@"; }
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >>"$LOG_FILE"; }

do_mine() {
  local before after result
  before=$(cli getblockcount 2>/dev/null || echo "?")
  result=$(cli generatetoaddress 1 "$MINER_ADDR" 2>&1 || echo "MINE_FAIL")
  if [ "$result" = "MINE_FAIL" ]; then
    log "挖块失败(节点可能未运行): $result"
  else
    after=$(cli getblockcount 2>/dev/null || echo "?")
    log "已出块 高度 ${before} -> ${after}"
  fi
}

run() {
  log "自动出块守护启动: 间隔=${INTERVAL}s coinbase=$MINER_ADDR"
  while true; do
    do_mine
    sleep "$INTERVAL"
  done
}

case "${1:-run}" in
  start)
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      echo "已在运行 (PID $(cat "$PID_FILE"))"
      exit 0
    fi
    nohup bash "$0" run >/dev/null 2>&1 &
    echo $! >"$PID_FILE"
    echo "已后台启动 (PID $(cat "$PID_FILE"))"
    ;;
  stop)
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      kill "$(cat "$PID_FILE")"
      rm -f "$PID_FILE"
      echo "已停止"
    else
      echo "未在运行"
    fi
    ;;
  status)
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      echo "运行中 (PID $(cat "$PID_FILE"))"
    else
      echo "未运行"
    fi
    echo "--- 最近日志 ---"
    tail -5 "$LOG_FILE" 2>/dev/null || echo "(暂无日志)"
    ;;
  run)
    run
    ;;
  *)
    echo "用法: bash $0 {start|stop|status|run}"
    ;;
esac
