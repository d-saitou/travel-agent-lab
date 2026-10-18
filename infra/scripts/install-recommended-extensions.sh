#!/bin/bash
# Name:
#   VS Code ワークスペース推奨拡張機能インストールスクリプト
# Description:
#   VS Code のワークスペース推奨拡張機能をインストールする
# Usage:
#   ./install-recommended-extensions.sh
set -euo pipefail

WORKSPACE_DIR="$(cd -- "$(dirname -- "${0}")/../../" && pwd)"
WORKSPACE_FILE="${WORKSPACE_DIR}/travel-agent-lab.code-workspace"

# ワークスペース推奨拡張機能取得
RECOMMENDED_EXTENSIONS=$(sed 's|//.*$||' "${WORKSPACE_FILE}" | yq -p=json -r '.extensions.recommendations[]')

# インストール済み拡張機能取得（IDは小文字で比較）
INSTALLED_EXTENSIONS="$(code --list-extensions)"

while IFS= read -r EXTENSION; do
  [[ -z "${EXTENSION}" ]] && continue

  if ! grep -Fxiq -- "${EXTENSION}" <<< "${INSTALLED_EXTENSIONS}"; then
    echo "VS Code 拡張インストール実行: ${EXTENSION}"
    code --install-extension "${EXTENSION}"
  else
    echo "VS Code 拡張インストール済み: ${EXTENSION}"
  fi
done <<< "${RECOMMENDED_EXTENSIONS}"
