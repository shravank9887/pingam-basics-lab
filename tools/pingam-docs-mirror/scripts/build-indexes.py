#!/usr/bin/env python3
"""Build INDEX.md / READING-ORDER.md for the PingAM 8 mirror from llms.txt list + local files."""
import sys, os, collections
root = sys.argv[1]; base = "https://docs.pingidentity.com/pingam/8/"; d8 = os.path.join(root, "pingam/8")
rows = [l.rstrip("\n").split("\t", 1) for l in open(os.path.join(root, "_meta/pingam8-urls.tsv")) if l.strip()]
folders = collections.defaultdict(list)
for url, title in rows:
    rel = url[len(base):]; folder = rel.split("/")[0] if "/" in rel else "_root"
    folders[folder].append((title, rel))
ORDER = ["installation","setup","security","am-authentication","am-oauth2","am-oidc1","am-saml2","amster","maintenance","auth-nodes","entity-reference"]
def have(rel): return os.path.exists(os.path.join(d8, rel))
total_local = 0
out = ["# PingAM 8 docs mirror — index", "", "Content © Ping Identity. Personal/lab reference only. ✓ = downloaded locally.", "",
       "See [READING-ORDER.md](READING-ORDER.md) for a curated path.", "", "| Folder | Pages | Local |", "|---|---|---|"]
for f in sorted(folders):
    items = sorted(folders[f], key=lambda x: x[0].lower()); loc = sum(have(r) for _, r in items); total_local += loc
    out.append(f"| [{f}]({f}/INDEX.md) | {len(items)} | {loc} |")
    fd = os.path.join(d8, f); os.makedirs(fd, exist_ok=True)
    lines = [f"# PingAM 8 — {f}", "", f"[← all folders](../INDEX.md) · {len(items)} pages, {loc} local", ""]
    for t, r in items:
        name = r.split("/", 1)[1] if "/" in r else r
        lines.append(f"- {'✓' if have(r) else '·'} [{t}]({name})  — [online]({base}{r})")
    open(os.path.join(fd, "INDEX.md"), "w").write("\n".join(lines) + "\n")
out[2] += f" Total: {len(rows)} pages, {total_local} local."
open(os.path.join(d8, "INDEX.md"), "w").write("\n".join(out) + "\n")
ro = ["# PingAM 8 — suggested reading order for lab learners", ""]
for i, f in enumerate([x for x in ORDER if x in folders] + sorted(set(folders) - set(ORDER)), 1):
    ro.append(f"{i}. [{f}]({f}/INDEX.md) — {len(folders[f])} pages" + (" *(huge reference, read last)*" if f == "entity-reference" else ""))
open(os.path.join(d8, "READING-ORDER.md"), "w").write("\n".join(ro) + "\n")
