import { test, beforeEach, afterEach } from "node:test";
import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import worker from "../src/index.js";

const sha = text => createHash("sha256").update(text).digest("hex");
const commit = "a".repeat(40);
const bootstrap = "$publishedCommit = '__ATLAS_RELEASE_COMMIT__'\n$publishedManifest = '__ATLAS_RELEASE_MANIFEST_SHA256__'\n# fixture\n";
const launcher = "# fixture launcher\n";
const toolHashes = '{"files":{}}';
const bat = "@echo off\n";
const manifest = JSON.stringify({schemaVersion:1,version:"fixture",algorithm:"SHA256-UTF8-LF",files:{"get.ps1":sha(bootstrap),"launcher.ps1":sha(launcher),"config/tool-hashes.json":sha(toolHashes),"onboarding/install.bat":sha(bat)}});
let calls, env, originalFetch, bodies;
beforeEach(() => {
  calls = [];
  env = {ATLAS_RELEASE_COMMIT:commit,ATLAS_RELEASE_MANIFEST_SHA256:sha(manifest)};
  bodies = new Map([["release-manifest.json",manifest],["get.ps1",bootstrap],["launcher.ps1",launcher],["config/tool-hashes.json",toolHashes],["onboarding/install.bat",bat]]);
  originalFetch = globalThis.fetch;
  globalThis.fetch = async (url, options) => {
    calls.push({url,options});
    const path = new URL(url).pathname.split("/").slice(4).join("/");
    return bodies.has(path) ? new Response(bodies.get(path)) : new Response("missing", {status:404});
  };
});
afterEach(() => { globalThis.fetch = originalFetch; });
const request = (path="/", options={}) => worker.fetch(new Request("https://toolspanel.atlaspcsupport.com"+path,options),env);

