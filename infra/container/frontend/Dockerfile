ARG FRONTEND_NODE_IMAGE=26-bookworm-slim
ARG APP_UID=9999
ARG APP_GID=9999
ARG APP_USER_NAME=appuser
ARG APP_GROUP_NAME=appgroup

# ========================================
# 基礎環境構築ステージ
# ========================================
FROM node:${FRONTEND_NODE_IMAGE} AS base

ARG APP_UID
ARG APP_GID
ARG APP_USER_NAME
ARG APP_GROUP_NAME

# ユーザー作成
RUN groupadd --gid ${APP_GID} ${APP_GROUP_NAME} && \
    useradd --uid ${APP_UID} --gid ${APP_GID} --create-home --shell /bin/bash ${APP_USER_NAME}

# アプリケーションディレクトリ作成
RUN mkdir -p /app/frontend/.next && \
    chown -R ${APP_UID}:${APP_GID} /app

USER ${APP_USER_NAME}

WORKDIR /app/frontend

# ========================================
# 依存関係インストールステージ
# ========================================
FROM base AS deps

COPY --chown=${APP_UID}:${APP_GID} ./package*.json ./

RUN npm ci

# ========================================
# 開発環境構築ステージ
# ========================================
FROM deps AS development

ENV NODE_ENV=development \
    CHOKIDAR_USEPOLLING=true \
    WATCHPACK_POLLING=true \
    PORT=3000

USER root

# 開発用パッケージインストール
RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*

USER ${APP_USER_NAME}

EXPOSE 3000 9229

CMD ["npm", "run", "dev", "--", "--hostname", "0.0.0.0", "--inspect=0.0.0.0:9229"]
