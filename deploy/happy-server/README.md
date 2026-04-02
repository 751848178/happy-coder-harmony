# Happy Server Docker 部署

这套方案参考的是 `slopus/happy` 主仓库当前推荐的自部署思路：

- 上游新版优先推荐 `Happy Server` 单容器启动。
- 默认是 `PGlite + 本地文件存储 + 无 Redis` 的最小依赖模式。
- 你的场景需要复用已有 `Postgres`，所以这里保留单容器形态，但把数据库切到外部 `DATABASE_URL`，同时继续使用本地卷保存上传文件。

上游参考：

- `https://github.com/slopus/happy/tree/main/packages/happy-server`
- `https://github.com/slopus/happy/blob/main/packages/happy-server/README.md`

## 目录说明

- `docker-compose.yml`: 启动 Happy Server
- `Dockerfile`: 直接从上游仓库构建镜像
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

Dockerfile 也会自动识别这类“镜像前缀 + GitHub 仓库”的 URL，并继续优先下载对应的 archive 包，所以后续只改 `HAPPY_UPSTREAM_REF` 也能继续走镜像。

为了适配国内服务器，构建阶段还额外做了三件事：

- Node 基础镜像默认走 `DaoCloud` 公共镜像前缀，避免直接命中 `registry-1.docker.io`
- `apt` 默认切到清华 Debian 镜像，并开启重试，减少 `apt-get update` 卡死
- `yarn/npm` 默认切到 `npmmirror`，避免安装 Node 依赖时访问官方 npm 慢或超时

如果你之前的 `.env` 里还残留 `hub.fastgit.xyz`，新 Dockerfile 也会在构建时自动改写到 `gh-proxy + github.com`，避免继续走已经不稳定的旧地址。

## 快速开始

1. 复制环境变量模板。

```bash
cd /Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter/deploy/happy-server
cp .env.example .env
```

2. 修改 `.env` 中至少这三个值：

- `HAPPY_PUBLIC_URL`
- `HANDY_MASTER_SECRET`
- `DATABASE_URL`

3. 构建并启动。

```bash
docker compose build
docker compose up -d
```

默认已经走国内更友好的镜像源。如果你想显式指定另一套镜像 archive，或者想切回官方源，可以在 `.env` 里这样改：

```bash
# 切回官方 Node 基础镜像与 npm
HAPPY_NODE_IMAGE=node:20
HAPPY_NODE_SLIM_IMAGE=node:20-slim
HAPPY_NPM_REGISTRY=https://registry.npmjs.org
HAPPY_APT_MIRROR=
HAPPY_APT_SECURITY_MIRROR=

# 显式指定 archive 镜像
HAPPY_UPSTREAM_ARCHIVE_URL=https://your-mirror.example.com/happy.tar.gz

# 或切回 GitHub 官方仓库
HAPPY_UPSTREAM_REPO=https://github.com/slopus/happy.git
```

不设置 `HAPPY_UPSTREAM_ARCHIVE_URL` 时，会自动按 `HAPPY_UPSTREAM_REPO + HAPPY_UPSTREAM_REF` 推导 archive 地址；镜像前缀形式的 GitHub URL 也支持自动推导。

只有在你明确想刷新基础镜像时，再额外执行：

```bash
docker compose build --pull
```

4. 查看启动日志，确认迁移完成并成功监听 `3005`。

```bash
docker compose logs -f happy-server
```

5. 验证健康检查。

```bash
curl http://127.0.0.1:3005/health
```

如果已经挂到域名和 HTTPS，也可以验证：

```bash
curl https://your-domain.example.com/health
```

## 国内服务器常见报错

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
    "https://docker.m.daocloud.io"
  ]
}
EOF
systemctl restart docker
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
