#!/bin/bash
# Source inside a DS container. Host defaults to this container's hostname.
export LDAP_HOST="${DS_HOSTNAME:-localhost}"
export LDAP_PORT="1636"
export LDAP_ADMIN_DN="cn=Directory Manager"
export LDAP_ADMIN_PWD="${DS_ROOT_PASSWORD}"
alias ldap-modify='/opt/opendj/bin/ldapmodify --hostname $LDAP_HOST --port $LDAP_PORT --useSSL --trustAll --bindDN "$LDAP_ADMIN_DN" --bindPassword "$LDAP_ADMIN_PWD"'
alias ldap-search='/opt/opendj/bin/ldapsearch --hostname $LDAP_HOST --port $LDAP_PORT --useSSL --trustAll --bindDN "$LDAP_ADMIN_DN" --bindPassword "$LDAP_ADMIN_PWD"'
echo "LDAP aliases loaded for ${LDAP_HOST}"
