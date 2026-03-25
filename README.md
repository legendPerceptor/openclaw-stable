# OpenClaw Stable 镜像

解决配置更新时容器退出的问题，并自动修复权限问题。

## 前置依赖：Xray 代理容器

OpenClaw 需要通过代理访问外网，先启动 xray (其中GLM模型和飞书采用no_proxy直连的方式)：

```bash
# 创建 xray 配置目录
mkdir -p /volume1/docker/xray

# 创建配置文件（填入你的代理信息）
cat > /volume1/docker/xray/config.json << 'EOF'
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": 1087,
      "listen": "0.0.0.0",
      "protocol": "http",
      "settings": { "udp": true },
      "tag": "http-in"
    }
  ],
  "outbounds": [
    {
      "protocol": "vmess",
      "settings": {
        "vnext": [{
          "address": "YOUR_SERVER_ADDRESS",
          "port": YOUR_PORT,
          "users": [{
            "id": "YOUR_UUID",
            "alterId": 0,
            "security": "auto"
          }]
        }]
      },
      "tag": "proxy"
    },
    { "protocol": "freedom", "settings": {}, "tag": "direct" }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      { "type": "field", "ip": ["geoip:private"], "outboundTag": "direct" }
    ]
  }
}
EOF

# 启动 xray 容器
docker run -d \
  --name xray \
  --restart always \
  --network proxy-net \
  -v /volume1/docker/xray/config.json:/etc/xray/config.json:ro \
  teddysun/xray
```

## 构建 OpenClaw Stable 镜像

在 NAS 上执行：

```bash
cd /path/to/openclaw-stable
docker build -t openclaw-stable .
```

## 启动 OpenClaw 容器

```bash
# 停止并删除旧容器
docker stop 1panel_openclaw-1 2>/dev/null
docker rm 1panel_openclaw-1 2>/dev/null

# 启动新容器（确保 xray 已先启动）
docker run -d \
  --name openclaw \
  --restart always \
  --network proxy-net \
  -v /volume1/shared-shanghai/openclaw-workhome/1panel-claw:/home/node/.openclaw \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /usr/bin/docker:/usr/bin/docker \
  -v /var/log/openclaw:/var/log/supervisor \
  -v /home/briannas/.ssh:/home/node/.ssh \
  -e HTTP_PROXY=http://xray:1087 \
  -e HTTPS_PROXY=http://xray:1087 \
  -e NO_PROXY=localhost,127.0.0.1,*.feishu.cn,*.larksuite.com,*.zhipuai.cn,bigmodel.cn,open.bigmodel.cn, api.search.brave.com, api.minimaxi.com \
  openclaw-stable
```

## 变更说明

- 使用 **supervisord** 作为 PID 1 管理 openclaw gateway
- gateway 重启时 supervisord 自动拉起，容器不退出
- 挂载 `/var/run/docker.sock` 让 OpenClaw 可以管理 Docker
- 日志存储在 `/var/log/supervisor/`
- **自动修复权限**：启动时将 root 拥有的文件改为 node 用户

## 查看日志

```bash
# supervisord 日志
docker exec openclaw cat /var/log/supervisor/supervisord.log

# openclaw 日志
docker exec openclaw cat /var/log/supervisor/openclaw.log
```
