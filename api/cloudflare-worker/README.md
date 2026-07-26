# Atlas Cloudflare Worker

Versioned Worker code for:

- `https://toolspanel.atlaspcsupport.com/`
- `https://toolspanel.atlaspcsupport.com/launcher.sha256`
- `https://toolspanel.atlaspcsupport.com/tool-hashes.sha256`
- `https://toolspanel.atlaspcsupport.com/install.bat`
- `https://toolspanel.atlaspcsupport.com/install.ps1`
- `https://toolspanel.atlaspcsupport.com/install.ps1.sha256`

## How it works

The `/launcher.sha256` and `/tool-hashes.sha256` endpoints proxy their
values **live from the GitHub repo** (with 30s Cloudflare edge cache).
No manual secret updates are needed after merging to `main`.

## Prerequisites

- Node.js 20+
- Cloudflare account with access to worker `atlas-launcher`
- `wrangler` authenticated (`npx wrangler login` or `CLOUDFLARE_API_TOKEN`)

## Set/Rotate Worker Secrets

Only `GITHUB_PAT` needs to be set (for private repo access):

```powershell
npx wrangler secret put GITHUB_PAT
```

Or run the helper script:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./set-worker-secrets.ps1
```

## Deploy

```powershell
npm install
npm run deploy
```

## Validate

From repo root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./api/cloudflare-worker/test-worker-endpoints.ps1
```
