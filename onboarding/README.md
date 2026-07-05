# Atlas PC Support — RustDesk onboarding installer

A two-piece installer that bootstraps RustDesk on a new client's PC, pre-configured for Atlas's self-hosted server (`rustdesk.atlaspcsupport.com`), with a unique random 16-character permanent password generated per machine.

> **Important**: this is intended to be run **by the technician** during a one-shot AnyDesk session (or in person). It is *not* friction-free for an end-user to run cold — it shows a UAC prompt, a Windows SmartScreen warning, and a console window. The technician guides the client through it.

## Architecture

| File | Repo | Why |
|---|---|---|
| `onboarding/install.bat` | **public** (this repo) | Clients download and double-click. Contains no secrets. |
| `install-rustdesk.ps1` | **private** ([atlas-pc-support-handoff](https://github.com/mikepchelper-spec/atlas-pc-support-handoff)) | Contains the exported RustDesk *Server Config* string (host + ed25519 pubkey). The pubkey is technically public-by-design, but keeping it out of a public, search-indexed repo is a sensible defense in depth. |
| `install-rustdesk.ps1.sha256` | **private** (`atlas-pc-support-handoff`) | Integrity sidecar. `install.bat` verifies this SHA-256 before running `install.ps1`. |
| Cloudflare Worker `atlas-launcher` | Cloudflare account | Routes `toolspanel.atlaspcsupport.com/install.ps1` and `/install.ps1.sha256` → fetches both files from the **private** repo using a GitHub PAT stored as a Worker secret. |

End-to-end flow:

```
client browser   →   toolspanel.atlaspcsupport.com/install.bat   →   GitHub raw (public repo)
double-click     →   install.bat self-elevates              →   UAC prompt
.bat fetches     →   toolspanel.atlaspcsupport.com/install.ps1 + /install.ps1.sha256   →   Cloudflare Worker
                                                             ↓
                                                     api.github.com (Bearer $GITHUB_PAT)
                                                             ↓
                                                     atlas-pc-support-handoff/install-rustdesk.ps1 (+ .sha256)
.ps1 executes    →   downloads latest RustDesk → installs → applies config → generates password → popup
```

## Recommended workflow (Option H — assisted via AnyDesk)

1. Client calls / WhatsApp: *"quiero contratar Soporte Premium"*.
2. Send them a one-shot **AnyDesk** session (free for personal use). Ask them to install AnyDesk, give you their 9-digit code.
3. Connect to their PC. Open their browser. Go to:
   ```
   https://toolspanel.atlaspcsupport.com/install.bat
   ```
4. Save the file → double-click → "More info" → "Run anyway" → UAC → wait ~60-90 seconds.
5. A WinForms popup appears with the **ID** and **Password** for this PC. Hit `Copiar`, paste into Vaultwarden + RustDesk API Admin.
6. Close popup → close AnyDesk → done.

Total: ~5 minutes per client. Zero friction for the client (you do everything via AnyDesk).

A backup copy of the credentials is also written to:
```
C:\ProgramData\Atlas\rustdesk-onboarding-<timestamp>.txt
```

## One-time setup before this is usable in production

This is the **5-step list** you do once. After this, every new client is just step 1-6 of the workflow above.

### 1. Add the onboarding files to the private handoff repo

The PR that introduces this folder also opens a companion PR in `atlas-pc-support-handoff` that adds:

- `install-rustdesk.ps1` (with a placeholder for your config)
- `install-rustdesk.ps1.sha256`

Merge that PR.

### 2. Paste your RustDesk Server Config into the .ps1

1. Open RustDesk on your master PC.
2. Settings → Network → "Unlock" (gear icon).
3. Click **"Export Server Config"** — the encoded string is copied to your clipboard.
4. In the PRIVATE repo, open `install-rustdesk.ps1` (use GitHub web UI, click ✏️ Edit) and paste it into:
   ```powershell
   $AtlasRustDeskConfig = '<<PASTE-EXPORTED-CONFIG-HERE>>'
   ```
5. Commit directly to `main`.
6. Recalculate and commit `install-rustdesk.ps1.sha256` after every `.ps1` change.

Until you do this, the .ps1 will refuse to run and print a helpful error.

### 3. Generate a GitHub PAT for the Cloudflare Worker

You need a fine-grained Personal Access Token that lets the Worker read the private repo.

1. Go to https://github.com/settings/personal-access-tokens
2. Click **"Generate new token"** → **"Generate new token (Fine-grained)"**.
3. Settings:
   - **Token name**: `cloudflare-worker-handoff-read`
   - **Expiration**: 1 year (or "no expiration" if you don't want to think about it again).
   - **Resource owner**: `mikepchelper-spec`
   - **Repository access**: "Only select repositories" → pick `atlas-pc-support-handoff`.
   - **Permissions**: scroll to **Repository permissions** → **Contents** → set to **Read-only**.
4. Click **"Generate token"** → copy the `github_pat_xxxxx` string (you only see it once).

### 4. Add the PAT as a secret in your Cloudflare Worker

1. Go to https://dash.cloudflare.com → **Workers & Pages** → click your existing `atlas-launcher` worker.
2. Tab **"Settings"** → section **"Variables and Secrets"** → click **"Add"**.
3. Type: **Secret** | Name: `GITHUB_PAT` | Value: paste the `github_pat_xxxxx` string.
4. Click **"Save and deploy"**.

### 5. Update the Cloudflare Worker code

Replace your current Worker code with the version in [`docs/CLOUDFLARE-DOMAIN.md`](../docs/CLOUDFLARE-DOMAIN.md) under "Worker code (with private-repo support)". The new version:

- Keeps your existing `launcher.ps1` behavior unchanged.
- Adds a route `/install.bat` → public repo (no auth).
- Adds a route `/install.ps1` → private repo (uses `GITHUB_PAT`).

Click **"Save and deploy"**.

That's it. The whole flow is now live at `https://toolspanel.atlaspcsupport.com/install.bat`.

## Quick sanity check

After step 5, open a private/incognito browser tab and visit:

- `https://toolspanel.atlaspcsupport.com/install.bat` → should download a .bat file (~3 KB).
- `https://toolspanel.atlaspcsupport.com/install.ps1` → should display the PowerShell script (after step 2, with your real config inside).
- `https://toolspanel.atlaspcsupport.com/install.ps1.sha256` → should return one-line SHA256 metadata.

If you get a 502 or empty response on `/install.ps1`, double-check:
- The PAT has Contents:Read on the handoff repo.
- The Worker secret name is exactly `GITHUB_PAT` (case sensitive).
- You hit "Save and deploy" after adding the secret AND after pasting the new code.

## Security notes

- The **public ed25519 key** of your hbbs is, by design, public. Keeping it in a private repo is mild defense in depth, not a hard security requirement. The matching **private key** never leaves `/var/lib/docker/volumes/.../id_ed25519` on your Oracle ARM.
- **Each client gets a unique random 16-character password.** Never reuse a password across clients. If one is compromised, only that client is affected and you can rotate it on a new visit.
- The recovery file at `C:\ProgramData\Atlas\rustdesk-onboarding-*.txt` contains the password in plain text. This is fine while you're on the machine in the same session — but consider deleting it via Atlas's `EntregaPC` checklist before handover, or include it in your standard PC-handover delivery routine.
- The CF Worker URL `toolspanel.atlaspcsupport.com/install.ps1` is *publicly downloadable* — anyone hitting the URL gets the file. The PAT only protects the GitHub side. If you want stronger protection (e.g., rate-limiting, allow-list of installers), add Cloudflare WAF rules or require a query-string token validated by the Worker.

## Future integration with Atlas (Phase 2)

When [Tool C — RustDesk integrado] lands in the panel, this folder becomes redundant: Atlas will run the same logic from a button click in the GUI, plus auto-upload credentials to Vaultwarden and auto-register the machine in RustDesk API Admin. Until then, this installer + manual paste into Vaultwarden is the bridge.

## Troubleshooting

| Symptom | Probable cause | Fix |
|---|---|---|
| `# Atlas: GITHUB_PAT not configured` in the .ps1 output | Worker secret missing | Step 4 of one-time setup. |
| `# Atlas: failed to fetch private .ps1 (404)` | PAT lacks access to the handoff repo, or the `.ps1` filename in the worker doesn't match the one in the private repo | Verify PAT scope (Contents:Read on `atlas-pc-support-handoff`). Verify file is named `install-rustdesk.ps1` at repo root. |
| `Checksum remoto invalido o no disponible` | Missing or stale `install-rustdesk.ps1.sha256`, or Worker route `/install.ps1.sha256` not deployed | Generate/update `.sha256` in private repo and deploy the updated Worker code. |
| `# Atlas: failed to fetch private .ps1 (401)` | PAT expired or revoked | Regenerate, replace the secret in Cloudflare. |
| `Onboarding aborted: missing server config.` | You haven't pasted your Server Config into `$AtlasRustDeskConfig` in the private .ps1 | Step 2 of one-time setup. |
| Popup never appears, console exits with `cannot find rustdesk.exe` | RustDesk silent installer was blocked by AV | Whitelist temp dir + retry, or install RustDesk first manually then re-run the PS script. |
| `--get-id` returns empty | Service still booting, or RustDesk 1.4.6+ broke the flag | The script retries 6 times with 4s sleep. If still empty, open RustDesk GUI to read the ID — it's there. The installer log shows `(no detectado - abrir RustDesk para verlo)` in this case. |
| SmartScreen blocks the .bat | Expected — file is unsigned. | Click "More info" → "Run anyway". Or buy a code-signing cert (~€25/year via Certum) and sign the .bat to remove the warning permanently. |
| Custom architecture (ARM64 Surface Pro X, etc.) | The script auto-detects via `$env:PROCESSOR_ARCHITECTURE` and downloads `aarch64`. If that asset is missing in the latest release, the script will throw. | Wait for next RustDesk release that includes ARM64 binaries. |
