#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 --url <url> [--host-header <host>] [--timeout <seconds>] [--interval <seconds>]" >&2
  exit 1
}

TIMEOUT=60
INTERVAL=2
HOST_HEADER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) URL="$2"; shift 2 ;;
    --host-header) HOST_HEADER="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --interval) INTERVAL="$2"; shift 2 ;;
    *) usage ;;
  esac
done

: "${URL:?--url is required}"

CURL_ARGS=(-sf -o /dev/null -m 5)
if [[ -n "$HOST_HEADER" ]]; then
  CURL_ARGS+=(-H "Host: $HOST_HEADER")
fi

START=$(date +%s)
while true; do
  if curl "${CURL_ARGS[@]}" "$URL"; then
    echo "Healthy: $URL${HOST_HEADER:+ (Host: $HOST_HEADER)}"
    exit 0
  fi
  NOW=$(date +%s)
  ELAPSED=$((NOW - START))
  if (( ELAPSED >= TIMEOUT )); then
    echo "Timed out waiting for $URL${HOST_HEADER:+ (Host: $HOST_HEADER)} after ${TIMEOUT}s" >&2
    exit 1
  fi
  sleep "$INTERVAL"
done
