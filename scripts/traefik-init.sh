#!/usr/bin/env bash
# scripts/traefik-init.sh – Tailscale TCP 80/443 forwarders with PROXY protocol v2

# Ensure tailscaled is online
if ! tailscale status --json | jq -e '.Online // false' >/dev/null 2>&1; then
    echo "tailscaled is not online. Aborting tailscale serve." >&2
    exit 1
fi

# Serve TCP port 80 to Traefik's loopback port 8080 with PROXY protocol v2
tailscale serve --bg --proxy-protocol=2 --tcp=80 tcp://127.0.0.1:8080

# Serve TCP port 443 to Traefik's loopback port 8443 with PROXY protocol v2
tailscale serve --bg --proxy-protocol=2 --tcp=443 tcp://127.0.0.1:8443
