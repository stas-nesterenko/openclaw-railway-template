#!/bin/sh
set -eu

if pgrep -f "filebrowser --root /data" >/dev/null 2>&1; then
  echo "[start.sh] filebrowser already running"
  exit 0
fi

nohup filebrowser \
  --root /data \
  --database /data/filebrowser.db \
  --port 8081 \
  --baseURL /files \
  >/data/filebrowser.log 2>&1 &

echo "[start.sh] filebrowser started on :8081"
