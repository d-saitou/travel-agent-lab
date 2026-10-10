ARG BACKEND_PYTHON_IMAGE=3.14-slim-trixie
ARG BACKEND_UV_VERSION=latest
ARG APP_UID=9999
ARG APP_GID=9999
ARG APP_USER_NAME=appuser
ARG APP_GROUP_NAME=appgroup

# ========================================
# uvイメージ指定
# ========================================
FROM ghcr.io/astral-sh/uv:${BACKEND_UV_VERSION} AS uv

# ========================================
# 基礎環境構築ステージ
# ========================================
FROM python:${BACKEND_PYTHON_IMAGE} AS base

ARG APP_UID
ARG APP_GID
ARG APP_USER_NAME
ARG APP_GROUP_NAME

# Python環境設定
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app/backend \
    UV_PROJECT_ENVIRONMENT=/app/backend/.venv

# uvコピー
COPY --from=uv /uv /uvx /bin/

# ユーザー作成
RUN groupadd --gid ${APP_GID} ${APP_GROUP_NAME} && \
    useradd --uid ${APP_UID} --gid ${APP_GID} --create-home --shell /bin/bash ${APP_USER_NAME}

# アプリケーションディレクトリ作成
RUN mkdir -p /app/backend/.venv && \
    chown -R ${APP_UID}:${APP_GID} /app

USER ${APP_USER_NAME}

WORKDIR /app/backend

# ========================================
# 開発環境構築ステージ
# ========================================
FROM base AS development

USER root

# 開発用パッケージインストール
RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*

# アプリケーションファイルコピー
COPY --chown=${APP_UID}:${APP_GID} ./pyproject.toml ./uv.lock ./README.md ./
COPY --chown=${APP_UID}:${APP_GID} ./src/ ./src/

USER ${APP_USER_NAME}

# 依存関係インストール
RUN uv sync --frozen

CMD ["uv", "run", "python", "-m", "debugpy", "--listen", "0.0.0.0:5678", "-m", "uvicorn", "server.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
