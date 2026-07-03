# Resolve private Lab Hostnames through public DNS

Cloudflare authoritative DNS will publish a DNS-only wildcard for `*.lab.mikek8s.win` that resolves to the lab host's stable Tailscale address. This avoids operating split DNS while keeping Lab Services private because the address remains reachable only within the Trusted Access Environment; split DNS should be introduced only if this assumption stops holding.
