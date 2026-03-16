#!/bin/bash
set -e

# 修复挂载目录的权限问题
# 将 root 拥有的文件改为 node 用户
if [ -d "/home/node/.openclaw" ]; then
    # 修复 root 拥有的文件和目录
    find /home/node/.openclaw -type d -user 0 -exec chown node:node {} \; 2>/dev/null || true
    find /home/node/.openclaw -type f -user 0 -exec chown node:node {} \; 2>/dev/null || true
    
    # 修复 group 权限（SMB 挂载可能导致 gid=10）
    find /home/node/.openclaw -type d -group 0 -exec chgrp node {} \; 2>/dev/null || true
    find /home/node/.openclaw -type f -group 0 -exec chgrp node {} \; 2>/dev/null || true
    find /home/node/.openclaw -type d -group 10 -exec chgrp node {} \; 2>/dev/null || true
    find /home/node/.openclaw -type f -group 10 -exec chgrp node {} \; 2>/dev/null || true
fi

# 执行传入的命令
exec "$@"
