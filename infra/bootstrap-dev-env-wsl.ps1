<#
.SYNOPSIS
    旅行履歴・提案エージェント WSLインスタンス・開発環境構築スクリプト
.DESCRIPTION
    以下の開発環境構築処理を実行する：
    1. システム要件チェック（WSL, Docker Desktop, VS Code, VS Code Remote Development）
    2. WSL インスタンス構築
    3. WSL インスタンスプロビジョニング実行 (/infra/provision/provision-dev-env.sh)
    4. VS Code リモートセッション起動
.NOTES
    - 実行前に .env.example をコピーして .env を作成し、設定等を環境に合わせて変更すること。
    - 実行前に .env.secrets.example をコピーして .env.secrets を作成し、機密情報を設定すること。
    - 環境構築完了後、.env.secrets は直ちに削除すること。
.PARAMETER SecretsPath
    .env.secrets ファイルパス
.EXAMPLE
    .\bootstrap-dev-env-wsl.ps1 -SecretsPath C:\wsl\.env.secrets
#>
param(
  [Parameter(Mandatory = $true)]
  [string]$SecretsPath
)
$ErrorActionPreference = "Stop"
$ScriptName = $MyInvocation.MyCommand.Name

<#
.SYNOPSIS
    ログメッセージコンソール出力
.PARAMETER Level
    ログレベル文字列
.PARAMETER Message
    出力メッセージ文字列
.DESCRIPTION
    タイムスタンプとログレベルを付与してコンソールに出力する。例: [2026-04-01 12:00:00][INFO] メッセージ
#>
function Write-Log {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("INFO", "WARN", "ERROR")]
    [string]$Level,
    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string]$Message
  )
  $text = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')][$Level][$ScriptName] $Message"
  $esc = [char]27  # ANSI エスケープ（PS 5.1 では `e が使えない）
  switch ($Level) {
    "WARN"  { Write-Host "$esc[38;5;208m$text$esc[0m" }  # オレンジ
    "ERROR" { Write-Host "$esc[31m$text$esc[0m" }        # 赤
    default { Write-Host $text -ForegroundColor Gray }
  }
}

<#
.SYNOPSIS
    改行コード CRLF → LF 変換
.PARAMETER Path
    変換対象ファイルパス
.DESCRIPTION
    ファイル内の CRLF を LF に変換して上書きする。WSL 内で使用するファイル用。
    バイト単位で置換するため、文字エンコーディング (BOM 含む) は変更されない。CRLF が含まれない場合は書き込まない。
