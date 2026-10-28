# Atlas publication Worker

Serves the existing `https://toolspanel.atlaspcsupport.com` domain.
The approved commit and SHA-256 of `release-manifest.json` are deployment variables,
independent of mutable repository reads. Root bootstrap, manifest and members are
verified before they are served. Unknown refs fail without a main fallback.

See [publication and recovery](../../docs/RELEASES.md) for the trust model, endpoint
contract, complete offline layout, CI gates and first-migration limitations.

```powershell
npm ci
npm test
npm audit --audit-level=moderate
npx wrangler deploy --dry-run --outdir .wrangler/dry-run
```

After committing the complete bundle and passing `build`, `windows-compat` and
`worker` on the same SHA, from the repository root:

```powershell
pwsh -NoProfile -File ./api/cloudflare-worker/publish-release.ps1 -Commit <full-tested-SHA>
```

`-DryRun` compiles without publishing. Promotion keeps existing vars/secrets and
pins the new code and release together. The custom-domain association stays the
same. No Cloudflare credentials are stored in this repository or required on PCs.

Wrangler is pinned to 4.152.0. The compatible transitive Undici 7.30.1 override fixes
the advisories reported by the current lock; no `npm audit fix --force` is used.
Node 22 is a development/CI requirement, not a requirement for Windows clients.

`/install.ps1` and its checksum are intentionally public client-distribution routes
backed by the existing private source repository. They use no shared cache and do
not accept a public Atlas ref for the private source. Review of the private script
content and client enrollment design remains separate work. `onboarding-release.json`
pins the private source commit and exact byte digest independently. Promotion
verifies those bytes using the existing gh credential and deploys the pins with
the Worker. Both private routes fetch that commit and verify its digest; the
checksum is derived from the same bytes, never a second mutable sidecar.

Each upstream fetch has a 15-second deadline that includes headers and bounded
body reading. Timeout aborts/cancels the request/reader and returns 504; bytes are
still verified before serving code. A public route may fetch both manifest and
member, so 15 seconds is not a total route-duration promise. No private cache or
mutable-ref fallback is added. Tests cover missing headers, a stalled body and
deadline cleanup after success. Wrangler is pinned with the lockfile; a version
update does not implicitly change compatibility_date or add runtime flags.
