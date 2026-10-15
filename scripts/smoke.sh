#!/usr/bin/env bash
# Smoke test: three DS healthy, AM alive, amadmin login, LDAP base DN on each store.
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a

FQDN=${AM_FQDN:-am.example.com}; PORT=${AM_HTTP_PORT:-8080}
AM="http://${FQDN}:${PORT}/am"
RESOLVE="${FQDN}:${PORT}:127.0.0.1"
pass=0; failn=0
t() { local name=$1; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $name"; pass=$((pass+1)); else echo "FAIL  $name"; failn=$((failn+1)); fi; }

healthy() {
  local svc=$1
  [ "$(docker inspect -f '{{.State.Health.Status}}' "$(docker compose ps -q "$svc")")" = healthy ]
}

t "ds-config healthy"     healthy ds-config
t "ds-identities healthy" healthy ds-identities
t "ds-cts healthy"        healthy ds-cts
t "pingam healthy"        healthy pingam
t "AM isAlive.jsp"        curl -fsS --resolve "$RESOLVE" "$AM/isAlive.jsp"
t "AM serverinfo"         curl -fsS --resolve "$RESOLVE" "$AM/json/serverinfo/*"
t "amadmin login"         sh -c "curl -fsS --resolve '$RESOLVE' -X POST '$AM/json/realms/root/authenticate' \
      -H 'Content-Type: application/json' -H 'Accept-API-Version: resource=2.0, protocol=1.0' \
      -H 'X-OpenAM-Username: amadmin' -H \"X-OpenAM-Password: \$AM_ADMIN_PASSWORD\" | grep -q tokenId"

t "ds-config base DN"     docker compose exec -T ds-config sh -c \
  '/opt/opendj/bin/ldapsearch -h localhost -p 1636 --useSSL --trustAll \
   -D "cn=Directory Manager" -w "$DS_ROOT_PASSWORD" -b "ou=am-config" -s base "(objectClass=*)" dn'
t "ds-identities base DN" docker compose exec -T ds-identities sh -c \
  '/opt/opendj/bin/ldapsearch -h localhost -p 1636 --useSSL --trustAll \
   -D "cn=Directory Manager" -w "$DS_ROOT_PASSWORD" -b "ou=identities" -s base "(objectClass=*)" dn'
t "ds-cts base DN"        docker compose exec -T ds-cts sh -c \
  '/opt/opendj/bin/ldapsearch -h localhost -p 1636 --useSSL --trustAll \
   -D "cn=Directory Manager" -w "$DS_ROOT_PASSWORD" -b "ou=tokens" -s base "(objectClass=*)" dn'

echo "smoke: ${pass} passed, ${failn} failed"
[ "$failn" -eq 0 ]
