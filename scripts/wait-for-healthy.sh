#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 --url <url> [--timeout <seconds>] [--interval <seconds>]" >&2
  exit 1
}

TIMEOUT=60
INTERVAL=2

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) URL="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --interval) INTERVAL="$2"; shift 2 ;;
    *) usage ;;
  esac
done

: "${URL:?--url is required}"

START=$(date +%s)
while true; do
  if curl -sf -o /dev/null -m 5 "$URL"; then
    echo "Healthy: $URL"
    exit 0
  fi
  NOW=$(date +%s)
  ELAPSED=$((NOW - START))
  if (( ELAPSED >= TIMEOUT )); then
    echo "Timed out waiting for $URL after ${TIMEOUT}s" >&2
    exit 1
  fi
  sleep "$INTERVAL"
done
