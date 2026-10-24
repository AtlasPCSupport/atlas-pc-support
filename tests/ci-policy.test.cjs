const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const workflow = fs.readFileSync(path.join(__dirname, '../.github/workflows/auto-merge.yml'), 'utf8');
const source = workflow.split('script: |\n')[1].split('\n').map(line => line.replace(/^ {12}/, '')).join('\n');
const AsyncFunction = Object.getPrototypeOf(async function(){}).constructor;
const run = new AsyncFunction('github','context','core',source);
async function evaluate(change = {}) {
  const sha = 'a'.repeat(40);
  const pr = {number:1,state:'open',draft:false,user:{login:'devin-ai-integration[bot]'},head:{sha,repo:{id:1}},base:{sha:'b'.repeat(40),ref:'main',repo:{id:1}},changed_files:1,labels:[{name:'auto-merge-ok'}], ...change.pr};
  let reads=0; const merged=[]; const removed=[];
  const api = {
    pulls: {
      get: async () => ({data: ++reads > 1 ? {...pr, ...change.current} : pr}),
      listFiles: () => {}, listReviews: () => {},
      merge: async args => { merged.push(args); }
    },
    issues: {removeLabel: async args => {removed.push(args);}},
    actions: {listWorkflowRuns: async () => ({data:{workflow_runs:[{id:2,head_sha:sha,status:'completed',conclusion:'success',...change.run}]}}), listJobsForWorkflowRun: () => {}}
  };
  const github = {rest:api,paginate:async fn => {
    if(fn===api.pulls.listFiles) return change.files || [{filename:'docs/guide.md'}];
    if(fn===api.pulls.listReviews) return change.reviews || [{id:1,state:'APPROVED',commit_id:sha,user:{login:'maintainer',type:'User'},author_association:'MEMBER'}];
    if(fn===api.actions.listJobsForWorkflowRun) return change.jobs || ['build','windows-compat','worker'].map(name=>({name,conclusion:'success'}));
    throw new Error('Unexpected API call');
  }};
  await run(github,{repo:{owner:'AtlasPCSupport',repo:'atlas-pc-support'},payload:{pull_request:{number:1}}},{info:()=>{}});
  return {merged,removed};
}
test('merges reviewed documentation using the exact checked head',async()=>{
  const {merged}=await evaluate(); assert.equal(merged.length,1); assert.equal(merged[0].sha,'a'.repeat(40));
});
test('a stale label cannot authorize tools, worker, tests, GUI or release files',async()=>{
  for(const filename of ['src/tools/Invoke-X.ps1','src/gui/MainWindow.ps1','api/cloudflare-worker/worker.js','tests/Lib.Tests.ps1','release-manifest.json','config/tools.json','.github/workflows/build.yml','docs/ci/build.yml']) {
    const result=await evaluate({files:[{filename}]}); assert.equal(result.merged.length,0,filename); assert.equal(result.removed.length,1,filename);
  }
});
test('rename from executable code to documentation still requires human merge',async()=>{
  assert.equal((await evaluate({files:[{filename:'docs/old.md',previous_filename:'src/tools/old.ps1'}]})).merged.length,0);
});
test('an incomplete API diff fails closed',async()=>{assert.equal((await evaluate({pr:{changed_files:2}})).merged.length,0);});
test('approval of a previous commit is insufficient',async()=>{
  assert.equal((await evaluate({reviews:[{id:1,state:'APPROVED',commit_id:'old',user:{login:'maintainer',type:'User'},author_association:'MEMBER'}]})).merged.length,0);
});
test('a current changes-requested review blocks merge',async()=>{
  assert.equal((await evaluate({reviews:[{id:2,state:'CHANGES_REQUESTED',user:{login:'maintainer'}}]})).merged.length,0);
});
test('missing Windows checks or a failed workflow block merge',async()=>{
  assert.equal((await evaluate({jobs:[{name:'build',conclusion:'success'},{name:'worker',conclusion:'success'}]})).merged.length,0);
  assert.equal((await evaluate({run:{conclusion:'failure'}})).merged.length,0);
});
test('head or base movement before merge blocks the action',async()=>{
  assert.equal((await evaluate({current:{head:{sha:'new'}}})).merged.length,0);
  assert.equal((await evaluate({current:{base:{sha:'new'}}})).merged.length,0);
});
test('foreign authors, forks and draft PRs never enter automatic merge',async()=>{
  for(const pr of [{user:{login:'other'}},{head:{sha:'a'.repeat(40),repo:{id:2}}},{draft:true}]) assert.equal((await evaluate({pr})).merged.length,0);
});
