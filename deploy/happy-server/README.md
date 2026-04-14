# Happy Server Docker 部署

这套方案参考的是 `slopus/happy` 主仓库当前推荐的自部署思路：

- 上游新版优先推荐 `Happy Server` 单容器启动。
- 默认是 `PGlite + 本地文件存储 + 无 Redis` 的最小依赖模式。
- 你的场景需要复用已有 `Postgres`，所以这里保留单容器形态，但把数据库切到外部 `DATABASE_URL`，同时继续使用本地卷保存上传文件。

上游参考：

- `https://github.com/slopus/happy/tree/main/packages/happy-server`
- `https://github.com/slopus/happy/blob/main/packages/happy-server/README.md`

## 目录说明

- `build.sh`: 本地构建并导出镜像（推荐方式）
- `Dockerfile`: 从上游仓库构建镜像（需 GitHub 访问）
- `docker-compose.yml`: 服务器直接构建时使用的 compose 文件
- `docker-compose.server.yml`: 加载预构建镜像时使用的 compose 文件（推荐）
- `docker-entrypoint.sh`: 启动前自动做数据库迁移
- `.env.example`: 环境变量模板
- `nginx/happy-server.conf.example`: 反向代理示例

## 为什么这样改

上游单容器镜像里的 `standalone.ts migrate` 主要服务于内置 `PGlite`。当你改用已有 PostgreSQL 时，直接照搬它的默认启动命令会漏掉外部数据库迁移，所以这里在入口脚本里做了分流：

- 设置了 `DATABASE_URL`: 启动前执行 `prisma migrate deploy`
- 设置了 `DATABASE_URL`: 同时清掉 `PGLITE_DIR`，避免运行时误切回内置 PGlite
- 没设置 `DATABASE_URL`: 回退到上游默认的 `PGlite` 迁移逻辑

另外，这里的源码阶段现在会优先下载 GitHub 的源码压缩包，而不是在容器里直接 `git fetch` 某个 commit SHA。这样在网络较慢、代理较严格，或 Docker 内 `git` 对 commit ref 支持不稳定的环境里更稳。

当前默认的 `HAPPY_UPSTREAM_REPO` 已经切到了带 GitHub 镜像前缀的地址：

- `https://gh-proxy.com/https://github.com/slopus/happy.git`

Dockerfile 也会自动识别这类”镜像前缀 + GitHub 仓库”的 URL，并继续优先下载对应的 archive 包，所以后续只改 `HAPPY_UPSTREAM_REF` 也能继续走镜像。

源码下载阶段内置了多个 GitHub 镜像的自动 fallback（按顺序尝试）：

1. `gh-proxy.com`（默认，实测稳定）
2. `gh.ddlc.top`（备用）
3. `ghproxy.net`（备用）

三个镜像全部失败时，构建会报错并提示通过 `HAPPY_ARCHIVE_URL` 指定自托管源码包。

为了适配国内服务器，构建阶段还额外做了三件事：

- Node 基础镜像默认走 `DaoCloud` 公共镜像前缀，避免直接命中 `registry-1.docker.io`
- `apt` 默认切到清华 Debian 镜像，并开启重试，减少 `apt-get update` 卡死
- `yarn/npm` 默认切到 `npmmirror`，避免安装 Node 依赖时访问官方 npm 慢或超时

如果你之前的 `.env` 里还残留 `hub.fastgit.xyz`，新 Dockerfile 也会在构建时自动改写到 `gh-proxy + github.com`，避免继续走已经不稳定的旧地址。

## 快速开始（推荐：本地构建 + 导出）

在国内服务器直接构建会因无法访问 GitHub 而失败。推荐方案：**在本地（可访问 GitHub 的机器）构建镜像，导出后传输到服务器**，服务器完全不需要访问任何国外资源。

### 第一步：本地构建并导出

在能访问 GitHub 的机器上（如你的 Mac）：

```bash
cd /Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter/deploy/happy-server

# 构建并导出镜像
./build.sh --export
```

这会生成 `happy-server-image.tar.gz`（约 300-500MB）。

### 第二步：传输到服务器

```bash
scp happy-server-image.tar.gz \
    docker-compose.server.yml \
    .env.example \
    user@your-server:/opt/happy-server/
```

### 第三步：服务器上启动

```bash
ssh user@your-server
cd /opt/happy-server

# 加载镜像（纯本地操作，不需要网络）
docker load -i happy-server-image.tar.gz

# 配置环境变量
cp .env.example .env
vim .env
```

`.env` 中只需要设置这两个必填项：

```bash
HAPPY_PUBLIC_URL=https://happy.your-domain.com
HANDY_MASTER_SECRET=replace-with-a-long-random-secret
```

> `DATABASE_URL` 留空即可，默认使用内嵌 PGlite（零外部依赖）。如果需要外部 PostgreSQL，再填写。

启动：

```bash
docker compose -f docker-compose.server.yml up -d
```

### 第四步：验证

```bash
# 查看日志
docker compose -f docker-compose.server.yml logs -f happy-server

# 健康检查
curl http://127.0.0.1:3005/health
```

---

## 快速开始（备选：服务器直接构建）

如果服务器可以访问国内镜像（DaoCloud、清华、npmmirror），也可以直接在服务器上构建：

```bash
cp .env.example .env
vim .env  # 设置 HAPPY_PUBLIC_URL, HANDY_MASTER_SECRET

docker compose build
docker compose up -d
```

所有网络依赖均指向国内可达的镜像源：

