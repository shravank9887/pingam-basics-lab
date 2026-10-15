#!/bin/bash
set -e
: "${DS_ROOT_PASSWORD:?DS_ROOT_PASSWORD must be set (see .env)}"

INSTALL_DIR=${INSTALL_DIR:-/opt/opendj}
INSTANCE_DIR=${INSTANCE_DIR:-/opt/pingds-data/instance}
DATA_DIR=${DATA_DIR:-/opt/pingds-data}
DS_EXPORT_CERTS=${DS_EXPORT_CERTS:-false}

log_info()  { echo "[ENTRYPOINT] $(date '+%Y-%m-%d %H:%M:%S') - $1"; }
log_error() { echo "[ENTRYPOINT] $(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >&2; }

if [ "$(id -u)" = "0" ]; then
    log_info "Running as root - fixing volume permissions..."
    chown -R pingds:pingds /opt/pingds-data /opt/certs /opt/backups /opt/logs 2>/dev/null || true
    chmod 755 /opt/certs
    log_info "Permissions fixed. Switching to pingds user..."
    exec gosu pingds "$0" "$@"
fi

is_ds_instance_valid() {
    [ -d "${INSTANCE_DIR}/db" ] && \
    [ -f "${INSTANCE_DIR}/config/config.ldif" ] && \
    [ -f "${DATA_DIR}/.setup_complete" ]
}

# Prefer instance bin/ after setup; fall back to install bin/ for tools
start_ds_bin() {
    if [ -x "${INSTANCE_DIR}/bin/start-ds" ]; then
        echo "${INSTANCE_DIR}/bin/start-ds"
    else
        echo "${INSTALL_DIR}/bin/start-ds"
    fi
}

status_bin() {
    if [ -x "${INSTANCE_DIR}/bin/status" ]; then
        echo "${INSTANCE_DIR}/bin/status"
    else
        echo "${INSTALL_DIR}/bin/status"
    fi
}

FIRST_TIME_SETUP=false
if ! is_ds_instance_valid; then
    log_info "DS instance not found or incomplete. Running setup script..."
    /opt/scripts/setup-ds.sh
    if ! is_ds_instance_valid; then
        log_error "Setup failed! DS instance is still invalid."
        exit 1
    fi
    FIRST_TIME_SETUP=true
else
    log_info "DS instance already configured. Skipping setup."
    /opt/scripts/setup-ds.sh || true
fi

case "${1:-start-server}" in
    start-server)
        log_info "Starting PingDS (${DS_HOSTNAME:-?} profile=${DS_PROFILE:-?})..."
        CERTS_DIR=${CERTS_DIR:-/opt/certs}

        if [ "${DS_EXPORT_CERTS}" = "true" ]; then
            if [ "$FIRST_TIME_SETUP" = "true" ]; then
                log_info "Fresh setup - clearing stale certificates from shared volume..."
                rm -f "${CERTS_DIR}/ds-ca-cert.pem" "${CERTS_DIR}/truststore.p12"
            fi
            if [ ! -f "${CERTS_DIR}/truststore.p12" ]; then
                (
                    MAX_WAIT=${CERT_EXPORT_TIMEOUT:-600}
                    WAIT_COUNT=0
                    STATUS=$(status_bin)
                    while [ "$WAIT_COUNT" -lt "$MAX_WAIT" ]; do
                        if "$STATUS" \
                            --hostname "${DS_HOSTNAME:-ds-config}" \
                            --port 4444 \
                            --bindDN "cn=Directory Manager" \
                            --bindPassword "${DS_ROOT_PASSWORD}" \
                            --trustAll > /dev/null 2>&1 \
                           && /opt/scripts/export-certificates.sh; then
                            exit 0
                        fi
                        sleep 5
                        WAIT_COUNT=$((WAIT_COUNT + 5))
                    done
                    log_error "Certificate export did not succeed within ${MAX_WAIT}s"
                ) &
            fi
        fi

        exec "$(start_ds_bin)" --nodetach
        ;;
    stop-server)
        if [ -x "${INSTANCE_DIR}/bin/stop-ds" ]; then
            "${INSTANCE_DIR}/bin/stop-ds"
        else
            "${INSTALL_DIR}/bin/stop-ds"
        fi
        ;;
    status)
        "$(status_bin)" \
            --hostname "${DS_HOSTNAME:-localhost}" \
            --port 4444 \
            --bindDN "cn=Directory Manager" \
            --bindPassword "${DS_ROOT_PASSWORD}" \
            --trustAll
        ;;
    shell|bash)
        exec /bin/bash
        ;;
    *)
        exec "$@"
        ;;
esac
