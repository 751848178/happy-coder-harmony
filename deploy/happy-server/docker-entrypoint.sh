#!/bin/sh
set -eu

if [ -z "${HANDY_MASTER_SECRET:-}" ]; then
  echo "HANDY_MASTER_SECRET is required." >&2
  exit 1
fi

if [ -z "${PUBLIC_URL:-}" ]; then
  echo "PUBLIC_URL is required so uploaded file URLs point to your public domain." >&2
  exit 1
fi

if [ -n "${DATABASE_URL:-}" ]; then
  echo "Using external PostgreSQL via DATABASE_URL."
  echo "Running Prisma migrations against the existing database..."
  node_modules/.bin/prisma migrate deploy --schema packages/happy-server/prisma/schema.prisma
else
  echo "DATABASE_URL is not set. Falling back to embedded PGlite."
  echo "Running bundled standalone migrations..."
  node_modules/.bin/tsx packages/happy-server/sources/standalone.ts migrate
fi

echo "Starting Happy Server..."
exec node_modules/.bin/tsx packages/happy-server/sources/standalone.ts serve
