#!/bin/bash
# Name:
#   Linux / WSL 判定スクリプト
# Description:
#   Linux か WSL かを判定して出力する
# Usage:
#   ./detect-linux-or-wsl.sh
set -euo pipefail

if grep -qiE '(microsoft|wsl)' /proc/sys/kernel/osrelease ||
   grep -qiE '(microsoft|wsl)' /proc/version ||
   [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    echo "wsl"
else
    echo "linux"
fi
