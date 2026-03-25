FROM 1panel/openclaw

USER root

# ============================================
# The Akali YouTube Project - 视频制作工具
# ============================================

RUN if [ -f /etc/apt/sources.list ]; then \
      sed -i 's|http://deb.debian.org/debian|https://mirrors.tuna.tsinghua.edu.cn/debian|g' /etc/apt/sources.list && \
      sed -i 's|http://security.debian.org/debian-security|https://mirrors.tuna.tsinghua.edu.cn/debian-security|g' /etc/apt/sources.list; \
    elif [ -f /etc/apt/sources.list.d/debian.sources ]; then \
      sed -i 's|http://deb.debian.org/debian|https://mirrors.tuna.tsinghua.edu.cn/debian|g' /etc/apt/sources.list.d/debian.sources && \
      sed -i 's|http://security.debian.org/debian-security|https://mirrors.tuna.tsinghua.edu.cn/debian-security|g' /etc/apt/sources.list.d/debian.sources; \
    else \
      echo "No known APT source file found" && exit 1; \
    fi && \
    apt-get update

# 安装核心依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    # 系统管理
    supervisor \
    # Python 环境（用于各种脚本）
    python3 \
    python3-pip \
    python3-venv \
    # 视频处理（完整版 ffmpeg）
    ffmpeg \
    # Chromium 浏览器（用于 Puppeteer 截图）
    chromium \
    chromium-driver \
    # 字体支持（中文显示）
    fonts-wqy-zenhei \
    fonts-wqy-microhei \
    # 图片处理
    imagemagick \
    # 其他实用工具
    curl \
    wget \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 安装 Python 包（用于视频脚本）
RUN pip3 install --no-cache-dir --break-system-packages \
    # Markdown 处理
    markdown \
    pyyaml \
    # 图片处理
    Pillow \
    # 其他实用库
    requests

# 创建 docker 组（GID 121 匹配宿主机）并添加 node 用户
RUN groupadd -g 121 docker && \
    usermod -aG docker node

# 确保 Puppeteer 缓存目录存在且可写
RUN mkdir -p /home/node/.cache/puppeteer && \
    chown -R node:node /home/node/.cache

# 确保 /home/node/.openclaw 目录权限正确
RUN mkdir -p /home/node/.openclaw && \
    chown -R node:node /home/node/.openclaw

# 创建日志目录
RUN mkdir -p /var/log/supervisor

COPY supervisord.conf /etc/supervisor/conf.d/openclaw.conf

# 启动时修复权限，然后启动 supervisord
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
