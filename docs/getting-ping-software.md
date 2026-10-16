# Getting PingAM, PingDS & Amster 8.0.2 (after the ForgeRock → Ping merge)

Last verified: 2026-10-15 (URLs checked with curl redirects from the public internet; login-walled screens NOT seen)

Lab artifacts you need:

| File | Product | Goes in |
|---|---|---|
| `AM-8.0.2.war` | PingAM 8.0.2 | `artifacts/` |
| `DS-8.0.2.zip` | PingDS 8.0.2 | `artifacts/` |
| `Amster-8.0.2.zip` | Amster 8.0.2 | `artifacts/` |

> Anything marked **(verify on screen)** is behind a login wall and could not be checked; it is described generically. Labels may differ.

## 1. Which site is which

| Old ForgeRock URL | Current URL (final, after redirects) | Purpose |
|---|---|---|
| https://backstage.forgerock.com | https://backstage.pingidentity.com/ (301) | Old Backstage portal, now on a Ping domain |
| https://backstage.forgerock.com/downloads | https://backstage.pingidentity.com/downloads → https://product-downloads.pingidentity.com/ | **Software downloads** (login required) |
| https://docs.forgerock.com | No response from our test (connection failed); use docs.pingidentity.com | Old docs domain |
| — | https://docs.pingidentity.com/pingam/8/ | PingAM 8 docs |
| — | https://docs.pingidentity.com/pingds/8/ | PingDS 8 docs |
| (Amster docs) | https://docs.pingidentity.com/amster/8/ → https://docs.pingidentity.com/pingam/8/ | Amster docs are now part of the PingAM docs |
| — | https://docs.pingidentity.com/pingam/8/amster/ | Amster guide |
| — | https://docs.pingidentity.com/pingam/8/release-notes/ → https://docs.pingidentity.com/pingam/release-notes/ | Release notes (one page for all versions) |
| — | https://docs.pingidentity.com/auth-node-ref/latest/ | Authentication node reference (journeys) |
| ForgeRock support | https://support.pingidentity.com/s/ | Support portal / knowledge base (customers) |
| — | https://www.pingidentity.com/en/resources/downloads.html | Ping's public downloads overview page (marketing) |
| — | https://www.pingidentity.com/en/try-ping.html | Free trial sign-up (**business email only**, see section 6b) |

`identity.pingidentity.com` did not answer to a plain request, so we couldn't confirm it as a sign-in host. Sign in wherever the download site sends you (verify on screen).

## 2. Create an account

1. Go to https://product-downloads.pingidentity.com/ (or the old Backstage link, which redirects there).
2. You'll be sent to a Ping sign-in page. Choose the option to register or create an account **(verify on screen)**.
3. Enter your details. **Use your work email.** Ping's trial form rejects personal addresses with the message "Enter valid business email" (we found this text in the try-ping page source). Expect the same rule here.
4. Confirm the email-verification link.
5. **Access to the downloads:** AM and DS binaries are licensed software. Whether a new account can see them depends on your entitlement (customer, partner, or approved evaluation). If the product list is empty or says you don't have access, see section 6b **(verify on screen)**.

## 3. Sign in

1. Open https://backstage.pingidentity.com/downloads. It redirects to product-downloads.pingidentity.com.
2. Sign in with the Ping account from step 2. If your org uses SSO, follow the prompts **(verify on screen)**.
3. If you land back on the home page, open the downloads link again.

## 4. Find and download AM, DS and Amster 8.0.2

1. On the downloads site, pick the product (**PingAM** / Access Management) **(verify on screen)**.
2. Choose **version 8.0.2**. Newer versions (8.0.4, 8.1.x) exist. Don't take the default "latest" because the lab is pinned to 8.0.2.
3. Download `AM-8.0.2.war`. Accept the licence agreement if it's shown **(verify on screen)**.
4. In the same AM version area, download `Amster-8.0.2.zip`. Amster is usually listed with AM **(verify on screen)**.
5. Switch to **PingDS** (Directory Services), pick 8.0.2, then download `DS-8.0.2.zip`.
6. Copy the checksum the site shows for each file **(verify on screen)**.
7. Check each file:

```bash
sha256sum AM-8.0.2.war DS-8.0.2.zip Amster-8.0.2.zip
```

```powershell
Get-FileHash .\AM-8.0.2.war, .\DS-8.0.2.zip, .\Amster-8.0.2.zip -Algorithm SHA256
```

If the site only gives SHA-1 or MD5, use `sha1sum`/`md5sum` or `-Algorithm SHA1/MD5` instead.
8. Move the files to the lab:

```bash
mv AM-8.0.2.war DS-8.0.2.zip Amster-8.0.2.zip /path/to/pingam-basics-lab/artifacts/
```

Keep the exact file names. Never commit or re-upload the binaries, because the licence doesn't allow redistribution.

## 5. Find the PingAM docs

