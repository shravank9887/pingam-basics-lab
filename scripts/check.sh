#!/usr/bin/env bash
# Pre-flight: tools present, licensed artifacts present, checksums match MANIFEST.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

fail=0
ok()   { printf '  [ OK ] %s\n' "$*"; }
warn() { printf '  [WARN] %s\n' "$*"; }
bad()  { printf '  [FAIL] %s\n' "$*"; fail=1; }

envfile=.env; [ -f "$envfile" ] || envfile=.env.example
getv() { grep -E "^$1=" "$envfile" | tail -n1 | cut -d= -f2-; }
AM_VERSION=$(getv AM_VERSION); DS_VERSION=$(getv DS_VERSION)

echo "Tools:"
if command -v docker >/dev/null 2>&1; then ok "docker $(docker version --format '{{.Client.Version}}' 2>/dev/null)"; else bad "docker not found"; fi
if docker compose version >/dev/null 2>&1; then ok "$(docker compose version)"; else bad "docker compose v2 plugin not found"; fi
if [ -f .env ]; then ok ".env present"; else warn ".env missing - run 'make secrets' (versions read from .env.example)"; fi
if [ -f .env ] && grep -qE '^DS_DEPLOYMENT_ID=.+' .env; then ok "DS_DEPLOYMENT_ID set"; else warn "DS_DEPLOYMENT_ID empty - run make secrets"; fi

if command -v sha256sum >/dev/null 2>&1; then SHA="sha256sum"
elif command -v shasum >/dev/null 2>&1; then SHA="shasum -a 256"
else SHA=""; fi

need=("AM-${AM_VERSION}.war" "DS-${DS_VERSION}.zip" "Amster-${AM_VERSION}.zip")

echo "Artifacts (artifacts/, download from Backstage - see artifacts/README.md):"
for f in "${need[@]}"; do
    path="artifacts/$f"
    if [ ! -f "$path" ]; then bad "missing $path"; continue; fi
    expected=$(awk -v f="$f" '$2==f {print $1}' artifacts/MANIFEST.sha256 2>/dev/null)
    if [ -z "$SHA" ]; then warn "$f present (no sha256 tool to verify)"; continue; fi
    actual=$($SHA "$path" | awk '{print $1}')
    if [ -z "$expected" ] || [ "${expected#<}" != "$expected" ]; then
        warn "$f present, no checksum recorded in MANIFEST.sha256 (actual: $actual)"
    elif [ "$expected" = "$actual" ]; then
        ok "$f sha256 verified"
    else
        bad "$f sha256 mismatch (expected $expected, got $actual)"
    fi
done

if [ "$fail" -ne 0 ]; then echo "check: FAILED"; exit 1; fi
echo "check: OK"
