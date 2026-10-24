# Atlas PC Support

> Unified Windows technical-support panel for IT professionals — WinUtil-style.

**🌐 Language: English | [Español](README.es.md)**

![License](https://img.shields.io/badge/license-MIT-green)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6)
[![Buy me a coffee](https://img.shields.io/badge/PayPal-Buy%20me%20a%20coffee-ffdd00?logo=paypal&logoColor=white)](https://www.paypal.me/atlaspcsupport)

Atlas PC Support is a WPF launcher (Fluent / Windows 11 theme) that bundles diagnostics, maintenance, networking, security and handover tools for technicians supporting Windows machines. Inspired by [Chris Titus' WinUtil](https://github.com/ChrisTitusTech/winutil).

---

## 🚀 Quick install (one line)

Open **Windows PowerShell 5.1** and paste. Elevate when the selected operation requires it:

```powershell
irm https://toolspanel.atlaspcsupport.com | iex
```

The HTTPS bootstrap downloads and verifies one complete approved release before running the launcher with `-File`. Its immutable commit and manifest digest are pinned in Cloudflare. Defender/AMSI remain active; there are no antivirus exclusions or permanent execution-policy changes.

Reopening the command selects the latest **approved publication**. An open session keeps its own verified tool versions. See [publication, offline use and rollback](docs/RELEASES.md).

---

## 🖼 Screenshot

![Atlas PC Support panel](docs/img/panel-screenshot.png)

A live dashboard banner (CPU / RAM / Disk + alerts) sits above the tool grid, and a system sidebar (hostname, user, Windows build, CPU model, total RAM, uptime, local IP) is visible at all times.

---

## 📦 Current inventory

The manifest retains **27 entries**. The deduplicator is unavailable; selected repair actions are restricted with an explanation.

See the [generated tool/dependency inventory](docs/INVENTARIO.md), [support matrix and restrictions](docs/SUPPORT-MATRIX.md), and [plan closure with pending QA](docs/audits/CIERRE-PLAN-2026-10-24.md). CI checks inventory freshness against the manifest.

Dashboard/system reads run on demand in a background PowerShell runspace. Shareable reports redact recognizable sensitive values and include release trace. Review free text before sharing; explicit BitLocker recovery backups contain secrets and must be stored separately.

---

## 🌍 Languages

The panel includes UI strings for the following languages; individual tool coverage varies. Cards have English/Spanish labels and search supports both without accents:

**English (default), Spanish, Portuguese, French, German, Italian, Romanian.**

Choose a language from the panel dropdown and restart to apply it. To force a specific language, set it in `branding.json`:

```json
{ "language": "en" }
```

Valid values: `"auto"`, `"en"`, `"es"`, `"pt"`, `"fr"`, `"de"`, `"it"`, `"ro"`. See [docs/LANGUAGES.md](docs/LANGUAGES.md) for adding more.

---

## 🎨 Custom branding

The panel accepts a **`branding.json`** file with your own brand: name, logo, colors, tagline, copyright, etc. Useful if you resell the panel or configure it for a specific client.

Copy `branding.example.json` to `branding.json` and edit it:

```json
{
  "brand": {
    "name": "YOUR SUPPORT COMPANY",
    "tagline": "Technical support for SMBs",
    "companyUrl": "https://mycompany.com",
    "copyright": "© 2026 My Company"
  },
  "theme": {
    "accentColor": "#0078D4",
    "darkMode": false,
    "cornerRadius": 4
  },
  "window": {
    "title": "My Company Panel v1.0"
  }
}
```

The launcher looks for `branding.json` in this order:

1. `branding.json` next to `launcher.ps1` (local repo).
2. `%LOCALAPPDATA%\AtlasPC\branding.json` (per-user profile).
3. `%APPDATA%\AtlasPC\branding.json`.

If none exist, the default Atlas branding is used.

📘 Full details in [docs/BRANDING.md](docs/BRANDING.md).

### Custom short domain

If you own a domain, you can serve the launcher from `tools.yourdomain.com` using Cloudflare Workers (free, ~10 minutes of setup). Step-by-step instructions in [docs/CLOUDFLARE-DOMAIN.md](docs/CLOUDFLARE-DOMAIN.md).

---

## 🧑‍💻 Local development

```powershell
git clone https://github.com/AtlasPCSupport/atlas-pc-support
cd atlas-pc-support

# Run in dev mode (uses src/, no compile step):
pwsh -NoProfile -ExecutionPolicy RemoteSigned -File src\Launcher.ps1

# Or build the distributable launcher:
pwsh -NoProfile -File build.ps1
# This regenerates launcher.ps1 (repo root) with everything embedded,
# plus get.ps1, launcher.ps1.sha256, config/tool-hashes.json and release-manifest.json.
```

### Repo layout

```
atlas-pc-support/
├── launcher.ps1              ← Compiled file entry, acquired as part of a verified release.
├── launcher.ps1.sha256       ← SHA-256 sidecar used by get.ps1.
├── build.ps1                 ← Regenerates launcher.ps1 from src/.
├── branding.example.json     ← Custom-branding template.
├── README.md / README.es.md  ← English / Spanish docs.
├── LICENSE / .gitignore
├── config/
│   ├── tools.json            ← Tool manifest (see "Add a tool" below).
│   └── tool-hashes.json      ← Expected SHA-256 for every Invoke-*.ps1.
├── docs/                     ← Guides + screenshots.
├── onboarding/               ← Standalone RustDesk client onboarding installer.
├── src/
│   ├── Launcher.ps1          ← Dev entry point.
│   ├── lib/                  ← Helpers (Branding, Admin, Logging, Dependencies, ToolRunner, PS7).
│   ├── gui/                  ← XAML + WPF GUI controllers.
│   └── tools/                ← One tool per file (`Invoke-XXX.ps1`).
└── .github/workflows/        ← CI rebuilds launcher.ps1 on every push.
```

### Add a new tool

1. Create `src/tools/Invoke-MyTool.ps1`:
   ```powershell
   function Invoke-MyTool {
       [CmdletBinding()] param()
       Write-Host "Hello from MyTool"
       Read-Host "Press ENTER to exit"
   }
   ```
2. Register it in `config/tools.json`:
   ```json
   {
     "id": "my-tool",
     "name": "My Tool",
     "description": "Short description (~150 chars max).",
     "category": "mantenimiento",
      "function": "Invoke-MyTool",
      "source": "Invoke-MyTool.ps1",
      "requiresAdmin": false,
     "runsInNewWindow": true,
     "runtime": {"engine":"windows-powershell","minimumVersion":"5.1","architecture":"x64","libraries":["ToolKit","Dependencies","PS7","Release"]},
     "dependencies": []
   }
   ```
3. Run `pwsh -File build.ps1` and `pwsh -File tests/Update-ToolDocumentation.ps1`.
4. Commit all generated files and push. CI rejects stale or incomplete releases. After the checks pass, promote the tested commit using [the release procedure](docs/RELEASES.md).

See [docs/ADDING-TOOLS.md](docs/ADDING-TOOLS.md) for the full reference.

---

## 📋 Logs and dependencies

- **Logs**: `%LOCALAPPDATA%\AtlasPC\logs\atlas-YYYY-MM-DD.log`.
- **External binaries** (FastCopy.exe, etc.): downloaded on demand to `%LOCALAPPDATA%\AtlasPC\bin\`.
- **Versioned releases**: `%LOCALAPPDATA%\AtlasPC\releases\<commit>\`; `current.json` and `previous.json` select verified bundles.
- **Client data / reports**: stored in `%USERPROFILE%\Documents\AtlasPC\` and never committed to the repo.

---

## 🛡 Requirements

- Windows client x64 build 19044+; targets include Windows 10 22H2 Home/Pro and LTSC 2021. VM qualification is pending.
- Windows PowerShell 5.1 is the default per-tool runtime. PowerShell 7 is not universally qualified.
- Administrator only for operations requiring it; Store/App Installer depend on current identity and policy.

---

## 📄 License

[MIT](LICENSE). Use, modify and redistribute freely, including commercially. Keep the copyright notice. Third-party binaries have separate workplace/redistribution terms, including FastCopy and HWiNFO.

---

## 🙋 Support

If you are a professional technician and want:

- A **branded version** with your own logo, colors and company-specific tools.
- **Premium email support**.
- A **pre-configured bundle** for fleets of 10+ PCs.

Visit [atlaspcsupport.com](https://atlaspcsupport.com) or open an issue.

---

## 🙏 Acknowledgements

- [Chris Titus Tech · WinUtil](https://github.com/ChrisTitusTech/winutil) — inspiration and architecture.
- [ModernWpfUI](https://github.com/Kinnara/ModernWpf) — Fluent style reference.
- The PowerShell community.
