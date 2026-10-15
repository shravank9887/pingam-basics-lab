#!/bin/bash
set -euo pipefail

# Setup PingDS with exactly ONE AM profile (DS_PROFILE).
# Shared DS_DEPLOYMENT_ID + password across all three DS containers → one CA.
# Instance lives on the volume (--instancePath) so container recreate keeps data.

INSTALL_DIR=${INSTALL_DIR:-/opt/opendj}
INSTANCE_DIR=${INSTANCE_DIR:-/opt/pingds-data/instance}
DATA_DIR=${DATA_DIR:-/opt/pingds-data}

DS_HOSTNAME=${DS_HOSTNAME:-pingds}
DS_SERVER_ID=${DS_SERVER_ID:-ds-server-01}
DS_DEPLOYMENT_ID=${DS_DEPLOYMENT_ID:?DS_DEPLOYMENT_ID must be set (see .env / make secrets)}
DS_DEPLOYMENT_PASSWORD=${DS_DEPLOYMENT_PASSWORD:?DS_DEPLOYMENT_PASSWORD must be set}
DS_ROOT_PASSWORD=${DS_ROOT_PASSWORD:?DS_ROOT_PASSWORD must be set}
DS_MONITOR_PASSWORD=${DS_MONITOR_PASSWORD:?DS_MONITOR_PASSWORD must be set}
DS_PROFILE=${DS_PROFILE:?DS_PROFILE must be am-config, am-identity-store, or am-cts}

log_info()    { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"; }
log_error()   { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2; }
log_success() { echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $1"; }

is_ds_configured() {
    [ -f "${DATA_DIR}/.setup_complete" ] && \
    [ -d "${INSTANCE_DIR}/db" ] && \
    [ -f "${INSTANCE_DIR}/config/config.ldif" ]
}

profile_args() {
    case "${DS_PROFILE}" in
        am-config)
            : "${AM_CONFIG_PASSWORD:?AM_CONFIG_PASSWORD must be set for am-config}"
            echo --profile am-config:6.5 --set "am-config/amConfigAdminPassword:${AM_CONFIG_PASSWORD}"
            ;;
        am-identity-store)
            : "${AM_IDENTITY_PASSWORD:?AM_IDENTITY_PASSWORD must be set for am-identity-store}"
            echo --profile am-identity-store:8.0 --set "am-identity-store/amIdentityStoreAdminPassword:${AM_IDENTITY_PASSWORD}"
            ;;
        am-cts)
            : "${AM_CTS_PASSWORD:?AM_CTS_PASSWORD must be set for am-cts}"
            echo --profile am-cts:6.5 --set "am-cts/amCtsAdminPassword:${AM_CTS_PASSWORD}"
            ;;
        *)
            log_error "Unknown DS_PROFILE=${DS_PROFILE}"
            exit 1
            ;;
    esac
}

setup_pingds() {
    log_info "Starting PingDS setup with profile=${DS_PROFILE}"
    log_info "Hostname: ${DS_HOSTNAME}  Server ID: ${DS_SERVER_ID}"
    log_info "Instance path: ${INSTANCE_DIR}"
    mkdir -p "${INSTANCE_DIR}"
    # shellcheck disable=SC2046
    ${INSTALL_DIR}/setup \
        --instancePath "${INSTANCE_DIR}" \
        --serverId "${DS_SERVER_ID}" \
        --deploymentId "${DS_DEPLOYMENT_ID}" \
        --deploymentIdPassword "${DS_DEPLOYMENT_PASSWORD}" \
        --rootUserDn "cn=Directory Manager" \
        --rootUserPassword "${DS_ROOT_PASSWORD}" \
        --monitorUserPassword "${DS_MONITOR_PASSWORD}" \
        --hostname "${DS_HOSTNAME}" \
        --ldapPort 1389 \
        --ldapsPort 1636 \
        --adminConnectorPort 4444 \
        --httpPort 8080 \
        --httpsPort 8443 \
        $(profile_args) \
        --acceptLicense
    log_success "PingDS setup completed (profile=${DS_PROFILE})"
}

display_info() {
    log_info "=========================================="
    log_info "PingDS Configuration Summary"
    log_info "=========================================="
    log_info "Hostname:    ${DS_HOSTNAME}"
    log_info "Server ID:   ${DS_SERVER_ID}"
    log_info "Profile:     ${DS_PROFILE}"
    log_info "Instance:    ${INSTANCE_DIR}"
    log_info "LDAP/LDAPS:  1389 / 1636"
    case "${DS_PROFILE}" in
        am-config)
            log_info "Base DN:     ou=am-config"
            log_info "Admin DN:    uid=am-config,ou=admins,ou=am-config"
            ;;
        am-identity-store)
            log_info "Base DN:     ou=identities"
            log_info "Admin DN:    uid=am-identity-bind-account,ou=admins,ou=identities"
            ;;
        am-cts)
            log_info "Base DN:     ou=tokens"
            log_info "CTS suffix:  ou=famrecords,ou=openam-session,ou=tokens"
            log_info "Admin DN:    uid=openam_cts,ou=admins,ou=famrecords,ou=openam-session,ou=tokens"
            ;;
    esac
    log_info "=========================================="
}

main() {
    if is_ds_configured; then
        log_info "PingDS already configured (profile=${DS_PROFILE}) - skipping setup"
        echo "${DS_DEPLOYMENT_ID}" > "${DATA_DIR}/.deployment_id"
        chmod 600 "${DATA_DIR}/.deployment_id"
        display_info
        return 0
    fi

    log_info "First-time setup for ${DS_HOSTNAME} (profile=${DS_PROFILE})..."
    echo "${DS_DEPLOYMENT_ID}" > "${DATA_DIR}/.deployment_id"
    chmod 600 "${DATA_DIR}/.deployment_id"

    setup_pingds

    if [ ! -f "${INSTANCE_DIR}/config/config.ldif" ]; then
        log_error "DS configuration files missing after setup"
        exit 1
    fi

    display_info
    touch "${DATA_DIR}/.setup_complete"
    echo "$(date '+%Y-%m-%d %H:%M:%S')" > "${DATA_DIR}/.setup_timestamp"
    log_success "First-time setup completed for ${DS_HOSTNAME}"
}

main "$@"
