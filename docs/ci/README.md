# CI workflow changes (Phase 0) — apply manually

The automation account that opened this PR **cannot modify files under
`.github/workflows/`** (GitHub requires the `workflow` OAuth scope, which the
integration token does not have). The two updated workflow files are staged here
so they travel with the PR and can be reviewed in diff.

## How to apply (≈1 minute, in the GitHub web UI)

For each file below, open the **target** workflow in GitHub, click the pencil
(Edit), replace its full contents with the staged version, and commit **to this
same branch** (`ci/phase-0-quality-gates`). The web UI commits with your own
credentials, which have the `workflow` scope.

| Staged copy (here)            | Copy into (target)                  |
|-------------------------------|-------------------------------------|
| `docs/ci/build.yml`           | `.github/workflows/build.yml`       |
| `docs/ci/auto-merge.yml`      | `.github/workflows/auto-merge.yml`  |

After applying both, you can delete this `docs/ci/` folder (optional).

## What changed

### `build.yml`
- **New `Lint (PSScriptAnalyzer)` step** — runs repo-wide using
  `PSScriptAnalyzerSettings.psd1`. Emits every finding as a GitHub annotation,
  but **only fails the build on `Error` severity** (verified: 0 errors repo-wide
  today, so it will not break existing CI). Warnings are surfaced to be reduced
  in later phases.
- **New `Assert compiled artifacts are fresh` step** — runs
  `tests/Assert-LauncherFresh.ps1` on the pristine checkout, before the build
  step, to block PRs that edit `src/` without rebuilding `launcher.ps1` /
  `config/tool-hashes.json`. Timestamp- and EOL-insensitive (no false positives).
- **New `Security guards` step** — runs `tests/Test-SecurityGuards.ps1` to
  fail fast on high-risk regressions (direct `Invoke-Expression/iex` command
  execution, `-EncodedCommand`, insecure onboarding pattern, and fallback to
  `%TEMP%\AtlasPC` for privileged runtime wrappers).
- All previous steps are preserved unchanged.

### `auto-merge.yml`
- Adds a **`guard` job** that, on every `pull_request` event for Devin-bot PRs,
  inspects the changed files. If the PR touches security-critical paths
  (`launcher.ps1`, `get.ps1`, `build.ps1`, `src/lib/**`, `config/**`,
  `.github/workflows/**`, `onboarding/**`) it **removes** the `auto-merge-ok`
  label; otherwise it **adds** it.
- The `automerge` job now requires the `auto-merge-ok` label
  (`MERGE_LABELS: "auto-merge-ok"`), so security-critical PRs are **never**
  auto-merged and require human review. Everything else keeps working as before.
