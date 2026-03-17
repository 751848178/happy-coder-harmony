#!/bin/sh
set -eu

APP_DIR=/repo/packages/happy-server
PRISMA_BIN=/repo/node_modules/.bin/prisma
TSX_BIN=/repo/node_modules/.bin/tsx

if [ -z "${HANDY_MASTER_SECRET:-}" ]; then
  echo "HANDY_MASTER_SECRET is required." >&2
  exit 1
fi

if [ -z "${PUBLIC_URL:-}" ]; then
  echo "PUBLIC_URL is required so uploaded file URLs point to your public domain." >&2
  exit 1
fi

cd "${APP_DIR}"

if [ -n "${DATABASE_URL:-}" ]; then
  echo "Using external PostgreSQL via DATABASE_URL."
  # db.ts prefers PGLITE_DIR when it is set, so clear it when external Postgres is enabled.
  unset PGLITE_DIR
  echo "Running Prisma migrations against the existing database..."
  "${PRISMA_BIN}" migrate deploy --schema prisma/schema.prisma
else
  echo "DATABASE_URL is not set. Falling back to embedded PGlite."
  echo "Running bundled standalone migrations..."
  "${TSX_BIN}" ./sources/standalone.ts migrate
fi

echo "Starting Happy Server..."
exec "${TSX_BIN}" ./sources/standalone.ts serve
