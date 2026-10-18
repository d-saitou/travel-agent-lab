#!/bin/bash
# Name:
#   開発コンテナ起動待機スクリプト (tasks.json タスク用)
# Description:
#   backendコンテナ・frontendコンテナの起動を待機する
# Usage:
#   ./task-wait-devcontainers-ready.sh
set -euo pipefail

TIMEOUT_SECONDS=120
INTERVAL_SECONDS=5
ELAPSED=0

while (( ELAPSED < TIMEOUT_SECONDS )); do
  BACKEND_READY=false
  FRONTEND_READY=false

  if curl --silent --fail http://localhost:8000/health >/dev/null; then
    BACKEND_READY=true
  fi

  if curl --silent --fail http://localhost:3000/ >/dev/null; then
    FRONTEND_READY=true
  fi

  if [[ "${BACKEND_READY}" == true && "${FRONTEND_READY}" == true ]]; then
    echo "backendコンテナ・frontendコンテナ起動完了"
    exit 0
  fi

  echo "backendコンテナ・frontendコンテナ起動中... (${ELAPSED}s経過)"
  sleep ${INTERVAL_SECONDS}
  ELAPSED=$((ELAPSED + INTERVAL_SECONDS))
done

echo "ERROR: backendコンテナ・frontendコンテナ起動待機タイムアウト" >&2
docker compose ps >&2
docker compose logs --tail=100 >&2
exit 1
