# ELX DMZ Range — Phase 2 vulnerable web stack (`apps/dmz/`)

**AUTHORIZED LAB USE ONLY.** Intentionally vulnerable training applications for the
`elx-dmz-enterprise-range`. Deploys on `dmz-web01` (the Phase 1/1b DMZ host) via Docker
Compose. Makes five attack chains deployable and validatable:

| Chain | App | Vulnerability | Flag location |
|-------|-----|---------------|---------------|
| WEB-01 | Acme Portal | Broken access control (UI-only admin gating) | `GET /admin/settings` → `web01_flag` |
| WEB-02 | Acme Portal | IDOR on invoices | `GET /api/invoice?id=1001` (owner=cfo) |
| WEB-03 | Acme Search | SQL injection (string concat) | `secrets` table via UNION |
| WEB-04 | Acme Docs | File upload → contained command execution | `/flag` inside the container, via uploaded PHP |
| WEB-08 | Acme Portal | Weak/predictable password reset token | padmin's `GET /me/secret` after takeover |

Each chain is **toggleable** (`CHAIN_WEBxx=true|false`). `true` = vulnerable (default);
`false` = the remediated code path, for teaching the fix.

---

## File tree
```text
apps/dmz/
├── README.md
├── docker-compose.yml          # 4 services: db, portal, search, docs
├── .env.example                # config + toggles + lab-internal DB passwords
├── .flags.env.example          # placeholder flags
├── .gitignore                  # ignores .env and .flags.env
├── render-flags.sh             # writes per-deploy .flags.env (gitignored)
├── validate-dmz.sh             # presence + fix-validation for WEB-01/02/03/04/08
├── db/
│   └── seed/
│       ├── 00-init.sql         # creates portal+search DBs + scoped app users
│       └── 01-search.sql       # search schema + weak-MD5 users + secrets
├── acme-portal/                # Flask (WEB-01/02/08)
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app.py
├── acme-search/                # PHP/Apache (WEB-03)
│   ├── Dockerfile
│   └── src/{index,search,db,health}.php
└── acme-docs/                  # PHP/Apache (WEB-04)
    ├── Dockerfile
    ├── entrypoint.sh
    └── src/{index,upload,health}.php
```

---

## Safety & containment
- **DB isolation:** MariaDB sits on an internal-only Docker network (`backend`) and publishes no port. Apps reach it; nothing outside the host can.
- **No internet egress at runtime:** enforced at the host/VPC layer — `dmz-web01` has no internet route (locked design). The only outbound is the gateway apt proxy during provisioning, disabled afterward.
- **WEB-04 blast radius = one container:** non-root Apache (www-data), **no host bind mounts**, `no-new-privileges`, `NET_RAW` dropped, pid/memory limits, uploads on a tmpfs (wiped on restart). The flag lives at `/flag` *inside* the container; the PoC reads it there. The only host mount in the whole stack is the **read-only DB seed dir**.
- **Ephemeral:** everything resets by redeploy. DB uses a tmpfs datadir, so it re-seeds on every (re)start.
- **Secrets discipline:** real flags (`.flags.env`) and `.env` are gitignored. Only `*.example` files are committed. DB passwords are lab-internal (DB never exposed).

---

## Prerequisites (on `dmz-web01`)
Docker Engine + Compose plugin (installed by the Phase 1b `docker` role). Confirm:
```bash
docker --version && docker compose version
```

## Deploy
```bash
cd /opt/elx/apps/dmz            # repo path on dmz-web01 (see integration note)
cp .env.example .env            # adjust toggles/ports if desired
./render-flags.sh               # writes .flags.env (gitignored)
docker compose build
docker compose up -d
docker compose ps
```

## Validate (proves each chain matches its toggle state)
```bash
./validate-dmz.sh 127.0.0.1
```
The harness logs in as `analyst1`, then for each chain confirms:
- **toggle true** → the chain is exploitable and the flag is reachable;
- **toggle false** → the chain is closed (flag not reachable).

Expected output ends with `PASS: N  FAIL: 0`. (The WEB-08 check takes over `padmin`,
reads the flag, then resets padmin back to `PADMIN_PW` so the lab returns to a clean state.)

## Teach the fix (remediation lesson)
Flip a toggle and redeploy to serve the remediated path, then re-run the validator —
the same chain should now report "closed":
```bash
# example: serve the fixed IDOR + fixed SQLi
sed -i 's/^CHAIN_WEB02=true/CHAIN_WEB02=false/; s/^CHAIN_WEB03=true/CHAIN_WEB03=false/' .env
docker compose up -d
./validate-dmz.sh 127.0.0.1
```

