#!/bin/bash
# Name:
#   VS Code ワークスペース推奨拡張機能インストールスクリプト
# Description:
#   VS Code のワークスペース推奨拡張機能をインストールする
# Usage:
#   ./install-recommended-extensions.sh <project.code-workspace ファイルパス>
set -euo pipefail

workspace_file="${1:?ワークスペースファイルを指定してください}"

# ワークスペース推奨拡張機能取得
recommended_extensions=$(sed 's|//.*$||' "${workspace_file}" | yq -p=json -r '.extensions.recommendations[]')

# インストール済み拡張機能取得（IDは小文字で比較）
installed_extensions="$(code --list-extensions)"

while IFS= read -r extension; do
  [[ -z "${extension}" ]] && continue

  if ! grep -Fxiq -- "${extension}" <<< "${installed_extensions}"; then
    echo "VS Code 拡張インストール実行: ${extension}"
    code --install-extension "${extension}"
  else
    echo "VS Code 拡張インストール済み: ${extension}"
  fi
done <<< "${recommended_extensions}"
