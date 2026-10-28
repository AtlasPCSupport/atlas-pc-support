// The existing domain is the bootstrap trust anchor. Publication pins are set
// with a Worker deployment, never inferred from mutable repository checksums.
const PUBLIC_REPO = "mikepchelper-spec/atlas-pc-support";
const PRIVATE_REPO = "mikepchelper-spec/atlas-pc-support-handoff";
const encoder = new TextEncoder();
const decoder = new TextDecoder("utf-8", { fatal: true });
const textHeaders = { "Content-Type": "text/plain; charset=utf-8", "Cache-Control": "no-store", "X-Content-Type-Options": "nosniff" };
class HttpError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}
function response(status, body, headers = {}) { return new Response(body, { status, headers: { ...textHeaders, ...headers } }); }
function descriptor(commit, manifestSha256) {
  if (!/^[a-f0-9]{40}$/.test(commit || "") || !/^[a-f0-9]{64}$/.test(manifestSha256 || "")) throw new HttpError(503, "Atlas publication is not configured.");
  return { schemaVersion: 1, commit, manifestSha256 };
}
function selectRelease(env, requestedRef) {
  const current = descriptor(env.ATLAS_RELEASE_COMMIT, env.ATLAS_RELEASE_MANIFEST_SHA256);
  if (requestedRef === null || requestedRef === "main" || requestedRef === current.commit) return current;
  if (!/^[A-Za-z0-9._\/-]+$/.test(requestedRef)) throw new HttpError(400, "Invalid Atlas ref.");
  if (requestedRef === env.ATLAS_PREVIOUS_RELEASE_COMMIT) return descriptor(env.ATLAS_PREVIOUS_RELEASE_COMMIT, env.ATLAS_PREVIOUS_RELEASE_MANIFEST_SHA256);
  throw new HttpError(404, "Atlas ref is not an approved publication. No fallback to main.");
}
async function sha256(bytes) {
  return [...new Uint8Array(await crypto.subtle.digest("SHA-256", bytes))].map(b => b.toString(16).padStart(2, "0")).join("");
}
function canonical(text) { return text.replace(/^\uFEFF/, "").replace(/\r\n?/g, "\n"); }
async function readLimited(upstream, limit, signal) {
  if (!upstream.ok) {
    if (upstream.body) await upstream.body.cancel();
    throw new HttpError(502, `Atlas upstream unavailable (${upstream.status}).`);
  }
  if (Number(upstream.headers.get("Content-Length")) > limit) {
    if (upstream.body) await upstream.body.cancel();
    throw new HttpError(502, "Atlas upstream response exceeds its size limit.");
  }
  if (!upstream.body) throw new HttpError(502, "Empty Atlas upstream response.");
  const reader = upstream.body.getReader();
  const cancel = () => { void reader.cancel().catch(() => {}); };
  signal.addEventListener("abort", cancel, { once: true });
  const chunks = [];
  let size = 0;
  try {
    for (;;) {
      const { value, done } = await reader.read();
      if (signal.aborted) throw new HttpError(504, "Atlas upstream timed out.");
      if (done) break;
      size += value.byteLength;
      if (size > limit) { await reader.cancel(); throw new HttpError(502, "Atlas upstream response exceeds its size limit."); }
      chunks.push(value);
    }
  } finally { signal.removeEventListener("abort", cancel); reader.releaseLock(); }
  const bytes = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength; }
  return bytes;
}
// The deadline includes headers and the full bounded body for either upstream.
export async function fetchLimited(url, options, limit, timeoutMs = 15000) {
  const controller = new AbortController();
  let timer;
  const deadline = new Promise((_, reject) => {
    timer = setTimeout(() => {
      reject(new HttpError(504, "Atlas upstream timed out."));
      controller.abort();
    }, timeoutMs);
  });
  const load = async () => {
    const upstream = await fetch(url, { ...options, signal: controller.signal });
    if (controller.signal.aborted) {
      if (upstream.body) void upstream.body.cancel().catch(() => {});
      throw new HttpError(504, "Atlas upstream timed out.");
    }
    return readLimited(upstream, limit, controller.signal);
  };
  try { return await Promise.race([load(), deadline]); }
  finally { clearTimeout(timer); }
}
async function publicFile(path, commit, limit = 1024 * 1024) {
  return fetchLimited(`https://raw.githubusercontent.com/${PUBLIC_REPO}/${commit}/${path}`, {
    headers: { "User-Agent": "atlas-launcher-worker" },
    cf: { cacheTtlByStatus: { "200-299": 86400, "400-599": 0 }, cacheEverything: true }
  }, limit);
}
async function publication(env, ref) {
  const approved = selectRelease(env, ref);
  const bytes = await publicFile("release-manifest.json", approved.commit, 128 * 1024);
  if (await sha256(bytes) !== approved.manifestSha256) throw new HttpError(502, "Atlas publication manifest failed verification.");
  const manifest = JSON.parse(decoder.decode(bytes));
  if (manifest.schemaVersion !== 1 || manifest.algorithm !== "SHA256-UTF8-LF" || !manifest.files) throw new HttpError(502, "Unsupported Atlas publication manifest.");
  return { approved, manifest, bytes };
}
async function verifiedFile(path, release) {
  const expected = release.manifest.files[path];
  if (!/^[a-f0-9]{64}$/.test(expected || "")) throw new HttpError(502, "Atlas publication member is missing.");
  const bytes = await publicFile(path, release.approved.commit);
  if (await sha256(encoder.encode(canonical(decoder.decode(bytes)))) !== expected) throw new HttpError(502, "Atlas publication member failed verification.");
  return bytes;
}
async function route(request, env) {
  const url = new URL(request.url);
  const path = url.pathname.toLowerCase();
  if (path === "/healthz") return response(200, "ok\n");
  // These are deliberately public client-distribution endpoints. A private GitHub
  // repository protects source hosting, not anonymous access to this installer.
  // Never cache the private upstream or reflect the public Atlas ref into it.
  if (path === "/install.ps1" || path === "/install.ps1.sha256") {
    const commit = env.ATLAS_ONBOARDING_COMMIT;
    const expected = env.ATLAS_ONBOARDING_SHA256;
    if (!env.GITHUB_PAT || !/^[a-f0-9]{40}$/.test(commit || "") || !/^[a-f0-9]{64}$/.test(expected || "")) return response(503, "Atlas onboarding is not configured.\n");
    const bytes = await fetchLimited(`https://api.github.com/repos/${PRIVATE_REPO}/contents/install-rustdesk.ps1?ref=${commit}`, {
      headers: { Accept: "application/vnd.github.v3.raw", "User-Agent": "atlas-launcher-worker", Authorization: `Bearer ${env.GITHUB_PAT}`, "Cache-Control": "no-store" },
      cf: { cacheTtl: 0, cacheEverything: false }
    }, 2 * 1024 * 1024);
    if (await sha256(bytes) !== expected) throw new HttpError(502, "Atlas onboarding failed verification.");
    const headers = { "X-Atlas-Onboarding-Ref": commit, "X-Atlas-Onboarding-Sha256": expected };
    return response(200, path.endsWith(".sha256") ? `${expected}  install-rustdesk.ps1\n` : bytes, headers);
  }
  if (!["/", "/get.ps1", "/release.json", "/release-manifest.json", "/launcher.sha256", "/tool-hashes.sha256", "/install.bat"].includes(path)) return response(404, "Atlas route not found.\n");
  const release = await publication(env, url.searchParams.get("ref"));
  const headers = { "X-Atlas-Source-Ref": release.approved.commit, "X-Atlas-Manifest-Sha256": release.approved.manifestSha256 };
  if (path === "/release.json") return response(200, JSON.stringify(release.approved) + "\n", { ...headers, "Content-Type": "application/json; charset=utf-8" });
  if (path === "/release-manifest.json") return response(200, release.bytes, { ...headers, "Content-Type": "application/json; charset=utf-8" });
  if (path === "/launcher.sha256" || path === "/tool-hashes.sha256") {
    const file = path === "/launcher.sha256" ? "launcher.ps1" : "config/tool-hashes.json";
    return response(200, `${await sha256(await verifiedFile(file, release))}  ${file.split("/").pop()}\n`, headers);
  }
  if (path === "/install.bat") return response(200, await verifiedFile("onboarding/install.bat", release), { ...headers, "Content-Type": "application/x-bat", "Content-Disposition": 'attachment; filename="install.bat"' });
  let bootstrap = decoder.decode(await verifiedFile("get.ps1", release));
  if (!bootstrap.includes("'__ATLAS_RELEASE_COMMIT__'") || !bootstrap.includes("'__ATLAS_RELEASE_MANIFEST_SHA256__'")) throw new HttpError(502, "Atlas bootstrap template is incompatible.");
  bootstrap = bootstrap.replaceAll("'__ATLAS_RELEASE_COMMIT__'", `'${release.approved.commit}'`).replaceAll("'__ATLAS_RELEASE_MANIFEST_SHA256__'", `'${release.approved.manifestSha256}'`);
  return response(200, bootstrap, headers);
}
export default {
  async fetch(request, env) {
    if (request.method !== "GET" && request.method !== "HEAD") return response(405, "Method not allowed.\n", { Allow: "GET, HEAD" });
    let result;
    try { result = await route(request, env); }
    catch (error) { result = response(error instanceof HttpError ? error.status : 502, error instanceof HttpError ? error.message + "\n" : "Atlas publication unavailable.\n"); }
    if (request.method === "HEAD") return new Response(null, { status: result.status, headers: result.headers });
    return result;
  }
};
