#!/bin/sh
set -eu

echo 'DERP starting...'

: "${DERP_DOMAIN:?must set DERP_DOMAIN}"
: "${TAILSCALE_HOSTNAME:=derp-auth}"

TS_STATE_FILE="/var/lib/tailscale/tailscaled.state"

tailscaled > /dev/null 2>&1 &

for i in $(seq 1 50); do
  [ -S /var/run/tailscale/tailscaled.sock ] && break
  sleep 0.1
done

[ -S /var/run/tailscale/tailscaled.sock ] || { echo "tailscaled.sock missing"; exit 1; }

TS_AUTH=""
if [ ! -s "$TS_STATE_FILE" ]; then
  : "${TAILSCALE_AUTH_KEY:?must set TAILSCALE_AUTH_KEY for first boot}"
  TS_AUTH="--authkey=${TAILSCALE_AUTH_KEY}"
fi

TS_LOGIN_FLAG=""
if [ -n "${TS_LOGIN_SERVER+x}" ] && [ -n "${TS_LOGIN_SERVER}" ]; then
  TS_LOGIN_FLAG="--login-server=${TS_LOGIN_SERVER}"
fi

MAX_RETRIES=10
COUNT=0
until tailscale up \
  ${TS_LOGIN_FLAG} \
  ${TS_AUTH} \
  --hostname="${TAILSCALE_HOSTNAME}" \
  --accept-routes=false \
  --shields-up=true \
  --ssh=false
do
  if [ $COUNT -ge $MAX_RETRIES ]; then
    echo "Failed to start tailscale after $MAX_RETRIES attempts"
    exit 1
  fi
  COUNT=$((COUNT + 1))
  sleep 0.5
done


DERPER_ARGS="
  -a :443
  --hostname ${DERP_DOMAIN}
  --certmode manual
  --certdir /cert
  --stun
  --verify-clients
"

/app/derper $DERPER_ARGS
