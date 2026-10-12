# ========================================
# ビルド引数定義
# ========================================
ARG LLMPROXY_PYTHON_IMAGE=3.14-slim-trixie
ARG LLMPROXY_LITELLM_VERSION=1.105.0
ARG APP_UID=9999
ARG APP_GID=9999
ARG APP_USER_NAME=appuser
ARG APP_GROUP_NAME=appgroup

# ========================================
# 開発環境コンテナ
# ========================================
FROM python:${LLMPROXY_PYTHON_IMAGE}

ARG LLMPROXY_LITELLM_VERSION
ARG APP_UID
ARG APP_GID
ARG APP_USER_NAME
ARG APP_GROUP_NAME

# Python環境設定
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# 必要パッケージインストール
RUN apt-get update && \
    apt-get install -y --no-install-recommends tini && \
    rm -rf /var/lib/apt/lists/*

# litellmインストール
RUN pip install --upgrade pip && \
    pip install "litellm[proxy]==${LLMPROXY_LITELLM_VERSION}"

# ユーザー作成
RUN groupadd -g ${APP_GID} ${APP_GROUP_NAME} && \
    useradd --uid ${APP_UID} --gid ${APP_GID} --create-home --shell /bin/bash ${APP_USER_NAME}

# アプリケーションディレクトリ作成
RUN mkdir -p /app && \
    chown -R ${APP_UID}:${APP_GID} /app

# エントリーポイントスクリプトコピー
COPY ./scripts/entrypoint.sh /usr/local/bin/entrypoint.sh

# エントリーポイントスクリプト権限設定
RUN chown ${APP_UID}:${APP_GID} /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

USER ${APP_USER_NAME}

WORKDIR /app

EXPOSE 4000

ENTRYPOINT ["tini", "-g", "--", "/usr/local/bin/entrypoint.sh"]
