#!/bin/bash
# Name:
#   旅行履歴・提案エージェント 開発環境プロビジョニングスクリプト
# Description:
#   以下の開発環境構築処理を実行する：
#   1. システム要件チェック (root 権限、.env・secrets.txt 存在確認)
#   2. Ansible インストール (未インストール時のみ)
#   3. yq インストール (未インストール時のみ)
#   4. .env・secrets.txt → Ansible group_vars 変換
#   5. Ansible Playbook (site.yml) 実行
# Usage:
#   ./provision-dev-env.sh <secrets.txt ファイルパス>
# Note:
#   - 実行前に .env.example をコピーして .env を作成し、設定等を環境に合わせて変更すること。
#   - 実行前に secrets.txt.example をコピーして secrets.txt を作成し、機密情報を設定すること。
#   - 環境構築完了後、secrets.txt は直ちに削除すること。
#   - root 権限で実行すること。
set -euo pipefail

# 変数定義
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)
ANSIBLE_DIR="${SCRIPT_DIR}/ansible"
ENV_PATH="${SCRIPT_DIR}/../../.env"
SECRETS_PATH="${1:-}"
ANSIBLE_GROUP_VARS_PATH="${ANSIBLE_DIR}/group_vars/all.yml"

# スクリプト終了処理
cleanup() {
  # ./infra/provision/ansible/group_vars/all.yml 削除
  rm -f "${ANSIBLE_GROUP_VARS_PATH}"
  # secrets.txt 削除警告表示
  if [ -n "${SECRETS_PATH}" ] && [ -f "${SECRETS_PATH}" ]; then
    show_secrets_warning
  fi
}
trap cleanup EXIT

# Description:
#   ログメッセージコンソール出力 (例: [2026-04-01 12:00:00][INFO] メッセージ)
# Arguments:
#   $1 - ログレベル (INFO、ERROR、等)
#   $2 - メッセージ
# Returns: なし
output_log() {
  local level="$1"
  local message="$2"
  local timestamp="$(date "+%Y/%m/%d %H:%M:%S")"
  local log_msg="[${timestamp}][${level}][${SCRIPT_NAME}] ${message}"
  local esc=$'\033'
  case "${level}" in
    ERROR) echo "${esc}[31m${log_msg}${esc}[0m" >&2 ;;
    WARN)  echo "${esc}[38;5;208m${log_msg}${esc}[0m" ;;
    *)     echo "${log_msg}" ;;
  esac
}

# Description:
#   システム要件チェック (root 権限、.env・secrets.txt 存在確認)
# Arguments:
#   なし
# Returns:
#   なし
test_system_requirements() {
  # 実行ユーザー判定
  if [ "$(id -u)" -ne 0 ]; then
    output_log "ERROR" "root 権限で実行してください"
    exit 1
  fi

  # .env ファイル存在確認
  if [ ! -f "${ENV_PATH}" ]; then
    output_log "ERROR" "${ENV_PATH} が見つかりません"
    exit 1
  fi

  # secrets.txt存在確認
  if [ -z "${SECRETS_PATH}" ] || [ ! -f "${SECRETS_PATH}" ]; then
    output_log "ERROR" "secrets.txtが見つかりません (引数: ${SECRETS_PATH:-未指定})"
    exit 1
  fi
}

# Description: Ansible インストール (未インストール時のみ)
# Arguments:
#   なし
# Returns:
#   なし
install_ansible() {
  if ! command -v ansible >/dev/null 2>&1; then
    output_log "INFO" "Ansible インストール..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y ansible
  fi
}

# Description: yq インストール (未インストール時のみ)
# Arguments:
#   なし
# Returns:
#   なし
install_yq() {
  if ! command -v yq >/dev/null 2>&1; then
    output_log "INFO" "yq インストール..."
    local yq_download_url=$(grep "^YQ_DOWNLOAD_URL=" "${ENV_PATH}" | cut -d'=' -f2- | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
    yq_download_url=${yq_download_url:-"https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"}
    wget -q "${yq_download_url}" -O /usr/bin/yq
    chmod +x /usr/bin/yq
  fi
}

# Description: .env・secrets.txt → Ansible group_vars 変換
# Arguments:
#   なし
# Returns:
#   なし
convert_env_to_ansible() {
  output_log "INFO" ".env・secrets.txt → Ansible group_vars 変換..."
  mkdir -p "$(dirname "${ANSIBLE_GROUP_VARS_PATH}")"
  cat "${ENV_PATH}" <(echo) "${SECRETS_PATH}" \
    | grep -vE '^\s*#|^\s*$' \
    | sed 's/\\/\\\\/g' \
    | yq eval-all -p=props -oy 'with_entries(.key |= downcase)' - \
    > "${ANSIBLE_GROUP_VARS_PATH}"
  chmod 600 "${ANSIBLE_GROUP_VARS_PATH}"

  local ansible_dir_owner_group="$(stat -c '%U:%G' "${ANSIBLE_DIR}")"
  chown "${ansible_dir_owner_group}" "${ANSIBLE_GROUP_VARS_PATH}"
}

# Description: Ansible Playbook (site.yml) 実行
# Arguments:
#   なし
# Returns:
#   なし
run_ansible_playbook() {
  output_log "INFO" "Ansible playbook 実行..."
  cd "${ANSIBLE_DIR}" || exit 1
  ansible-playbook -i inventory site.yml
}

# Description:
#   secrets.txt 削除警告表示
# Arguments:
#   なし
# Returns:
#   なし
show_secrets_warning() {
  output_log "WARN" ""
  output_log "WARN" "secrets.txt を直ちに削除してください！"
  output_log "WARN" "平文の機密情報（パスワード・APIキー）が残っています。"
  output_log "WARN" "対象: ${SECRETS_PATH}"
  output_log "WARN" ""
}

# Description:
#   メイン処理
# Arguments:
#   なし
# Returns:
#   なし
main() {
  test_system_requirements

  output_log "INFO" "セットアップ開始..."
  install_ansible
  install_yq
  convert_env_to_ansible
  run_ansible_playbook
  output_log "INFO" "セットアップ完了"
}

main
