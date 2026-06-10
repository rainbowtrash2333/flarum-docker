#!/usr/bin/env bash
set -euo pipefail

COMPOSE_DEV="-p flarum-dev -f docker-compose.dev.yml"
PROD_DIRS=(data mysql redis)
DEV_SUFFIX="-dev"

echo "=== 1. Stopping dev containers ==="
docker compose $COMPOSE_DEV down -v 2>/dev/null || true

echo "=== 2. Removing old dev data ==="
for dir in "${PROD_DIRS[@]}"; do
  rm -rf "./${dir}${DEV_SUFFIX}"
done

echo "=== 3. Copying prod data to dev ==="
for dir in "${PROD_DIRS[@]}"; do
  if [ -d "./$dir" ]; then
    cp -a "./$dir" "./${dir}${DEV_SUFFIX}"
    echo "  $dir -> ${dir}${DEV_SUFFIX}"
  else
    echo "  WARNING: ./$dir not found, skipping"
  fi
done

echo "=== 4. Rebuilding and starting dev ==="
docker compose $COMPOSE_DEV build --no-cache
docker compose $COMPOSE_DEV up -d

echo "=== Done ==="