test("root verifies the bootstrap and binds it to the approved immutable publication", async () => {
  const result=await request();
  assert.equal(result.status,200);
  const body=await result.text();
  assert.ok(body.includes(`'${commit}'`));
  assert.ok(body.includes(`'${sha(manifest)}'`));
  assert.ok(!body.includes("__ATLAS_RELEASE_"));
  assert.equal(result.headers.get("X-Atlas-Source-Ref"),commit);
  assert.equal(result.headers.get("Cache-Control"),"no-store");
  assert.ok(calls.every(c=>c.url.includes(`/${commit}/`)));
});
test("publication descriptor and manifest agree with the independent deployment pin", async () => {
  assert.deepEqual(await (await request("/release.json")).json(),{schemaVersion:1,commit,manifestSha256:sha(manifest)});
  assert.equal(await (await request("/release-manifest.json")).text(),manifest);
});
test("main is an alias of the approved publication, never a live upstream ref", async () => {
  assert.equal((await request("/?ref=main")).status,200);
  assert.ok(calls.every(c=>!c.url.includes("/main/")));
});
test("an unpublished ref fails without silently changing version", async () => {
  assert.equal((await request("/?ref=missing-branch")).status,404);
  assert.equal(calls.length,0);
});
test("malformed refs fail clearly", async () => {
  assert.equal((await request("/?ref=%27%3Bbad")).status,400);
  assert.equal(calls.length,0);
});
test("an unapproved full SHA also fails", async () => {
  assert.equal((await request("/?ref="+"f".repeat(40))).status,404);
  assert.equal(calls.length,0);
});
test("the previous approved commit can be selected explicitly", async () => {
  const previous="b".repeat(40);
  env.ATLAS_PREVIOUS_RELEASE_COMMIT=previous;
  env.ATLAS_PREVIOUS_RELEASE_MANIFEST_SHA256=sha(manifest);
  assert.equal((await request("/?ref="+previous)).status,200);
  assert.ok(calls.every(c=>c.url.includes(`/${previous}/`)));
});
test("a repository manifest change cannot override the deployment authority", async () => {
  bodies.set("release-manifest.json",manifest+" ");
  const result=await request();
  assert.equal(result.status,502);
  assert.match(await result.text(),/manifest failed/);
});
test("a modified bootstrap is never returned for execution", async () => {
  bodies.set("get.ps1",bootstrap+"# changed");
  assert.equal((await request()).status,502);
});
test("missing publication pins fail closed", async () => {
  delete env.ATLAS_RELEASE_MANIFEST_SHA256;
  assert.equal((await request()).status,503);
  assert.equal(calls.length,0);
});
test("unknown paths are not bootstrap aliases", async () => {
  assert.equal((await request("/missing.ps1")).status,404);
  assert.equal(calls.length,0);
});
test("unsupported methods fail before any upstream call", async () => {
  const result=await request("/",{method:"POST"});
  assert.equal(result.status,405);
  assert.equal(result.headers.get("Allow"),"GET, HEAD");
  assert.equal(calls.length,0);
});
test("HEAD returns the same status and metadata with an empty body", async () => {
  const result=await request("/",{method:"HEAD"});
  assert.equal(result.status,200);
  assert.equal(await result.text(),"");
  assert.equal(result.headers.get("X-Atlas-Source-Ref"),commit);
});
test("a missing immutable file produces an error, never a main fallback", async () => {
  bodies.delete("get.ps1");
  assert.equal((await request()).status,502);
  assert.ok(calls.every(c=>c.url.includes(`/${commit}/`)));
});
test("network errors return a bounded error without upstream details", async () => {
  globalThis.fetch=async()=>{throw new Error("sensitive upstream message");};
  const result=await request();
  assert.equal(result.status,502);
  assert.ok(!(await result.text()).includes("sensitive"));
});
test("oversized upstream bodies are rejected", async () => {
  globalThis.fetch=async()=>new Response("fixture",{headers:{"Content-Length":"999999999"}});
  assert.equal((await request()).status,502);
});
test("invalid JSON cannot masquerade as an approved manifest", async () => {
  bodies.set("release-manifest.json","not json");
  env.ATLAS_RELEASE_MANIFEST_SHA256=sha("not json");
  assert.equal((await request()).status,502);
});
test("legacy checksum routes verify content and return byte digests", async () => {
  bodies.set("launcher.ps1","\uFEFF"+launcher);
  const result=await request("/launcher.sha256");
  assert.equal(result.status,200);
  assert.equal(await result.text(),sha("\uFEFF"+launcher)+"  launcher.ps1\n");
  assert.equal(await (await request("/tool-hashes.sha256")).text(),sha(toolHashes)+"  tool-hashes.json\n");
});
test("the public batch installer is verified at the same approved commit", async () => {
  const result=await request("/install.bat");
  assert.equal(result.status,200);
  assert.equal(await result.text(),bat);
  assert.match(result.headers.get("Content-Disposition"),/install.bat/);
});
test("onboarding without its existing private-source credential fails closed", async () => {
  assert.equal((await request("/install.ps1")).status,503);
  assert.equal(calls.length,0);
});
test("private-source onboarding does not cache content or accept the public ref", async () => {
  env.GITHUB_PAT="fixture-token";
  env.ATLAS_ONBOARDING_COMMIT="c".repeat(40);
  env.ATLAS_ONBOARDING_SHA256=sha("# fixture private installer");
  globalThis.fetch=async(url,options)=>{calls.push({url,options});return new Response("# fixture private installer");};
  const result=await request("/install.ps1?ref=untrusted-branch");
  assert.equal(result.status,200);
  assert.equal(result.headers.get("Cache-Control"),"no-store");
  assert.ok(calls[0].url.endsWith("?ref="+env.ATLAS_ONBOARDING_COMMIT));
  assert.equal(result.headers.get("X-Atlas-Onboarding-Ref"),env.ATLAS_ONBOARDING_COMMIT);
  assert.equal(calls[0].options.cf.cacheEverything,false);
  assert.equal(calls[0].options.cf.cacheTtl,0);
  assert.ok(!(await result.text()).includes("fixture-token"));
});
test("onboarding requires its own independent commit and byte digest", async () => {
  env.GITHUB_PAT="fixture-token";
  env.ATLAS_ONBOARDING_COMMIT=commit;
  assert.equal((await request("/install.ps1")).status,503);
  assert.equal(calls.length,0);
});
test("a changed private installer is rejected for both installer and checksum routes", async () => {
  env.GITHUB_PAT="fixture-token";
  env.ATLAS_ONBOARDING_COMMIT="c".repeat(40);
  env.ATLAS_ONBOARDING_SHA256=sha("approved");
  globalThis.fetch=async()=>new Response("modified");
  assert.equal((await request("/install.ps1")).status,502);
  assert.equal((await request("/install.ps1.sha256")).status,502);
});
test("the onboarding checksum derives from the same verified raw bytes including BOM", async () => {
  const bytes="\uFEFF# approved\r\n";
  env.GITHUB_PAT="fixture-token";
  env.ATLAS_ONBOARDING_COMMIT="c".repeat(40);
  env.ATLAS_ONBOARDING_SHA256=sha(bytes);
  globalThis.fetch=async(url,options)=>{calls.push({url,options});return new Response(bytes);};
  const result=await request("/install.ps1.sha256");
  assert.equal(result.status,200);
  assert.equal(await result.text(),sha(bytes)+"  install-rustdesk.ps1\n");
  assert.ok(calls[0].url.includes("contents/install-rustdesk.ps1?ref="));
  assert.equal(result.headers.get("Cache-Control"),"no-store");
});