- Home: https://docs.pingidentity.com/pingam/8/
- **Version switcher:** the major version is in the URL (`/pingam/8/`). On the page, use the version selector to change versions **(verify on screen; position may change)**. Docs are per major version, and 8.0.x patch differences are covered in the release notes.
- Release notes: https://docs.pingidentity.com/pingam/release-notes/
- Install guide: open it from the PingAM 8 home navigation (the guessed URL `/pingam/8/install-guide/` returns **404**).
- Journeys / auth nodes: https://docs.pingidentity.com/auth-node-ref/latest/, plus the authentication section in the AM 8 navigation.
- REST API: from the AM 8 navigation (`/pingam/8/rest-api-guide/` returns **404**).
- Amster: https://docs.pingidentity.com/pingam/8/amster/
- PingDS 8: https://docs.pingidentity.com/pingds/8/

## 6. Common confusions & fixes

| Symptom | Fix |
|---|---|
| Old Backstage bookmark | It redirects to backstage.pingidentity.com, and downloads now live at product-downloads.pingidentity.com |
| docs.forgerock.com won't load | Use docs.pingidentity.com/pingam/8/ |
| Amster docs link lands on AM home | Amster docs moved under /pingam/8/amster/ |
| Old guide URLs return 404 | Paths changed. Navigate from the version home page |
| Downloaded 8.0.4/8.1.x by mistake | Re-pick 8.0.2. The lab scripts expect the exact file names |
| "Enter valid business email" | Personal email domains are blocked. See 6b |
| Signed in but no AM/DS listed | Your account has no entitlement. See 6b or ask your Ping account contact |

### 6b. No work email? Your legitimate options (easiest first)

Don't use fake or disposable "work" emails, don't get around the terms of service, and don't download binaries that someone else re-uploaded.

1. **OpenAM community fork (Open Identity Platform), easiest and free.** Source: https://github.com/OpenIdentityPlatform/OpenAM and https://github.com/OpenIdentityPlatform/OpenDJ. The latest OpenAM release is 16.1.3, and the repo is still active (pushed 2026-10-14). Docker image: https://hub.docker.com/r/openidentityplatform/openam (94 tags). Licence: CDDL. GitHub shows it as "Other", so read the LICENSE file. *Caveat:* it is **not** PingAM 8. The concepts (realms, trees, OAuth2) are similar, but the UI, nodes, versions and Amster support differ, so the episodes won't match one-to-one.
2. **Ask your employer or school.** If you have any organisational email, register with it. You may also be able to use your company's existing Ping customer or partner account.
3. **Ping partners / sales.** Ask a Ping partner or the Ping sales team for evaluation access. Use the contact links on pingidentity.com. Our guessed `/en/contact-sales.html` and `/en/partners.html` URLs returned 404, so navigate from the site menu.
4. **PingOne Advanced Identity Cloud trial** (https://www.pingidentity.com/en/try-ping.html). This one *requires a business email*: the form shows "Business Email Address" and rejects personal email with "Enter valid business email". It's SaaS, so it doesn't give you the WAR/ZIPs, but the journeys concepts carry over.
5. **ForgeOps public container images** (`us-docker.pkg.dev/forgeops-public/images/am` and `/ds`). The registry is public and can be pulled without login (tags API returned 200). Tags `am:8.0.2` and `ds:8.0.2` exist, along with 8.0.4 and 8.1.x. The deploy tooling (https://github.com/ForgeRock/forgeops) is CDDL, but **the AM/DS software inside the images is still Ping's licensed software**. Being publicly pullable is *not* a licence to use them. Treat them as evaluation/dev only and check Ping's licence terms before you use them (verify; we didn't find an explicit image licence statement). Docs: https://docs.pingidentity.com/forgeops/

### Could the lab support other modes?

- **Public-image mode (ForgeOps 8.0.2 images):** technically possible. You would add a compose profile that pulls `am:8.0.2`/`ds:8.0.2` instead of building from `artifacts/`, adapt the env/boot config (ForgeOps images expect their own config/secret layout), and add a licence notice. You also need a check with Ping that this use is allowed. Medium effort.
- **OpenAM-fork mode:** possible as a separate "community" track. It would need its own Dockerfiles (OpenAM WAR on Tomcat + OpenDJ) and a version matrix, and the Amster steps would have to be replaced by ssoadm or REST. Episode content would differ. Medium-to-high effort.

## 7. Episode outline: "Where to find PingAM downloads & documentation" (≈7 min)

- 0:00 Hook: "Backstage is gone? Here's where everything moved."
- 0:30 Site map table (section 1) and a live demo of the redirects
- 1:30 Creating an account, the business-email rule, and entitlement
- 2:45 Signing in and downloading AM/DS/Amster 8.0.2 (pinning the version, licence)
- 4:00 Verifying checksums (sha256sum / Get-FileHash) and the artifacts/ folder
- 4:45 Docs tour: AM 8 home, version selector, release notes, Amster, auth node reference
- 5:45 No work email? The options in 6b and their licence caveats
- 6:30 Recap and next episode
