FROM 1panel/openclaw

USER root

# 安装 supervisord
RUN apt-get update && apt-get install -y --no-install-recommends \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# 创建 docker 组（GID 121 匹配宿主机）并添加 node 用户
RUN groupadd -g 121 docker && \
    usermod -aG docker node

# 确保 /home/node/.openclaw 目录权限正确
RUN mkdir -p /home/node/.openclaw && \
    chown -R node:node /home/node/.openclaw

RUN mkdir -p /var/log/supervisor

COPY supervisord.conf /etc/supervisor/conf.d/openclaw.conf

# 启动时修复权限，然后启动 supervisord
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
