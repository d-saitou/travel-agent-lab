#!/bin/bash
# Name:
#   VS Code ワークスペース初回起動時セットアップスクリプト (tasks.json タスク用)
# Description:
#   VS Code のワークスペース初回起動時にセットアップを行う
# Usage:
#   ./task-setup-workspace.sh
set -euo pipefail

# スクリプトおよびリポジトリのパス
WORKSPACE_ROOT="$(cd -- "$(dirname -- "${0}")/../../" && pwd)"
SETUP_COMPLETED="${WORKSPACE_ROOT}/infra/.setup-completed"

# 初回セットアップ済みか確認
if [[ -f "${SETUP_COMPLETED}" ]]; then
  echo "ワークスペースセットアップ済み"
  exit 0
fi

echo "ワークスペース初回セットアップ開始..."
echo

# ワークスペース推奨拡張機能インストール
bash "${WORKSPACE_ROOT}/infra/scripts/install-recommended-extensions.sh"

# Linux または WSL 判定
ENVIRONMENT=$(bash "${WORKSPACE_ROOT}/infra/scripts/detect-linux-or-wsl.sh")
if [[ "${ENVIRONMENT}" == "wsl" ]]; then
  if ! docker info >/dev/null 2>&1; then
    echo
    echo -e "\033[31m[ERROR] Dockerを利用できません\033[0m"
    echo
    echo -e "\033[31mDocker Desktop の設定を確認してください\033[0m"
    echo -e "\033[31m1. Windows 側で Docker Desktop を起動する\033[0m"
    echo -e "\033[31m2. Settings > General を開く\033[0m"
    echo -e "\033[31m3. Use the WSL 2 based engine を有効にする\033[0m"
    echo -e "\033[31m4. Settings > Resources > WSL Integration を開く\033[0m"
    echo -e "\033[31m5. ubuntu-for-travel-agent-lab の連携を有効にする\033[0m"
    echo -e "\033[31m6. Apply & Restart を実行する\033[0m"

    # ワークスペース再起動案内
    echo
    echo -e "\033[31mDocker 有効化のため、ワークスペースを再起動してください\033[0m"
    echo

    # 任意キー入力待機
    read -r -n 1 -s -p "任意のキーを押すと終了します..." || true
    echo
  fi
fi

# セットアップ完了フラグ作成
touch "${SETUP_COMPLETED}"