#>
function Convert-LineEndingToLf {
  param([string]$Path)
  $fullPath = (Resolve-Path $Path).Path
  $bytes = [System.IO.File]::ReadAllBytes($fullPath)
  $converted = New-Object System.Collections.Generic.List[byte] ($bytes.Length)
  for ($i = 0; $i -lt $bytes.Length; $i++) {
    if ($bytes[$i] -eq 0x0D -and ($i + 1) -lt $bytes.Length -and $bytes[$i + 1] -eq 0x0A) {
      continue
    }
    $converted.Add($bytes[$i])
  }
  if ($converted.Count -eq $bytes.Length) {
    return
  }
  Write-Log "INFO" "改行コード CRLF → LF 変換... ($fullPath)"
  [System.IO.File]::WriteAllBytes($fullPath, $converted.ToArray())
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
    Write-Log "INFO" "ファイルダウンロード開始... (${Url})"
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
    Windows パス → WSL 内マウントパス変換
.PARAMETER WindowsPath
    Windows パス
.DESCRIPTION
    Windows のパスを WSL 内でアクセス可能なマウントパスに変換する。例: C:\path\to\dir → /mnt/c/path/to/dir
    ドライブレター形式のパスのみ変換対象。UNC パス (\\server\share) は変換されず、区切り文字のみ置換して返す。
#>
function Convert-WindowsPathToWsl {
  param([string]$WindowsPath)
  $path = $WindowsPath -replace "\\", "/"
  if ($path -match "^([A-Za-z]):(?<rest>.*)") {
    $drive = $Matches[1].ToLower()
    $rest = $Matches['rest']
    return "/mnt/$drive$($rest.TrimEnd('/'))"
  }
  return $path
}

<#
.SYNOPSIS
    システム要件チェック（WSL, Docker Desktop, VS Code, VS Code Remote Development）
.DESCRIPTION
    以下のシステム要件が満たされているかチェックする：
    - WSL がインストールされていること
    - Docker Desktop がインストールされており、起動していること
    - VS Code がインストールされていること
    - VS Code Remote Development 拡張がインストールされていること
#>
function Test-SystemRequirements {
  Write-Log "INFO" "システムチェック..."

  if (!(Get-Command wsl -ErrorAction SilentlyContinue)) {
    throw "WSL が見つかりません"
  }

  if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker CLI が見つかりません"
  }

  docker info > $null 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "Docker が起動していません"
  }

  if (!(Get-Command code -ErrorAction SilentlyContinue)) {
    throw "VS Code が見つかりません"
  }

  $isInstalledRemoteExt = code --list-extensions | Select-String "ms-vscode-remote.vscode-remote-extensionpack"
  if (!$isInstalledRemoteExt) {
    throw "VS Code に拡張 (ms-vscode-remote.vscode-remote-extensionpack) がインストールされていません"
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
  param($Path = (Join-Path $PSScriptRoot "..\.env"))
  Write-Log "INFO" ".env 環境変数読み込み..."
  if (!(Test-Path $Path)) {
    throw ".env が見つかりません"
  }
  Convert-LineEndingToLf $Path

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
    .env.secrets 検証
.PARAMETER Path
    .env.secrets ファイルパス
.DESCRIPTION
    .env.secrets が存在していることを検証し、改行コードを LF に変換して絶対パスを返す。
#>
function Initialize-EnvSecrets {
  param([string]$Path)
  Write-Log "INFO" ".env.secrets 検証..."
  if (!(Test-Path $Path -PathType Leaf)) {
    throw ".env.secrets が見つかりません: $Path"
  }
  $fullPath = (Resolve-Path $Path).Path
  Convert-LineEndingToLf $fullPath
  return $fullPath
}

<#
.SYNOPSIS
    WSL インスタンス存在確認
.PARAMETER Name
    WSL インスタンス名
.DESCRIPTION
    指定した名前の WSL インスタンスが存在するかを返す。
#>
function Test-WSLInstanceExists {
  param([string]$Name)
  # wsl -l の出力は UTF-16 のため、文字化けで混入する NUL 文字を除去して比較する
  $wslList = wsl -l -q | Out-String
  $names = $wslList -replace "`0", "" -split "`r`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
  return [bool]($names -contains $Name)
}

<#
.SYNOPSIS
    WSL インスタンス構築
.DESCRIPTION
    WSL インスタンスが存在しない場合、新しいインスタンスを作成する。
#>
function Import-WSLInstance {
  if (Test-WSLInstanceExists $env:WSL_INSTANCE_NAME) {
    return
  }
  if (!(Test-Path $env:WSL_INSTANCE_PATH)) {
    New-Item -ItemType Directory -Path $env:WSL_INSTANCE_PATH | Out-Null
  }
  Get-File $env:WSL_DISTRO_IMAGE_URL $env:WSL_DISTRO_IMAGE_PATH

  Write-Log "INFO" "WSL インスタンス作成... (${env:WSL_INSTANCE_NAME})"
  wsl --import $env:WSL_INSTANCE_NAME $env:WSL_INSTANCE_PATH $env:WSL_DISTRO_IMAGE_PATH
  if ($LASTEXITCODE -ne 0) {
    throw "WSL インスタンス作成失敗"
  }
  wsl --set-default $env:WSL_INSTANCE_NAME
  if ($LASTEXITCODE -ne 0) {
    throw "WSL インスタンス既定設定失敗"
  }
}

<#
.SYNOPSIS
    WSL インスタンスプロビジョニング実行 (./provision-dev-env.sh)
.PARAMETER SecretsFullPath
    .env.secrets ファイル絶対パス
#>
function Invoke-ProvisionScript {
  param([string]$SecretsFullPath)
  Write-Log "INFO" "WSL インスタンスプロビジョニング実行..."
  $scriptWslPath = Convert-WindowsPathToWsl (Join-Path $PSScriptRoot "provision/provision-dev-env.sh")
  $secretsWslPath = Convert-WindowsPathToWsl $SecretsFullPath
  wsl -d $env:WSL_INSTANCE_NAME -u root -- bash "$scriptWslPath" "$secretsWslPath"
  if ($LASTEXITCODE -ne 0) {
    throw "WSL インスタンスプロビジョニング実行失敗"
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
  Write-Log "INFO" "WSL インスタンス停止... (${env:WSL_INSTANCE_NAME})"
  wsl --terminate $env:WSL_INSTANCE_NAME
  if ($LASTEXITCODE -ne 0) {
    Write-Log "WARN" "WSL インスタンス停止失敗。処理続行..."
  }
}

<#
.SYNOPSIS
    VS Code リモートセッション起動
.DESCRIPTION
    VS Code を起動し、WSL インスタンスとのリモートセッションを開始する。
#>
function Start-VSCode {
  Write-Log "INFO" "VS Code起動..."
  $targetWorkspace = "/home/$($env:APP_USER_NAME)/$($env:GIT_REPO_NAME)/travel-agent-lab.code-workspace"
  code --remote wsl+$($env:WSL_INSTANCE_NAME) $targetWorkspace
}

<#
.SYNOPSIS
    .env.secrets 削除警告表示
.PARAMETER Path
    .env.secrets ファイルパス
.DESCRIPTION
    .env.secrets の即時削除を強調して警告表示する。
#>
function Show-SecretsWarning {
  param([string]$Path)
  Write-Log "WARN" ""
  Write-Log "WARN" ".env.secrets を直ちに削除してください！"
  Write-Log "WARN" "平文の機密情報（パスワード・APIキー）が残っています。"
  Write-Log "WARN" "対象: $Path"
  Write-Log "WARN" ""
}

# メイン処理
$secretsFullPath = $null
try {
  Write-Log "INFO" "セットアップ開始..."

  Set-Location $PSScriptRoot
  Read-Env
  $secretsFullPath = Initialize-EnvSecrets $SecretsPath
  Test-SystemRequirements
  Import-WSLInstance
  Invoke-ProvisionScript $secretsFullPath
  Stop-WSLInstance
  Start-VSCode

  Write-Log "INFO" "セットアップ完了"
} catch {
  Write-Log "ERROR" $_.Exception.Message
  exit 1
} finally {
  if ($secretsFullPath) {
    Show-SecretsWarning $secretsFullPath
  }
}
