# Atlas Cloudflare Worker

Versioned Worker code for:

- `https://toolspanel.atlaspcsupport.com/`
- `https://toolspanel.atlaspcsupport.com/launcher.sha256`
- `https://toolspanel.atlaspcsupport.com/tool-hashes.sha256`
- `https://toolspanel.atlaspcsupport.com/install.bat`
- `https://toolspanel.atlaspcsupport.com/install.ps1`
- `https://toolspanel.atlaspcsupport.com/install.ps1.sha256`

## Prerequisites

- Node.js 20+
- Cloudflare account with access to worker `atlas-launcher`
- `wrangler` authenticated (`npx wrangler login` or `CLOUDFLARE_API_TOKEN`)

## Set/Rotate Worker Secrets

Run from this folder:

```powershell
npx wrangler secret put GITHUB_PAT
npx wrangler secret put ATLAS_LAUNCHER_SHA256
npx wrangler secret put ATLAS_TOOL_HASHES_SHA256
```

Use current digest values from the main repo:

```powershell
Get-Content ../../launcher.ps1.sha256
(Get-FileHash ../../config/tool-hashes.json -Algorithm SHA256).Hash.ToLower()
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
