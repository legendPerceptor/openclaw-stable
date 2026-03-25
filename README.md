# OpenClaw Stable 镜像

解决配置更新时容器退出的问题，并自动修复权限问题。

## 一键配置

复制.env.example为.env文件，修改所需的环境变量。默认的Dockerfile中会安装一些额外的包以便openclaw可以在容器中做比较复杂的任务，比如视频生成、语音合成等等。我已经将pip和apt的源都换为国内源，安装所需时间应该在几分钟之内。如果不希望安装这些包，可以把docker-compose.yml中的Dockerfile改成Dockerfile.basic，也可以让你开始快速使用OpenClaw。

创建xray文件夹，并在其中配置config.json文件，具体如何配置见后文。

配置完成后可以用下面的命令一键启动openclaw。

```bash
docker compose up -d
```

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
docker build -t openclaw-stable . -f Dockerfile.basic
```

## 启动 OpenClaw 容器

```bash
# 停止并删除旧容器
docker container stop openclaw && docker container rm openclaw

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

---

## akali-video 分支 🎬

为 **The Akali YouTube Project** 扩展的视频制作专用镜像。

### 额外安装的软件

| 软件                 | 用途                    |
| -------------------- | ----------------------- |
| **ffmpeg**           | 视频处理、格式转换      |
| **Python3 + pip**    | 脚本执行、Markdown 处理 |
| **Chromium**         | Puppeteer 截图（备选）  |
| **ImageMagick**      | 图片转换处理            |
| **fonts-wqy-zenhei** | 中文字体支持            |
| **jq**               | JSON 处理               |

### Python 包

- `markdown` - Markdown 解析
- `pyyaml` - YAML 处理
- `Pillow` - 图片处理
- `requests` - HTTP 请求

### 使用 akali-video 镜像 (当前为默认Dockerfile)

```bash
# 构建镜像
docker container stop openclaw && docker container rm openclaw
docker build -t openclaw-stable:akali-video .

# 启动容器（同上，只需改镜像名）
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
  -e NO_PROXY=localhost,127.0.0.1,*.feishu.cn,*.larksuite.com,*.zhipuai.cn,bigmodel.cn,open.bigmodel.cn,api.search.brave.com,api.minimaxi.com \
  openclaw-stable:akali-video
```

### 验证安装

```bash
docker exec openclaw ffmpeg -version
docker exec openclaw python3 --version
docker exec openclaw pip3 list
```

## 查看日志

```bash
# supervisord 日志
docker exec openclaw cat /var/log/supervisor/supervisord.log

# openclaw 日志
docker exec openclaw cat /var/log/supervisor/openclaw.log
```
