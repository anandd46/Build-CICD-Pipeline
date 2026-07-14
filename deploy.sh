#!/usr/bin/env bash
# deploy.sh — triggered on EC2 by the GitHub Actions deploy job.
# Pulls the latest commit, rebuilds the Docker image, and restarts the container.
# Exit immediately on any error so partial deployments don't leave the app broken.
set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
APP_DIR="${APP_DIR:-$HOME/cicd-pipeline}"
IMAGE_NAME="${IMAGE_NAME:-cicd-flask-app}"
CONTAINER_NAME="${CONTAINER_NAME:-flask-app}"
APP_PORT="${APP_PORT:-5000}"
HEALTH_RETRIES=5
HEALTH_DELAY=5       # seconds between retries

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }

# ── Step 1: Pull latest code ───────────────────────────────────────────────────
log "Pulling latest code from origin/main..."
cd "$APP_DIR"
git fetch --prune
git reset --hard origin/main
log "Repository is at commit: $(git rev-parse --short HEAD)"

# ── Step 2: Stop and remove the running container ─────────────────────────────
log "Stopping existing container ($CONTAINER_NAME)..."
docker stop "$CONTAINER_NAME" 2>/dev/null && log "Container stopped." || log "Container was not running."
docker rm   "$CONTAINER_NAME" 2>/dev/null && log "Container removed." || log "Container did not exist."

# ── Step 3: Remove the old image to force a clean build ───────────────────────
log "Removing old image ($IMAGE_NAME:latest)..."
docker rmi "$IMAGE_NAME:latest" 2>/dev/null && log "Old image removed." || log "No previous image found."

# ── Step 4: Build new Docker image ────────────────────────────────────────────
log "Building Docker image: $IMAGE_NAME:latest..."
docker build --no-cache -t "$IMAGE_NAME:latest" "$APP_DIR"
log "Image built successfully."

# ── Step 5: Start the new container ───────────────────────────────────────────
log "Starting container ($CONTAINER_NAME) on port $APP_PORT..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p "${APP_PORT}:${APP_PORT}" \
    -e APP_ENV=production \
    "$IMAGE_NAME:latest"

log "Container started. Waiting for application to become healthy..."

# ── Step 6: Health check with retries ────────────────────────────────────────
for i in $(seq 1 $HEALTH_RETRIES); do
    sleep "$HEALTH_DELAY"
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost: ${APP_PORT}/health" 2>/dev/null || echo "000")
    if [ "$STATUS" = "200" ]; then
        log "Health check passed (attempt $i/$HEALTH_RETRIES). Application is live."
        break
    fi
    log "Health check attempt $i/$HEALTH_RETRIES — got HTTP $STATUS, retrying..."
    if [ "$i" -eq "$HEALTH_RETRIES" ]; then
        error "Application did not become healthy after $HEALTH_RETRIES attempts."
        log "Container logs:"
        docker logs "$CONTAINER_NAME" --tail 40
        exit 1
    fi
done

# ── Step 7: Print recent logs and status ──────────────────────────────────────
log "Deployment complete. Recent container logs:"
docker logs "$CONTAINER_NAME" --tail 20

log "Running containers:"
docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

log "Done. Application is accessible at http://$(curl -s ifconfig.me 2>/dev/null || echo '<EC2-IP>'):${APP_PORT}"
