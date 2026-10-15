#!/usr/bin/env bash
# Create .env from .env.example:
#   - fill every empty *_PASSWORD with a random value
#   - generate one shared DS_DEPLOYMENT_ID via dskeymgr (from artifacts/DS-*.zip)
# Idempotent: never overwrites an existing .env (delete it or `make reset` first).
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -f .env ]; then
    echo ".env already exists - leaving it untouched."
    exit 0
fi

rand() {
    LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 20 || true
}

umask 077
while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
        *_PASSWORD=) printf '%s%s\n' "$line" "$(rand)" ;;
        *) printf '%s\n' "$line" ;;
    esac
done < .env.example > .env

# Generate a shared deployment ID so all three DS instances share one CA.
DS_VERSION=$(grep -E '^DS_VERSION=' .env | cut -d= -f2-)
DS_ZIP="artifacts/DS-${DS_VERSION}.zip"
DEP_PASS=$(grep -E '^DS_DEPLOYMENT_PASSWORD=' .env | cut -d= -f2-)

if [ ! -f "$DS_ZIP" ]; then
    echo "WARNING: $DS_ZIP missing - cannot generate DS_DEPLOYMENT_ID yet."
    echo "         Place the zip, delete .env, and re-run make secrets."
    exit 0
fi

echo "Generating shared DS_DEPLOYMENT_ID (dskeymgr via Docker)..."
DEP_ID=$(docker run --rm \
    -v "$(pwd)/artifacts:/artifacts:ro" \
    -e DEP_PASS="$DEP_PASS" \
    -e DS_VERSION="$DS_VERSION" \
    eclipse-temurin:21.0.8_9-jre-jammy \
    bash -c 'apt-get update -qq >/dev/null && apt-get install -y -qq unzip >/dev/null \
      && unzip -q /artifacts/DS-${DS_VERSION}.zip -d /tmp \
      && /tmp/opendj/bin/dskeymgr create-deployment-id --deploymentIdPassword "$DEP_PASS"' \
    | tr -d '\r\n ')

if [ -z "$DEP_ID" ] || [ "${#DEP_ID}" -lt 10 ]; then
    echo "ERROR: failed to generate DS_DEPLOYMENT_ID"
    rm -f .env
    exit 1
fi

# Replace empty DS_DEPLOYMENT_ID= line
if grep -q '^DS_DEPLOYMENT_ID=$' .env; then
    sed -i "s|^DS_DEPLOYMENT_ID=\$|DS_DEPLOYMENT_ID=${DEP_ID}|" .env
elif grep -q '^DS_DEPLOYMENT_ID=' .env; then
    sed -i "s|^DS_DEPLOYMENT_ID=.*|DS_DEPLOYMENT_ID=${DEP_ID}|" .env
else
    printf 'DS_DEPLOYMENT_ID=%s\n' "$DEP_ID" >> .env
fi

echo "Generated .env with random passwords and shared DS_DEPLOYMENT_ID (mode 600)."
echo "amadmin password: see AM_ADMIN_PASSWORD in .env"