| 资源 | 默认镜像 |
|---|---|
| Docker 基础镜像 | `m.daocloud.io`（DaoCloud，可换成 `docker.1ms.run`） |
| apt 系统包 | `mirrors.tuna.tsinghua.edu.cn`（清华） |
| npm 包 | `registry.npmmirror.com`（阿里） |
| GitHub 源码 | `gh-proxy.com` → `gh.ddlc.top` → `ghproxy.net`（自动 fallback） |

默认已走国内友好镜像源。如需切换：

```bash
# 切回官方源（服务器可直连国际网络时）
HAPPY_NODE_IMAGE=node:20
HAPPY_NODE_SLIM_IMAGE=node:20-slim
HAPPY_NPM_REGISTRY=https://registry.npmjs.org
HAPPY_APT_MIRROR=
HAPPY_APT_SECURITY_MIRROR=

# 指定源码 archive 镜像
HAPPY_UPSTREAM_ARCHIVE_URL=https://your-mirror.example.com/happy.tar.gz

# 或切回 GitHub 官方仓库
HAPPY_UPSTREAM_REPO=https://github.com/slopus/happy.git
```

刷新基础镜像：

```bash
docker compose build --pull
```

## 国内服务器常见报错

### 0. `All GitHub mirrors failed`

源码下载阶段尝试了所有内置镜像（`gh-proxy.com`、`gh.ddlc.top`、`ghproxy.net`）但全部失败。解决办法：

1. 在 `.env` 里设置 `HAPPY_ARCHIVE_URL` 指向你自托管的源码包
2. 或使用推荐的"本地构建 + 导出"方案，完全绕过服务器网络

### 1. `hub.fastgit.xyz ... Couldn't connect to server`

这通常说明服务器还在用旧版 `Dockerfile` 或旧版 `.env`。新版部署目录已经把默认仓库切到了：

- `https://gh-proxy.com/https://github.com/slopus/happy.git`

并且会自动把旧的 `hub.fastgit.xyz/...` 改写成新的 GitHub 镜像地址。最稳妥的做法还是把当前目录的最新 `Dockerfile`、`docker-compose.yml`、`.env.example` 同步到服务器后再重建。

### 2. `Get "https://registry-1.docker.io/v2/" ... Client.Timeout exceeded`

这说明基础镜像仍然在尝试直接访问 Docker Hub。新版默认会改为：

- `m.daocloud.io/docker.io/library/node:20`
- `m.daocloud.io/docker.io/library/node:20-slim`

如果你的服务器日志里仍然显示 `docker.io/library/node:*`，先检查是否同步了最新 `docker-compose.yml`，以及 `.env` 里有没有把 `HAPPY_NODE_IMAGE` 覆盖回官方地址。

如果宿主机层面的 Docker 拉取依然很慢，可以再额外给 Docker daemon 配一层镜像：

```bash
cat >/etc/docker/daemon.json <<'EOF'
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.m.daocloud.io"
  ]
}
EOF
systemctl restart docker
```

或者在 `.env` 里直接切换基础镜像前缀：

```bash
# 1ms 镜像（国内 CDN，免登录）
HAPPY_NODE_IMAGE=docker.1ms.run/library/node:20
HAPPY_NODE_SLIM_IMAGE=docker.1ms.run/library/node:20-slim
```

### 3. `apt-get update` 或 `apt-get install ffmpeg` 卡很久

新版 Dockerfile 已经把 Debian 源切到了清华镜像，并且加了重试。如果你还是卡在这里，通常是：

- 服务器还在用旧版 Dockerfile
- 服务器网络策略不允许访问所选镜像
- 你在 `.env` 里把 `HAPPY_APT_MIRROR` 覆盖成了不可达地址

### 4. `yarn install` 很慢或超时

新版默认会把 npm registry 切到：

- `https://registry.npmmirror.com`

如果你有自建 npm 代理，也可以把 `HAPPY_NPM_REGISTRY` 改成自己的地址。

## 现有 Postgres 的使用建议

- 给 Happy 单独建一个数据库，或者至少单独建一个 schema。
- `DATABASE_URL` 建议写成 `postgresql://user:password@host:5432/dbname?schema=happy`。
- 如果你用的是云托管 PostgreSQL，通常还要在连接串后追加 TLS 参数，例如 `&sslmode=require`。
- 运行迁移的账号需要有目标 schema 的 `CREATE / ALTER / INDEX / INSERT / UPDATE / DELETE` 权限。
- 如果数据库就在 Docker 所在宿主机上，连接串主机名可以写 `host.docker.internal`。

## Redis 和 S3 什么时候再加

- 单机部署：可以先不配 `REDIS_URL`，这和上游现在的“最小依赖”方向一致。
- 多实例横向扩容：再补 `REDIS_URL`，让事件总线跨实例同步。
- 文件量大或要走 CDN：再补 `S3_*` 变量，把文件从本地卷切到对象存储。

## 反向代理

生产环境建议把 `3005` 放在 Nginx、Traefik 或云负载均衡后面，并对外提供 HTTPS。

已经附了一个 Nginx 示例：

- `nginx/happy-server.conf.example`

要点只有两个：

- HTTP API 和 WebSocket 都走同一个上游 `127.0.0.1:3005`
- `PUBLIC_URL` 必须和最终用户访问到的外网地址一致，否则本地文件 URL 会指错

## 在客户端里切到自定义服务

这个 Flutter 项目已经支持自定义后端地址：

- App 内进入“服务器设置”
- 选择“自定义服务器”
- 填入你的 `HAPPY_PUBLIC_URL`

CLI 或其他 Happy 客户端通常也可以通过 `HAPPY_SERVER_URL` 指向你的域名。
