#!/usr/bin/env bash
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
EC2_USER="${EC2_USER:-ec2-user}"
EC2_HOST="${EC2_HOST:-}"
EC2_KEY="${EC2_KEY:-}"
REMOTE_DIR="${REMOTE_DIR:-/home/ec2-user/MSML605_Final}"
REMOTE_PORT="${REMOTE_PORT:-8000}"
# ──────────────────────────────────────────────────────────────────────────────

if [[ -z "$EC2_HOST" ]]; then
    echo "ERROR: EC2_HOST is not set. Run with: EC2_HOST=<ip> EC2_KEY=<path> bash deploy.sh"
    exit 1
fi

if [[ -z "$EC2_KEY" ]]; then
    echo "ERROR: EC2_KEY is not set. Run with: EC2_HOST=<ip> EC2_KEY=<path> bash deploy.sh"
    exit 1
fi

echo "→ Deploying to ${EC2_USER}@${EC2_HOST}:${REMOTE_DIR}"

ssh -i "$EC2_KEY" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_HOST" bash <<EOF
set -euo pipefail

cd "$REMOTE_DIR"

echo "  • Pulling latest changes..."
git pull origin main

echo "  • Installing/updating dependencies..."
pip install -q -r requirements-api.txt

echo "  • Restarting API..."
pkill -f "uvicorn api.main:app" || true
sleep 1
nohup uvicorn api.main:app --host 0.0.0.0 --port $REMOTE_PORT > api.log 2>&1 &

sleep 2
if pgrep -f "uvicorn api.main:app" > /dev/null; then
    echo "  ✓ API is running on port $REMOTE_PORT"
else
    echo "  ✗ API failed to start — check api.log"
    exit 1
fi
EOF

echo "✓ Deployed successfully."
