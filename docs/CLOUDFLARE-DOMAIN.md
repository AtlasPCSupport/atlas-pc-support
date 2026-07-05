# Dominio corto propio vía Cloudflare

En lugar de hacer que tus clientes ejecuten:

```powershell
irm https://raw.githubusercontent.com/mikepchelper-spec/atlas-pc-support/main/launcher.ps1 | iex
```

Puedes servirlo bajo **tu dominio** así:

```powershell
irm https://toolspanel.atlaspcsupport.com | iex
```

Gratis, 2 minutos de setup con Cloudflare Workers.

El mismo Worker también sirve `https://toolspanel.atlaspcsupport.com/install.bat` (instalador de RustDesk para clientes nuevos, ver [`onboarding/README.md`](../onboarding/README.md)).

---

## Requisitos previos

1. **Dominio** `atlaspcsupport.com` gestionado en Cloudflare (gratis añadirlo).
2. Cuenta Cloudflare (gratis).

Si tu dominio está en otro registrador (GoDaddy, Namecheap, etc.), basta con
cambiar los nameservers en el registrador por los de Cloudflare (te los dice
Cloudflare al añadir el sitio). Trámite normal de 15 min - 24 h.

---

## Opción recomendada: Cloudflare Worker

### 1. Crear el Worker

