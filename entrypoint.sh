#!/bin/bash
set -e

# 修复挂载目录的权限问题
# 将 root 拥有的文件改为 node 用户
if [ -d "/home/node/.openclaw" ]; then
    # 只修复 .git 目录和其他 root 拥有的文件
    find /home/node/.openclaw -type d -user 0 -exec chown node:node {} \; 2>/dev/null || true
    find /home/node/.openclaw -type f -user 0 -exec chown node:node {} \; 2>/dev/null || true
fi

# 执行传入的命令
exec "$@"
