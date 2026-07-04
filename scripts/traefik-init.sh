#!/usr/bin/env bash
# scripts/traefik-init.sh – Traefik init: ACME permissions + Tailscale TCP 80/443 forwarders
# Bypass with --no-verify is not applicable; this is not a git hook.

# --- Load .env for TRAEFIK_CERTS_VOLUME ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    . "$ENV_FILE"
    set +a
fi

# --- ACME permissions init (idempotent) ---
CERTS_DIR="${TRAEFIK_CERTS_VOLUME:-}"
if [ -z "$CERTS_DIR" ]; then
    echo "TRAEFIK_CERTS_VOLUME is not set. Aborting ACME init." >&2
    exit 1
fi

# Create certs directory if missing
mkdir -p "$CERTS_DIR"

# Touch acme-staging.json and acme.json if missing, then chmod 600
for f in "$CERTS_DIR/acme-staging.json" "$CERTS_DIR/acme.json"; do
    [ -f "$f" ] || touch "$f"
    chmod 600 "$f"
done
echo "ACME files ready in $CERTS_DIR (mode 600)."

# --- Tailscale TCP 80/443 forwarders with PROXY protocol v2 ---
# Ensure tailscaled is online
if ! tailscale status --json | jq -e '.Online // false' >/dev/null 2>&1; then
    echo "tailscaled is not online. Aborting tailscale serve." >&2
    exit 1
fi

# Serve TCP port 80 to Traefik's loopback port 8080 with PROXY protocol v2
tailscale serve --bg --proxy-protocol=2 --tcp=80 tcp://127.0.0.1:8080

# Serve TCP port 443 to Traefik's loopback port 8443 with PROXY protocol v2
tailscale serve --bg --proxy-protocol=2 --tcp=443 tcp://127.0.0.1:8443
