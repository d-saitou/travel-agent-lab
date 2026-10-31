# ディレクトリ・ファイル構成

## 1. 構成

```text
travel-agent-lab/                  # リポジトリルート
 ├ .vscode/                        # VS Codeフォルダー設定（launch.json、tasks.json等）
 ├ backend/                        # バックエンドアプリケーション
 │  ├ .devcontainer/               # Dev Container定義（バックエンド）
 │  └ ...                          # 内部構成は「ディレクトリ・ファイル構成（バックエンド）」で定義 ※TBD
 ├ data/                           # 永続化データ（DBバックアップ等） ※Git管理対象外
 ├ docs/                           # ドキュメント
 │  └ design/                      # 設計ドキュメント
 ├ frontend/                       # フロントエンドアプリケーション
 │  ├ .devcontainer/               # Dev Container定義（フロントエンド）
 │  └ ...                          # 内部構成は「ディレクトリ・ファイル構成（フロントエンド）」で定義 ※TBD
 ├ infra/                          # インフラ構成・開発環境構築
 │  ├ container/                   # コンテナ定義（Dockerfile、マウント用ファイル等）
 │  │  ├ backend/                  # コンテナ定義（バックエンド）
 │  │  ├ db/                       # コンテナ定義（データベース）
 │  │  ├ frontend/                 # コンテナ定義（フロントエンド）
 │  │  └ llmproxy/                 # コンテナ定義（LLMプロキシ）
 │  ├ provision/                   # 開発環境構成管理
 │  │  ├ ansible/                  # Ansible定義（プレイブック等）
 │  │  └ provision-dev-env.sh      # 開発環境プロビジョニングスクリプト ※WSL 2内で実行
 │  ├ scripts/                     # 開発作業用スクリプト
 │  └ bootstrap-wsl.ps1            # WSL 2セットアップ・開発環境構築スクリプト ※Windows側で実行
 ├ .env                            # 環境変数定義 ※Git管理対象外
 ├ .env.example                    # 環境変数定義テンプレート
 ├ .gitignore                      # Git管理対象外ファイル定義
 ├ compose.devcontainer.yaml       # Composeファイル（Dev Container用の上書き設定）
 ├ compose.yaml                    # Composeファイル（全コンテナの定義）
 ├ LICENSE                         # ライセンス
 ├ README.md                       # プロジェクト概要
 └ travel-agent-lab.code-workspace # VS Codeワークスペース定義（Dev Host：WSL 2）
```

## 2. ディレクトリ・ファイル構成変更ルール

- フロントエンドの実装とバックエンドの実装を相互に混在させない。
- インフラ設定とアプリケーションの業務ロジックを分離する。
- 新規ファイルは、そのファイルが担う主な責務に対応するディレクトリに配置する。
- 既存の構成で適切な配置先がない場合は、ディレクトリを新設する前に既存の責務との重複を確認する。
- ディレクトリの新設・移動・削除、または責務の変更を行った場合は、本ドキュメントを更新する。
- 本ドキュメントと実際のリポジトリ構成に差異がある場合は、原因を確認し、意図した変更であれば本ドキュメントを、意図しない変更であればリポジトリ構成を修正する。
