# Tailscale DERP for Headscale (Podman)

Run a private Tailscale DERP relay that only serves nodes in your Headscale tailnet.  

---

## Quick Start

1) Persist Tailscale login state
```bash
mkdir -p ./state
```

2) Prepare a valid TLS certificate for your DERP domain

Assume the files live at:
- Certificate: `/etc/letsencrypt/<derp.example.com>/certificate.crt`
- Private key: `/etc/letsencrypt/<derp.example.com>/private.key`

3) Run the container (replace all placeholders)

Replace:
- `<derp.example.com>` with your DERP domain 
- `<Auth Key>` with a Headscale pre-auth key
- `<hs.example.com>` with your Headscale URL

Strict filename requirement inside the container:
The certificate files must be mounted as `/cert/<DERP_DOMAIN>.crt` and `/cert/<DERP_DOMAIN>.key` (filenames must exactly equal the `DERP_DOMAIN` value).

```bash
podman run --rm -d --name derp \
  --device /dev/net/tun \
  --cap-add=NET_ADMIN \
  -e DERP_DOMAIN=<derp.example.com> \
  -e TAILSCALE_HOSTNAME=derp-auth \
  -e TAILSCALE_AUTH_KEY=<Auth Key> \
  -e TAILSCALE_LOGIN_SERVER=https://<hs.example.com> \
  -v ./state:/var/lib/tailscale:Z \
  -v /etc/letsencrypt/<derp.example.com>/certificate.crt:/cert/<derp.example.com>.crt:Z \
  -v /etc/letsencrypt/<derp.example.com>/private.key:/cert/<derp.example.com>.key:Z \
  -p 8443:443/tcp \
  -p 3478:3478/tcp -p 3478:3478/udp \
  ghcr.io/bbooxx/tailscale-derp:latest
  ```

4) First-time login / authorization

If this is the first boot (empty `./state`) or your auth key is single-use/expired, follow the prompts:

```bash
podman logs -f derp
```

Complete the Tailscale login flow so the DERP node is authorized to your Headscale tailnet.  
On success, `./state/tailscaled.state` is persisted and future restarts won’t require login.

5) Verify from any other Tailscale client

```bash
tailscale netcheck
```
