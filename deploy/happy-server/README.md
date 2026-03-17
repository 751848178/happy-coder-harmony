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
docker compose build --pull
docker compose up -d
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
