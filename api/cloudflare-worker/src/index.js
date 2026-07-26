// atlas-launcher-worker
//
// Routes:
//   /                     -> get.ps1 (public repo)
//   /launcher.sha256      -> out-of-band launcher checksum (Worker secret)
//   /tool-hashes.sha256   -> out-of-band tool-hashes checksum (Worker secret)
//   /install.bat          -> onboarding/install.bat (public repo)
//   /install.ps1          -> install-rustdesk.ps1 (private repo via GITHUB_PAT)
//   /install.ps1.sha256   -> install-rustdesk.ps1.sha256 (private repo via GITHUB_PAT)
//   /healthz              -> lightweight health response
//
// Query params:
//   ?ref=<branch|tag|sha>  pin ref for public repo routes
//   ?v=<anything>          cache buster

const PUBLIC_REPO = "mikepchelper-spec/atlas-pc-support";
const PRIVATE_REPO = "mikepchelper-spec/atlas-pc-support-handoff";
const PRIVATE_PS1 = "install-rustdesk.ps1";
const PRIVATE_SHA = "install-rustdesk.ps1.sha256";

const CACHE_TTL_SECONDS = 30;
const TEXT_HEADERS = {
  "Content-Type": "text/plain; charset=utf-8",
  "Cache-Control": `public, max-age=${CACHE_TTL_SECONDS}`
};

function asText(status, body, headers = {}) {
  return new Response(body, {
    status,
    headers: { ...TEXT_HEADERS, ...headers }
  });
}

function safeRef(rawRef) {
  if (!rawRef) return "main";
  const ref = String(rawRef).trim();
  if (!ref) return "main";
  // Allow common git ref characters only.
  if (/^[A-Za-z0-9._\-\/]+$/.test(ref)) return ref;
  return "main";
}

async function fetchPublic(filePath, ref = "main") {
  return fetch(
    `https://raw.githubusercontent.com/${PUBLIC_REPO}/${encodeURIComponent(ref)}/${filePath}`,
    {
      headers: { "User-Agent": "atlas-launcher-worker" },
      cf: { cacheTtl: CACHE_TTL_SECONDS, cacheEverything: true }
    }
  );
}

async function fetchPrivate(filePath, env, ref = "main") {
  return fetch(
    `https://api.github.com/repos/${PRIVATE_REPO}/contents/${filePath}?ref=${encodeURIComponent(ref)}`,
    {
      headers: {
        Accept: "application/vnd.github.v3.raw",
        "User-Agent": "atlas-launcher-worker",
        Authorization: `Bearer ${env.GITHUB_PAT}`
      },
      cf: { cacheTtl: CACHE_TTL_SECONDS, cacheEverything: true }
    }
  );
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname.toLowerCase();
    const ref = safeRef(url.searchParams.get("ref"));

    if (path === "/healthz") {
      return asText(200, "ok\n");
    }

    // Live proxy from repo — no manual secrets needed.
    if (path === "/launcher.sha256") {
      const upstream = await fetchPublic("launcher.ps1.sha256", ref);
      if (!upstream.ok) {
        return asText(502, `# Atlas: launcher.ps1.sha256 not found (${upstream.status}).\n`);
      }
      return asText(200, await upstream.text());
    }

    if (path === "/tool-hashes.sha256") {
      const upstream = await fetchPublic("config/tool-hashes.json", ref);
      if (!upstream.ok) {
        return asText(502, `# Atlas: tool-hashes.json not found (${upstream.status}).\n`);
      }
      const body = await upstream.arrayBuffer();
      const hashBuf = await crypto.subtle.digest("SHA-256", body);
      const sha = [...new Uint8Array(hashBuf)]
        .map((b) => b.toString(16).padStart(2, "0"))
        .join("");
      return asText(200, `${sha}  tool-hashes.json\n`);
    }

    if (path === "/install.bat") {
      const upstream = await fetchPublic("onboarding/install.bat", ref);
      if (!upstream.ok) {
        return asText(502, `@echo off\necho Atlas: install.bat not found (${upstream.status})\npause\n`);
      }
      return new Response(await upstream.text(), {
        status: 200,
        headers: {
          "Content-Type": "application/x-bat; charset=utf-8",
          "Content-Disposition": "attachment; filename=\"install.bat\"",
          "Cache-Control": `public, max-age=${CACHE_TTL_SECONDS}`
        }
      });
    }

    if (path === "/install.ps1") {
      if (!env.GITHUB_PAT) {
        return asText(
          500,
          "# Atlas: GITHUB_PAT not configured in Cloudflare Worker secrets.\n" +
            "Write-Error 'Atlas onboarding not yet activated. Contact your technician.'\n"
        );
      }
      const upstream = await fetchPrivate(PRIVATE_PS1, env, ref);
      if (!upstream.ok) {
        return asText(
          502,
          `# Atlas: failed to fetch private .ps1 (${upstream.status}).\n` +
            'Write-Error "Atlas onboarding script unreachable. Check GITHUB_PAT scope and file exists at root of private repo."\n'
        );
      }
      return asText(200, await upstream.text());
    }

    if (path === "/install.ps1.sha256") {
      if (!env.GITHUB_PAT) {
        return asText(500, "# Atlas: GITHUB_PAT not configured in Cloudflare Worker secrets.\n");
      }
      const upstream = await fetchPrivate(PRIVATE_SHA, env, ref);
      if (!upstream.ok) {
        return asText(502, `# Atlas: failed to fetch private checksum (${upstream.status}).\n`);
      }
      return asText(200, await upstream.text());
    }

    // Default route: return get.ps1 so `irm https://toolspanel... | iex`
    // keeps launcher SHA verification before executing launcher.ps1.
    let upstream = await fetchPublic("get.ps1", ref);
    let actualRef = ref;
    if (!upstream.ok && ref !== "main") {
      upstream = await fetchPublic("get.ps1", "main");
      actualRef = "main";
    }
    if (!upstream.ok) {
      return asText(
        502,
        `# Atlas bootstrap: no se pudo obtener '${ref}' (${upstream.status})\n` +
          `Write-Error "Bootstrap no disponible (ref=${ref})"\n`
      );
    }

    return new Response(await upstream.text(), {
      status: 200,
      headers: {
        "Content-Type": "text/plain; charset=utf-8",
        "Cache-Control": `public, max-age=${CACHE_TTL_SECONDS}`,
        "X-Atlas-Source-Ref": actualRef,
        "X-Atlas-Requested-Ref": ref
      }
    });
  }
};
