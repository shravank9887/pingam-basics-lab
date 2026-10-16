#!/usr/bin/env bash
# Convenience wrapper → tools/pingam-docs-mirror
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/tools/pingam-docs-mirror/scripts/fetch-pingam-docs.sh" "$@"
