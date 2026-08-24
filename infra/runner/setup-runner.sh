#!/usr/bin/env bash
set -euo pipefail

: "${REPO_URL:?Set REPO_URL to https://github.com/<owner>/<repo>}"
: "${RUNNER_TOKEN:?Set RUNNER_TOKEN to a registration token from that repo Settings > Actions > Runners > New self-hosted runner page (expires in ~1 hour)}"

cd "$(dirname "$0")"
docker compose up -d

echo "Runner starting as '${RUNNER_NAME:-preview-runner}' (label: preview)."
echo "Check it came online: ${REPO_URL}/settings/actions/runners"
