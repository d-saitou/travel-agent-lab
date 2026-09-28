# 変数定義(デフォルト値) ※参照：https://hub.docker.com/r/pgvector/pgvector/tags
ARG DB_PGVECTOR_IMAGE=0.8.6-pg18-trixie

# イメージ指定
FROM pgvector/pgvector:${DB_PGVECTOR_IMAGE}

# ロケールインストール
RUN apt-get update && \
    apt-get install -y locales && \
    localedef -i ja_JP -c -f UTF-8 -A /usr/share/locale/locale.alias ja_JP.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

# 環境変数ロケール指定
ENV LANG ja_JP.UTF-8
ENV LC_ALL ja_JP.UTF-8
