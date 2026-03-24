# Build a runnable Happy Server image directly from the upstream repository.
# Default ref is pinned for reproducibility and can be overridden in .env.
# For public GitHub repos we prefer the archive download because fetching a
# detached commit SHA over git is flaky in some Docker/network environments.

FROM node:20 AS source

ARG HAPPY_REPO=https://github.com/slopus/happy.git
ARG HAPPY_REF=d343330c86ab966969aecd82be4aecbad7ec4238
ARG HAPPY_ARCHIVE_URL=

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl git \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN set -eux; \
  repo_url="${HAPPY_REPO%/}"; \
  repo_base="${repo_url%.git}"; \
  archive_url=""; \
  if [ -n "${HAPPY_ARCHIVE_URL}" ]; then \
    archive_url="${HAPPY_ARCHIVE_URL}"; \
  elif [ "${repo_base#https://github.com/}" != "${repo_base}" ] || [ "${repo_base#http://github.com/}" != "${repo_base}" ]; then \
    archive_url="${repo_base}/archive/${HAPPY_REF}.tar.gz"; \
  fi; \
  if [ -n "${archive_url}" ]; then \
    curl -fsSL --retry 5 --retry-all-errors --connect-timeout 15 "${archive_url}" \
      | tar -xzf - --strip-components=1 -C /src; \
  else \
    git init; \
    git remote add origin "${HAPPY_REPO}"; \
    git fetch --depth 1 origin "${HAPPY_REF}"; \
    git checkout --detach FETCH_HEAD; \
  fi

FROM node:20 AS deps

RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 make g++ build-essential \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /repo

COPY --from=source /src/package.json /src/yarn.lock ./
COPY --from=source /src/scripts ./scripts
COPY --from=source /src/patches ./patches

RUN mkdir -p packages/happy-app packages/happy-server packages/happy-cli packages/happy-agent packages/happy-wire

COPY --from=source /src/packages/happy-app/package.json packages/happy-app/
COPY --from=source /src/packages/happy-server/package.json packages/happy-server/
COPY --from=source /src/packages/happy-cli/package.json packages/happy-cli/
COPY --from=source /src/packages/happy-agent/package.json packages/happy-agent/
COPY --from=source /src/packages/happy-wire/package.json packages/happy-wire/

COPY --from=source /src/packages/happy-app/patches packages/happy-app/patches
COPY --from=source /src/packages/happy-server/prisma packages/happy-server/prisma
COPY --from=source /src/packages/happy-cli/scripts packages/happy-cli/scripts
COPY --from=source /src/packages/happy-cli/tools packages/happy-cli/tools

RUN SKIP_HAPPY_WIRE_BUILD=1 yarn install --frozen-lockfile --ignore-engines

FROM deps AS builder

COPY --from=source /src/packages/happy-wire ./packages/happy-wire
COPY --from=source /src/packages/happy-server ./packages/happy-server

RUN yarn workspace @slopus/happy-wire build
RUN yarn workspace happy-server build

FROM node:20-slim AS runner

WORKDIR /repo

RUN apt-get update \
  && apt-get install -y --no-install-recommends ffmpeg \
  && rm -rf /var/lib/apt/lists/*

ENV NODE_ENV=production
ENV DATA_DIR=/data
ENV PGLITE_DIR=/data/pglite
ENV PORT=3005

COPY --from=builder /repo/node_modules /repo/node_modules
COPY --from=builder /repo/packages/happy-wire /repo/packages/happy-wire
COPY --from=builder /repo/packages/happy-server /repo/packages/happy-server
COPY docker-entrypoint.sh /usr/local/bin/happy-server-entrypoint.sh

RUN chmod +x /usr/local/bin/happy-server-entrypoint.sh

VOLUME /data

EXPOSE 3005
EXPOSE 9090

CMD ["happy-server-entrypoint.sh"]