1. Cloudflare Dashboard → **Workers & Pages** → **Create application** → **Create Worker**.
2. Nombre sugerido: `atlas-launcher`.
3. Click **Deploy** (acepta el "Hello World" por defecto, lo cambiamos ahora).
4. Click **Edit code**.
5. Borra todo y pega el código de la sección **["Worker code (with private-repo support)"](#worker-code-with-private-repo-support)** abajo.
6. **Save and Deploy**.

Ya funciona bajo `atlas-launcher.<tu-subdominio>.workers.dev`. Falta atarlo a tu dominio.

### 2. Ruta personalizada `toolspanel.atlaspcsupport.com`

1. En el Worker → pestaña **Settings** → **Triggers** → **Add Custom Domain**.
2. Escribe `toolspanel.atlaspcsupport.com`.
3. Cloudflare crea el DNS automáticamente y propaga en minutos.

### 3. (Solo si vas a usar `/install.ps1`) — Añadir el GitHub PAT

El endpoint `/install.ps1` lee del repo PRIVADO `atlas-pc-support-handoff`.
Para que el Worker pueda leerlo, necesita un **GitHub Personal Access Token**
guardado como secret.

1. **Generar PAT** en GitHub:
   - Ir a https://github.com/settings/personal-access-tokens
   - **Generate new token (Fine-grained)**.
   - **Token name**: `cloudflare-worker-handoff-read`
   - **Expiration**: 1 year (o "no expiration").
   - **Resource owner**: `mikepchelper-spec`
   - **Repository access**: "Only select repositories" → `atlas-pc-support-handoff`.
   - **Permissions** → **Repository permissions** → **Contents**: **Read-only**.
   - **Generate token** → copiar el `github_pat_xxxxx` (solo se ve una vez).

2. **Añadir como secret en el Worker**:
   - Cloudflare Dashboard → tu worker `atlas-launcher`.
   - **Settings** → **Variables and Secrets** → **Add**.
   - Type: **Secret** | Name: `GITHUB_PAT` | Value: pegar el token.
   - **Save and deploy**.

3. **En el repo privado**, guarda también el checksum:
   - `install-rustdesk.ps1`
   - `install-rustdesk.ps1.sha256` (formato estándar: `<sha256>  install-rustdesk.ps1`)

### 4. Comprobar

```powershell
# Launcher principal:
irm https://toolspanel.atlaspcsupport.com | iex

# Forzar bypass del cache de Cloudflare/PowerShell:
irm "https://toolspanel.atlaspcsupport.com/?v=$(Get-Random)" | iex

# Pinnear versión (cuando hagamos releases con tags):
irm "https://toolspanel.atlaspcsupport.com?ref=v1.2.0" | iex

# Probar un branch específico antes de merge:
irm "https://toolspanel.atlaspcsupport.com?ref=devin/alguna-rama" | iex

# Onboarding installer (descarga el .bat):
# Abrir en navegador: https://toolspanel.atlaspcsupport.com/install.bat
```

---

## Worker code (with private-repo support)

```javascript
// atlas-launcher — sirve scripts de Atlas bajo tu dominio.
//
//   /                     → launcher.ps1 (PUBLIC repo)
//   /install.bat          → onboarding/install.bat (PUBLIC repo)
//   /install.ps1          → install-rustdesk.ps1 (PRIVATE repo, requires GITHUB_PAT)
//   /install.ps1.sha256   → install-rustdesk.ps1.sha256 (PRIVATE repo, requires GITHUB_PAT)
//
// Query params (only on /):
//   ?ref=<branch|tag|sha>  pinear versión (default: main)
//   ?v=<lo-que-sea>        cache buster (URL única → entrada nueva)
//
// IMPORTANTE: NO usar ?v como ref (versiones antiguas del Worker lo
// hacían y rompía el patrón `?v=$(Get-Random)` con números aleatorios).

const PUBLIC_REPO  = "mikepchelper-spec/atlas-pc-support";
const PRIVATE_REPO = "mikepchelper-spec/atlas-pc-support-handoff";
const PRIVATE_PS1  = "install-rustdesk.ps1";        // file at root of private repo
const PRIVATE_SHA  = "install-rustdesk.ps1.sha256"; // file at root of private repo

export default {
  async fetch(request, env) {
    const url  = new URL(request.url);
    const path = url.pathname.toLowerCase();

    // Helper: fetch a public file from raw.githubusercontent.com
    const fetchPublic = (filePath, ref = "main") =>
      fetch(
        `https://raw.githubusercontent.com/${PUBLIC_REPO}/${encodeURIComponent(ref)}/${filePath}`,
        {
          headers: { "User-Agent": "atlas-launcher-worker" },
          cf: { cacheTtl: 30, cacheEverything: true }
        }
      );

    // Helper: fetch a private file via GitHub Contents API with PAT
    const fetchPrivate = (filePath, ref = "main") =>
      fetch(
        `https://api.github.com/repos/${PRIVATE_REPO}/contents/${filePath}?ref=${encodeURIComponent(ref)}`,
        {
          headers: {
            "Accept": "application/vnd.github.v3.raw",
            "User-Agent": "atlas-launcher-worker",
            "Authorization": `Bearer ${env.GITHUB_PAT}`
          },
          cf: { cacheTtl: 30, cacheEverything: true }
        }
      );

    // ROUTE: /install.bat → public onboarding/install.bat (download)
    if (path === "/install.bat") {
      const upstream = await fetchPublic("onboarding/install.bat");
      if (!upstream.ok) {
        return new Response(`@echo off\necho Atlas: install.bat not found (${upstream.status})\npause\n`, {
          status: 502,
          headers: { "Content-Type": "text/plain; charset=utf-8" }
        });
      }
      return new Response(await upstream.text(), {
        status: 200,
        headers: {
          "Content-Type": "application/x-bat; charset=utf-8",
          "Content-Disposition": "attachment; filename=\"install.bat\"",
          "Cache-Control": "public, max-age=30"
        }
      });
    }

    // ROUTE: /install.ps1 → private install-rustdesk.ps1 (executed via iex)
    if (path === "/install.ps1") {
      if (!env.GITHUB_PAT) {
        return new Response(
          "# Atlas: GITHUB_PAT not configured in Cloudflare Worker secrets.\n" +
          "Write-Error 'Atlas onboarding not yet activated. Contact your technician.'\n",
          { status: 500, headers: { "Content-Type": "text/plain; charset=utf-8" } }
        );
      }
      const upstream = await fetchPrivate(PRIVATE_PS1);
      if (!upstream.ok) {
        return new Response(
          `# Atlas: failed to fetch private .ps1 (${upstream.status}).\n` +
          `Write-Error "Atlas onboarding script unreachable. Check GITHUB_PAT scope and file exists at root of private repo."\n`,
          { status: 502, headers: { "Content-Type": "text/plain; charset=utf-8" } }
        );
      }
      return new Response(await upstream.text(), {
        status: 200,
        headers: {
          "Content-Type": "text/plain; charset=utf-8",
          "Cache-Control": "public, max-age=30"
        }
      });
    }

    // ROUTE: /install.ps1.sha256 → private checksum sidecar
    if (path === "/install.ps1.sha256") {
      if (!env.GITHUB_PAT) {
        return new Response(
          "# Atlas: GITHUB_PAT not configured in Cloudflare Worker secrets.\n",
          { status: 500, headers: { "Content-Type": "text/plain; charset=utf-8" } }
        );
      }
      const upstream = await fetchPrivate(PRIVATE_SHA);
      if (!upstream.ok) {
        return new Response(
          `# Atlas: failed to fetch private checksum (${upstream.status}).\n`,
          { status: 502, headers: { "Content-Type": "text/plain; charset=utf-8" } }
        );
      }
      return new Response(await upstream.text(), {
        status: 200,
        headers: {
          "Content-Type": "text/plain; charset=utf-8",
          "Cache-Control": "public, max-age=30"
        }
      });
    }

    // ROUTE: / (default) → launcher.ps1 from public repo
    const ref = url.searchParams.get("ref") || "main";
    let upstream  = await fetchPublic("launcher.ps1", ref);
    let actualRef = ref;
    if (!upstream.ok && ref !== "main") {
      upstream  = await fetchPublic("launcher.ps1", "main");
      actualRef = "main";
    }
    if (!upstream.ok) {
      return new Response(
        `# Atlas launcher: no se pudo obtener '${ref}' (${upstream.status})\n` +
        `Write-Error "Launcher no disponible (ref=${ref})"\n`,
        { status: 502, headers: { "Content-Type": "text/plain; charset=utf-8" } }
      );
    }
    return new Response(await upstream.text(), {
      status: 200,
      headers: {
        "Content-Type": "text/plain; charset=utf-8",
        "Cache-Control": "public, max-age=30",
        "X-Atlas-Source-Ref": actualRef,
        "X-Atlas-Requested-Ref": ref
      }
    });
  }
};
```

---

## Opción simple: Page Rule con redirect

Si no quieres tocar código de Workers (y no necesitas el endpoint privado `/install.ps1`):

1. Cloudflare Dashboard → tu dominio → **Rules** → **Page Rules** → **Create Page Rule**.
2. URL: `toolspanel.atlaspcsupport.com/*`
3. Settings: **Forwarding URL** → **302 Temporary Redirect** →
   `https://raw.githubusercontent.com/mikepchelper-spec/atlas-pc-support/main/launcher.ps1`
4. Save.

**Contras**:
- Tras el redirect, la barra URL del usuario muestra GitHub (leve pérdida de marca).
- No puedes pinnear versiones con `?ref=...`.
- **No soporta `/install.ps1`** (no puedes redirigir con un PAT en una URL pública).

---

## Opción avanzada: analítica de uso

Añade un registro a KV storage dentro del Worker:

```javascript
// en fetch():
const country = request.cf?.country || "?";
await env.ATLAS_HITS.put(
  `${new Date().toISOString().slice(0,10)}:${country}`,
  String(((await env.ATLAS_HITS.get(...)) ?? 0) + 1),
  { expirationTtl: 86400 * 90 }  // 90 días
);
```

(Esto requiere crear un KV namespace en Cloudflare y bindearlo al Worker.
Setup 5 min.)

Te da conteo de ejecuciones por país/día sin tocar la app.

---

## Seguridad

- **`/` y `/install.bat`**: el Worker hace proxy de archivos PÚBLICOS de GitHub. Sin credenciales, sin riesgo si el código se filtra.
- **`/install.ps1`**: el Worker usa `GITHUB_PAT` (secret) para leer del repo PRIVADO. El token nunca se expone al cliente — solo se usa en la llamada server-to-server al GitHub Contents API. Si el PAT se filtra, lo regeneras en GitHub y rotas el secret en Cloudflare. La URL pública sigue siendo descargable por cualquiera (la "privacidad" es contra el indexado público de GitHub, no contra acceso anónimo a la URL final).
- **Coste**: 0 € para el caso normal (100 000 requests/día gratis en el plan free de Cloudflare Workers).
