#!/usr/bin/env bash
# Idempotent AM install + external CTS wiring. Safe to run repeatedly (`make config`).
set -euo pipefail

: "${AM_URL:?}" "${AM_ADMIN_PASSWORD:?}" "${AM_CONFIG_PASSWORD:?}" "${AM_IDENTITY_PASSWORD:?}"
: "${AM_CTS_PASSWORD:?}"
AM_COOKIE_DOMAIN=${AM_COOKIE_DOMAIN:-example.com}
CTS_HOST=${CTS_HOST:-ds-cts}
CTS_PORT=${CTS_PORT:-1636}
AMSTER=/opt/amster/amster
MARKER_DIR=/opt/am-config

render() {
    local tpl=$1 out=$2; shift 2
    cp "$tpl" "$out"; chmod 600 "$out"
    for n in "$@"; do
        local v=${!n}
        v=${v//\\/\\\\}; v=${v//|/\\|}; v=${v//&/\\&}
        sed -i "s|&{$n}|$v|g" "$out"
    done
}

log() { echo "[amster] $(date '+%H:%M:%S') $*"; }
http_code() { curl -s -m 10 -o /dev/null -w '%{http_code}' "$1" || true; }

wait_for_am() {
    log "Waiting for AM at ${AM_URL} ..."
    for i in $(seq 1 120); do
        [ "$(http_code "${AM_URL}/isAlive.jsp")" != "000" ] && return 0
        [ $((i % 6)) -eq 0 ] && log "  still waiting ($((i * 5))s)"
        sleep 5
    done
    log "AM did not respond within 10 minutes"; exit 1
}

am_configured() {
    [ "$(http_code "${AM_URL}/json/serverinfo/*")" = "200" ]
}

wait_for_am

if am_configured; then
    log "AM already configured - skipping install."
else
    log "Installing AM (cfg=ds-config, identities=ds-identities) ..."
    render /opt/lab/install.amster /tmp/install.amster \
        AM_URL AM_ADMIN_PASSWORD AM_COOKIE_DOMAIN AM_CONFIG_PASSWORD AM_IDENTITY_PASSWORD
    "$AMSTER" /tmp/install.amster < /dev/null
    rm -f /tmp/install.amster
    for _ in $(seq 1 60); do am_configured && break; sleep 5; done
    am_configured || { log "AM still not configured after install"; exit 1; }
    touch "${MARKER_DIR}/.lab-installed"
    log "Install complete."
fi

if [ -f "${MARKER_DIR}/.lab-cts-wired" ]; then
    log "External CTS already wired ($(cat "${MARKER_DIR}/.lab-cts-wired")). Delete marker to re-apply."
    exit 0
fi

log "Configuring external CTS -> ${CTS_HOST}:${CTS_PORT} via REST ..."

TOKEN=$(curl -fsS -X POST "${AM_URL}/json/realms/root/authenticate" \
    -H 'Content-Type: application/json' \
    -H 'Accept-API-Version: resource=2.0, protocol=1.0' \
    -H 'X-OpenAM-Username: amadmin' \
    -H "X-OpenAM-Password: ${AM_ADMIN_PASSWORD}" \
  | sed -n 's/.*"tokenId":"\([^"]*\)".*/\1/p')

if [ -z "$TOKEN" ]; then
    log "Failed to obtain amadmin session token for CTS wiring"
    exit 1
fi

# Passwords from gen-env.sh are alphanumeric; embed safely as a JSON string.
cat > /tmp/cts-body.json <<CTSEOF
{
  "amconfig.org.forgerock.services.cts.store.common.section": {
    "org.forgerock.services.cts.store.location": "external",
    "org.forgerock.services.cts.store.root.suffix": "ou=famrecords,ou=openam-session,ou=tokens",
    "org.forgerock.services.cts.store.max.connections": "100",
    "org.forgerock.services.cts.store.page.size": 0,
    "org.forgerock.services.cts.store.vlv.page.size": 1000
  },
  "amconfig.org.forgerock.services.cts.store.external.section": {
    "org.forgerock.services.cts.store.ssl.enabled": true,
    "org.forgerock.services.cts.store.mtls.enabled": false,
    "org.forgerock.services.cts.store.starttls.enabled": false,
    "org.forgerock.services.cts.store.directory.name": "${CTS_HOST}:${CTS_PORT}",
    "org.forgerock.services.cts.store.loginid": "uid=openam_cts,ou=admins,ou=famrecords,ou=openam-session,ou=tokens",
    "org.forgerock.services.cts.store.password": "${AM_CTS_PASSWORD}",
    "org.forgerock.services.cts.store.heartbeat": 10,
    "org.forgerock.services.cts.store.affinity.enabled": false
  }
}
CTSEOF

HTTP=$(curl -s -o /tmp/cts-resp.json -w '%{http_code}' -X PUT \
    "${AM_URL}/json/global-config/servers/server-default/properties/cts" \
    -H "iPlanetDirectoryPro: ${TOKEN}" \
    -H 'Content-Type: application/json' \
    -H 'Accept-API-Version: protocol=1.0,resource=1.0' \
    --data-binary @/tmp/cts-body.json)

if [ "$HTTP" != "200" ] && [ "$HTTP" != "201" ]; then
    log "CTS update failed (HTTP ${HTTP}): $(cat /tmp/cts-resp.json)"
    exit 1
fi

date '+%Y-%m-%d %H:%M:%S' > "${MARKER_DIR}/.lab-cts-wired"
log "External CTS configured (HTTP ${HTTP}). Restart pingam (make config does this) for it to take effect."
rm -f /tmp/cts-body.json /tmp/cts-resp.json