## Reset
```bash
docker compose down -v        # drop containers + volumes
./render-flags.sh             # new flag tokens
docker compose up -d          # fresh, re-seeded
```

---

## Per-chain reference

### WEB-01 — Broken access control (Acme Portal)
- **Path:** log in as `analyst1` (role `user`) → request `/admin/settings` directly (the link is hidden in the UI but the route isn't guarded).
- **Vuln vs fix:** vulnerable build skips the server-side role check; fixed build returns `403` for non-admins.
- **Remediation:** enforce server-side authorization on every admin handler; deny-by-default. *(CWE-862 · OWASP A01)*

### WEB-02 — IDOR (Acme Portal)
- **Path:** as `analyst1` (owns invoice 1005), request `/api/invoice?id=1001` (owner `cfo`). Invoice 1007 carries a bonus vendor credential.
- **Vuln vs fix:** vulnerable build returns any invoice; fixed build checks `invoice.owner == session.user`.
- **Remediation:** object-level authorization. *(CWE-639 · OWASP A01)*

### WEB-03 — SQL injection (Acme Search)
- **Path:** `GET /search.php?q=` is concatenated into SQL. Extract secrets:
  ```text
  q = %' UNION SELECT name, value, '1' FROM secrets-- -
  ```
- **Cross-link:** the `users` table holds weak MD5 hashes; cracking `padmin` yields `Autumn2024!`, which is padmin's **Portal** password — a bonus route into WEB-01/WEB-08 territory.
- **Vuln vs fix:** vulnerable build concatenates; fixed build uses a prepared statement.
- **Remediation:** parameterized queries; least-privilege DB user. *(CWE-89 · OWASP A03)*

### WEB-04 — File upload → contained command execution (Acme Docs)
- **Path:** upload a `.php` file with `Content-Type: image/png` (the validator trusts the client content-type and keeps the original extension). The file lands in a web-served dir and Apache executes it. PoC reads `/flag` and runs `id` — **inside the container only**.
- **Vuln vs fix:** vulnerable build trusts content-type + keeps the name; fixed build verifies real image bytes (`getimagesize`), renames to a random `.png`, and the upload dir has PHP execution disabled via `.htaccess`.
- **Remediation:** content-inspected allowlist; store outside webroot; disable execution in upload dirs; randomize names. *(CWE-434 · OWASP A04)*

### WEB-08 — Weak password reset (Acme Portal)
- **Path:** the reset token is predictable (`md5("acme-reset-" + username)[:16]`) and not bound to a session. Compute padmin's token, set a new password via `/reset/confirm`, log in, read padmin's secret at `/me/secret` (= the flag).
- **Vuln vs fix:** vulnerable build accepts the predictable token; fixed build issues a random, single-use, 15-min, user-bound token (delivered out-of-band) and rejects the predictable one.
- **Remediation:** cryptographically random single-use expiring tokens bound to the user; rate limiting. *(CWE-640 · OWASP A07)*

---

## Validation status (honest)
Verified **in this build environment** (no Docker/Docker Hub egress available here):
- `acme-portal/app.py` — Python syntax compiles (`py_compile`).
- `docker-compose.yml` — valid YAML; 4 services, 2 networks.
- `entrypoint.sh`, `render-flags.sh`, `validate-dmz.sh` — pass `bash -n` / `sh -n`; `render-flags.sh` runs and emits correctly formatted flags.
- WEB-03 UNION payload assembles to valid SQL against the seeded `products`/`secrets` schema.

**Not yet run end-to-end** (requires Docker on `dmz-web01`): image builds, container boot, PHP execution paths, and the live `validate-dmz.sh` pass. PHP files are not lint-checked here (no `php` in this environment). Run the Deploy + Validate steps above on the target and confirm `FAIL: 0` before issuing the lab — consistent with the project's rule that nothing is claimed validated until it has actually been run.

---

## Integration notes (for the Phase 2 Ansible `vuln-apps` role)
- Sync this directory to `/opt/elx/apps/dmz` on `dmz-web01`, render flags, then `docker compose up -d` (the role can wrap these three steps).
- Optional: front the three services behind the host nginx as `/portal`, `/search`, `/docs` instead of distinct ports.
- Add the `apps/dmz/.env` and `apps/dmz/.flags.env` paths to the repo root `.gitignore` (the local `.gitignore` here already covers them; confirm the root ignore too).
- Wire `validate-dmz.sh` into the instructor pre-flight (guide §16) and the scoring portal's flag manifest (guide §17).
