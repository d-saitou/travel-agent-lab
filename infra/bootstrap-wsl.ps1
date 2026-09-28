<#
.SYNOPSIS
    旅行記録・提案エージェント 開発環境構築スクリプト（WSL＋開発環境）
.DESCRIPTION
    以下の開発環境構築処理を実行する：
    1. システム要件チェック（WSL）
    2. WSL インスタンス構築
.NOTES
    - 実行前に プロジェクトルート/.env ファイルを作成し、ユーザー情報等を環境に合わせて変更すること。
#>
$ErrorActionPreference = "Stop"
$ScriptName = $MyInvocation.MyCommand.Name

<#
.SYNOPSIS
    ログメッセージコンソール出力
.PARAMETER Message
    出力メッセージ文字列
.PARAMETER Level
    ログレベル文字列
.DESCRIPTION
    タイムスタンプとログレベルを付与してコンソールに出力する。例: [2026-04-01 12:00:00][INFO] メッセージ
#>
function Write-Log {
  param(
    [string]$Message,
    [string]$Level = "INFO"
  )
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Write-Host "[$ts][$Level][$ScriptName] $Message"
}

<#
.SYNOPSIS
    ファイルダウンロード
.PARAMETER Url
    ダウンロード URL
.PARAMETER Path
    保存先パス
.DESCRIPTION
    指定URLからファイルをダウンロードし、指定パスに保存する。既にファイルが存在する場合はダウンロードをスキップする。
#>
function Get-File {
  param([string]$Url, [string]$Path)
  if (!(Test-Path $Path)) {
    Write-Log "ファイルダウンロード開始... (${Url})"
    try {
      # Import-Module BitsTransfer
      # Start-BitsTransfer -Source $Url -Destination $Path -Priority Foreground -RetryTimeout 60 -RetryInterval 60 -ErrorAction Stop
      Invoke-WebRequest -Uri $Url -OutFile $Path
    } catch {
      if (Test-Path $Path) {
        Remove-Item $Path -Force
      }
      throw "ダウンロード失敗: $($_.Exception.Message)"
    }
  }
}

<#
.SYNOPSIS
    システム要件チェック（WSL, Docker Desktop, VS Code, VS Code Remote Development）
.DESCRIPTION
    以下のシステム要件が満たされているかチェックする：
    - WSL がインストールされていること
    - VS Code がインストールされていること
    - VS Code Remote Development 拡張がインストールされていること
#>
function Test-SystemRequirements {
  Write-Log "システムチェック..."

  if (!(Get-Command wsl -ErrorAction SilentlyContinue)) {
    throw "WSL が見つかりません"
  }

}

<#
.SYNOPSIS
    .env 環境変数読み込み
.PARAMETER Path
    .env ファイルパス
.DESCRIPTION
    指定された .env ファイルから環境変数を読み込み、PowerShell の環境変数として設定する。
#>
function Read-Env {
  param($Path = "..\.env")
  Write-Log ".env 環境変数読み込み..."
  if (!(Test-Path $Path)) {
    throw ".env が見つかりません"
  }

  Get-Content $Path | ForEach-Object {
    if ($_ -match "^\s*#") { return }
    if ($_ -match "^\s*$") { return }
    if ($_ -notmatch "=") { return }
    $key, $value = $_ -split "=", 2
    $key = $key.Trim()
    $value = $value.Trim().Trim("'").Trim('"')
    if ($key) {
      [System.Environment]::SetEnvironmentVariable($key, $value)
    }
  }
}

<#
.SYNOPSIS
    WSL インスタンス構築
.DESCRIPTION
    WSL インスタンスが存在しない場合、新しいインスタンスを作成する。
#>
function Import-WSLInstance {
  # $exists = wsl -l -q | ForEach-Object { $_.Trim() } | Where-Object { $_ -eq $env:WSL_INSTANCE_NAME }
  $wslList = wsl -l -q | Out-String
  $exists = $wslList -replace "`0", "" -split "`r`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" -and $_ -eq $env:WSL_INSTANCE_NAME }
  if ($exists) {
    return
  }
  if (!(Test-Path $env:WSL_INSTANCE_PATH)) {
    New-Item -ItemType Directory -Path $env:WSL_INSTANCE_PATH | Out-Null
  }
  Get-File $env:WSL_DISTRO_IMAGE_URL $env:WSL_DISTRO_IMAGE_PATH

  Write-Log "WSL インスタンス作成... (${env:WSL_INSTANCE_NAME})"
  wsl --import $env:WSL_INSTANCE_NAME $env:WSL_INSTANCE_PATH $env:WSL_DISTRO_IMAGE_PATH
  if ($LASTEXITCODE -ne 0) {
    throw "WSL インスタンス作成失敗"
  }
  wsl --set-default $env:WSL_INSTANCE_NAME
  if ($LASTEXITCODE -ne 0) {
    throw "WSL インスタンス規定設定失敗"
  }
}

<#
.SYNOPSIS
    WSL インスタンス停止
.DESCRIPTION
    WSL インスタンスを停止する。
    設定変更後にインスタンスの状態をリセットするために使用する。
#>
function Stop-WSLInstance {
  Write-Log "WSL インスタンス停止... (${env:WSL_INSTANCE_NAME})"
  wsl --terminate $env:WSL_INSTANCE_NAME
  if ($LASTEXITCODE -ne 0) {
    Write-Log "WSL インスタンス停止失敗。処理続行..." "WARN"
  }
}

# メイン処理
try {
  Write-Log "セットアップ開始..."

  Set-Location $PSScriptRoot
  Read-Env
  Test-SystemRequirements
  Import-WSLInstance
  Stop-WSLInstance

  Write-Log "セットアップ完了"
} catch {
  Write-Log $_.Exception.Message "ERROR"
  exit 1
}
