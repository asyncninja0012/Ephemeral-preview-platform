#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 --pr <number> --compose <path> --service <name> --port <port> --domain <base-domain> --out <output-path>" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr) PR="$2"; shift 2 ;;
    --compose) COMPOSE_FILE="$2"; shift 2 ;;
    --service) SERVICE="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --domain) DOMAIN="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    *) usage ;;
  esac
done

: "${PR:?--pr is required}"
: "${COMPOSE_FILE:?--compose is required}"
: "${SERVICE:?--service is required}"
: "${PORT:?--port is required}"
: "${DOMAIN:?--domain is required}"
: "${OUT:?--out is required}"

if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "compose file not found: $COMPOSE_FILE" >&2
  exit 1
fi

HOST="pr-${PR}.${DOMAIN}"
ROUTER="pr-${PR}"

cat > "$OUT" <<EOF
services:
  ${SERVICE}:
    networks:
      - preview-net
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.${ROUTER}.rule=Host(\`${HOST}\`)"
      - "traefik.http.services.${ROUTER}.loadbalancer.server.port=${PORT}"

networks:
  preview-net:
    external: true
EOF

echo "Rendered override for PR ${PR}: ${OUT} (host: ${HOST})"
