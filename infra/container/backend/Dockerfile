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

# uvコピー
COPY --from=uv /uv /uvx /bin/

# ユーザー作成
RUN groupadd --gid ${APP_GID} ${APP_GROUP_NAME} && \
    useradd --uid ${APP_UID} --gid ${APP_GID} --create-home --shell /bin/bash ${APP_USER_NAME}

USER ${APP_USER_NAME}

WORKDIR /app

# ========================================
# 開発環境構築ステージ
# ========================================
FROM base AS development

USER root

# 開発用パッケージインストール
RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*

USER ${APP_USER_NAME}

CMD ["bash"]
