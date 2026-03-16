FROM 1panel/openclaw

USER root

# 安装 supervisord
RUN apt-get update && apt-get install -y --no-install-recommends \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# 创建 docker 组（GID 121 匹配宿主机）并添加 node 用户
RUN groupadd -g 121 docker && \
    usermod -aG docker node

RUN mkdir -p /var/log/supervisor

COPY supervisord.conf /etc/supervisor/conf.d/openclaw.conf

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
