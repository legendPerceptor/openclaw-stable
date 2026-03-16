FROM 1panel/openclaw

USER root

# 只安装 supervisord，docker CLI 从宿主机映射
RUN apt-get update && apt-get install -y --no-install-recommends \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/supervisor

COPY supervisord.conf /etc/supervisor/conf.d/openclaw.conf

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
