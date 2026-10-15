# artifacts/ — licensed Ping Identity downloads (not in git)

These files are licensed by Ping Identity and **must not be redistributed**, so this
folder is git-ignored apart from this README and `MANIFEST.sha256`.

1. Sign in to **Backstage** (<https://backstage.pingidentity.com>) → *Downloads*.
2. Download exactly these versions and save them here **with these exact names**:

| File | Product | Needed for |
|------|---------|-----------|
| `AM-8.0.2.war`     | PingAM 8.0.2 (.war) | `make up` |
| `Amster-8.0.2.zip` | Amster 8.0.2        | `make config` |
| `DS-8.0.2.zip`     | PingDS 8.0.2 (.zip) | `make up` (three containers) |

   Versions come from `.env` (`AM_VERSION`, `DS_VERSION`).
3. Record checksums in `MANIFEST.sha256` and run `make check`.
