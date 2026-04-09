#!/usr/bin/env bash
# Build Happy Server Docker image and export for deployment.
#
# Run on a machine with GitHub access (e.g. your Mac).
# Transfer the exported tar.gz to your China server and load it —
# no network access needed on the server at all.
#
# Usage:
#   ./build.sh                # build only
#   ./build.sh --export       # build + export to tar.gz
#   ./build.sh --export --ref=abc123  # use a specific upstream commit
set -euo pipefail
cd "$(dirname "$0")"

# ── Config ──
REF="${HAPPY_UPSTREAM_REF:-d343330c86ab966969aecd82be4aecbad7ec4238}"
IMAGE="happy-server-custom:local"
OUTPUT="happy-server-image.tar.gz"

# ── Args ──
EXPORT=false
for arg in "$@"; do
  case "$arg" in
    --export|-e) EXPORT=true ;;
    --ref=*)     REF="${arg#*=}" ;;
    --help|-h)
      echo "Usage: $0 [--export] [--ref=COMMIT_SHA]"
      echo ""
      echo "  --export    Export image to tar.gz after building"
      echo "  --ref=SHA   Build from a specific upstream commit"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg (try --help)" >&2
      exit 1
      ;;
  esac
done

echo "==> Building image (ref: ${REF:0:12})"
echo "    Image: ${IMAGE}"

docker build \
  -t "${IMAGE}" \
  --build-arg "HAPPY_REF=${REF}" \
  -f Dockerfile \
  .

echo "==> Build complete: ${IMAGE}"

# ── Export ──
if [ "${EXPORT}" = true ]; then
  echo "==> Exporting to ${OUTPUT} ..."
  docker save "${IMAGE}" | gzip > "${OUTPUT}"
  SIZE="$(du -h "${OUTPUT}" | cut -f1)"
  echo "==> Done! (${SIZE})"
  echo ""
  echo "Next steps:"
  echo "  1. scp ${OUTPUT} docker-compose.server.yml .env.example user@your-server:/opt/happy-server/"
  echo "  2. ssh user@your-server"
  echo "  3. cd /opt/happy-server"
  echo "  4. docker load -i ${OUTPUT}"
  echo "  5. cp .env.example .env && vim .env   # set HAPPY_PUBLIC_URL, HANDY_MASTER_SECRET"
  echo "  6. docker compose -f docker-compose.server.yml up -d"
fi
