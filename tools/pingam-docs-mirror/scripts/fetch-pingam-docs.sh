#!/usr/bin/env bash
# Mirror PingAM 8 docs (Markdown alternates published by Ping) for personal/lab AI reference.
# Content (c) Ping Identity. Do NOT publish mirrored pages.
set -uo pipefail
ROOT="${PINGAM_MIRROR_ROOT:-}"
if [ -z "$ROOT" ]; then
  ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fi
LLMS_URL="https://docs.pingidentity.com/pingam/llms.txt"
BASE="https://docs.pingidentity.com/pingam/8/"
DRY=0; LIMIT=0; SECTION=""; FORCE=0; SLEEP=0.3; MAXFAIL=20
usage(){ echo "Usage: $0 [--dry-run] [--limit N] [--section FOLDER] [--force] [--sleep SEC] [--max-fail N]"; }
while [ $# -gt 0 ]; do case "$1" in
  --dry-run) DRY=1;; --force) FORCE=1;;
  --limit) LIMIT="$2"; shift;; --section) SECTION="$2"; shift;;
  --sleep) SLEEP="$2"; shift;; --max-fail) MAXFAIL="$2"; shift;;
  -h|--help) usage; exit 0;; *) echo "Unknown arg $1"; usage; exit 2;; esac; shift; done
mkdir -p "$ROOT/_meta" "$ROOT/pingam/8"
MAN="$ROOT/_meta/manifest.jsonl"; touch "$MAN"
UA="pingam-docs-mirror/1.0 (personal lab reference)"
curl -fsSL -A "$UA" "$LLMS_URL" -o "$ROOT/_meta/llms.txt.tmp" && mv "$ROOT/_meta/llms.txt.tmp" "$ROOT/_meta/llms.txt" \
  || { echo "WARN: llms.txt refresh failed, using cached"; [ -s "$ROOT/_meta/llms.txt" ] || exit 1; }
# Exact header match: "## Pingam 8" (not 8.1)
awk '/^## Pingam 8[[:space:]]*$/{f=1;next} /^## /{f=0} f' "$ROOT/_meta/llms.txt" \
  | grep -oE "\[[^]]*\]\(${BASE//./\\.}[^)]+\.md\)" \
  | sed -E 's/^\[(.*)\]\((.*)\)$/\2\t\1/' | awk -F'\t' '!s[$1]++' > "$ROOT/_meta/pingam8-urls.tsv"
LIST="$ROOT/_meta/pingam8-urls.tsv"
[ -n "$SECTION" ] && LIST=$(mktemp) && grep -E "^${BASE}${SECTION}/" "$ROOT/_meta/pingam8-urls.tsv" > "$LIST"
TOTAL=$(wc -l < "$LIST"); echo "Pingam 8 pages selected: $TOTAL (all: $(wc -l < "$ROOT/_meta/pingam8-urls.tsv"))"
n=0; ok=0; skip=0; fail=0
while IFS=$'\t' read -r url title; do
  [ "$LIMIT" -gt 0 ] && [ "$n" -ge "$LIMIT" ] && break; n=$((n+1))
  rel="${url#https://docs.pingidentity.com/}"; out="$ROOT/$rel"
  if [ $DRY = 1 ]; then echo "[dry] $url -> $rel"; continue; fi
  mkdir -p "$(dirname "$out")"; tmp="$out.tmp"
  code=$(curl -sSL -A "$UA" -H 'Accept: text/markdown' -o "$tmp" -w '%{http_code}' "$url"); 
  if [ "$code" != 200 ]; then echo "FAIL $code $url"; rm -f "$tmp"; fail=$((fail+1))
    [ "$fail" -ge "$MAXFAIL" ] && { echo "Too many failures"; exit 3; }; sleep "$SLEEP"; continue; fi
  sha=$(sha256sum "$tmp" | cut -d' ' -f1)
  if [ $FORCE = 0 ] && [ -f "$out" ] && [ "$(sha256sum "$out" | cut -d' ' -f1)" = "$sha" ]; then
    rm -f "$tmp"; skip=$((skip+1)); echo "same $rel"
  else mv "$tmp" "$out"; ok=$((ok+1)); echo "saved $rel"; fi
  jq -nc --arg u "$url" --arg p "$rel" --argjson b "$(stat -c%s "$out")" --arg t "$(date -u +%FT%TZ)" \
    --arg s "$sha" --argjson c "$code" '{url:$u,local_path:$p,bytes:$b,fetched_at:$t,sha256:$s,http_status:$c}' >> "$MAN"
  sleep "$SLEEP"
done < "$LIST"
# keep last manifest entry per url
[ -s "$MAN" ] && tac "$MAN" | jq -sc 'unique_by(.url)[]' > "$MAN.tmp" && mv "$MAN.tmp" "$MAN"
echo "processed=$n saved=$ok unchanged=$skip failed=$fail"
[ $DRY = 1 ] || python3 "$ROOT/scripts/build-indexes.py" "$ROOT"
[ "$fail" -gt 0 ] && [ "$fail" -ge $(( (n+1)/2 )) ] && { echo "Majority failed"; exit 4; }
exit 0
