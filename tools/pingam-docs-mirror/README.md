# PingAM 8 docs mirror tooling

Fetches Ping’s official Markdown doc pages for **PingAM 8** (the version used by this lab) into a local folder your AI tools can read offline.

Ping publishes these alternates for agents (`.html` → `.md`). Index: https://docs.pingidentity.com/pingam/llms.txt  
Guide: https://developer.pingidentity.com/build-with-ai/docs-for-agents.md

## What is in this repo (public, OK)

- `scripts/fetch-pingam-docs.sh` — download / refresh pages
- `scripts/build-indexes.py` — build `INDEX.md` and `READING-ORDER.md` after a fetch

These scripts are lab tooling (MIT with the rest of this repo).

## What is NOT in this repo

Downloaded page bodies under `pingam/` and `_meta/` are **© Ping Identity**. They stay on your machine (gitignored). Do not commit or re-upload them.

## Quick start (office PC / Copilot offline)

```bash
cd tools/pingam-docs-mirror
./scripts/fetch-pingam-docs.sh --limit 5          # smoke test
./scripts/fetch-pingam-docs.sh --section installation
./scripts/fetch-pingam-docs.sh                   # all ~891 PingAM 8 pages (~5 min)
```

Needs: `bash`, `curl`, `python3`, `jq`, and network once. After that, point Copilot / Cursor at `tools/pingam-docs-mirror/pingam/8/`.

Flags: `--dry-run`, `--limit N`, `--section FOLDER`, `--force`, `--sleep SEC` (default 0.3), `--max-fail N` (default 20).  
Override output root with `PINGAM_MIRROR_ROOT=/path/to/dir`.

## Layout after fetch

```
pingam/8/<folder>/<page>.md
pingam/8/INDEX.md
pingam/8/READING-ORDER.md
pingam/8/<folder>/INDEX.md
_meta/llms.txt  _meta/pingam8-urls.tsv  _meta/manifest.jsonl
```
