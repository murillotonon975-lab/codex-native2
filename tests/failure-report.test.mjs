import test from 'node:test';
import assert from 'node:assert/strict';
import { inWindowsRoot, summarizeRollout, summarizeMultiple, buildIssue, validateProof, MARKER } from '../scripts/Relatorio-Falhas-GitHub.mjs';

const json = rows => rows.map(x=>JSON.stringify(x)).join('\n');
const sample = json([
  {type:'session_meta',payload:{runtime_workspace_roots:['D:\\Codex'],token:'sk-secret-would-not-be-published'}},
  {type:'turn_context',payload:{cwd:'D:\\Codex\\project'}},
  {type:'turn_context',payload:{cwd:'C:\\Users\\private\\Documents\\ChatGPT\\Plugins',prompt:'private conversation'}},
  {type:'event_msg',timestamp:'2026-11-04T17:40:00Z',payload:{error:{message:'stream disconnected: Codex rollout cwd is outside its workspace roots',token:'private-token'}}}
]);

test('windows paths require an actual descendant directory',()=>{
  assert.equal(inWindowsRoot('D:\\Codex','d:\\CODEX\\project'),true);
  assert.equal(inWindowsRoot('D:\\Codex','D:\\Codex2'),false);
  assert.equal(inWindowsRoot('D:\\Codex','C:\\Codex'),false);
  assert.equal(inWindowsRoot('D:\\Codex','D:\\Codex\\..\\secret'),false);
});

test('only counts and dates are extracted from JSONL',()=>{
  assert.deepEqual(summarizeRollout(sample),{turns:2,outside:1,errors:1,lastError:'2026-11-04'});
  assert.deepEqual(summarizeMultiple([sample]).files,1);
  const issue=buildIssue({
    dateUTC:'2026-11-04',local:{status:'announced',found:6},
    rollouts:summarizeMultiple([sample]),host:'not_verified',nativeRead:'not_verified',
    extra:'sk-very-private',
  });
  assert.ok(issue.body.startsWith(MARKER));
  for(const forbidden of ['sk-secret','private-token','C:\\Users','private conversation','sk-very-private','D:\\Codex']){
    assert.equal(issue.body.includes(forbidden),false,forbidden);
  }
  assert.match(issue.body,/codex_tool_inventory anunciado no host: PENDENTE/);
  assert.match(issue.body,/Chamada nativa de leitura: PENDENTE/);
});

test('local catalog 6 of 6 alone never clears remote verification',()=>{
  assert.throws(()=>validateProof({
    schema:'codex-native2-resolution-v1',source:'authorized-chatgpt-task',
    workspaceRolloutPassed:true,hostInventoryAnnounced:false,nativeReadSucceeded:false,
    checkedAt:new Date().toISOString(),
  }),/REMOTE_TESTS_REQUIRED/);
  assert.throws(()=>validateProof({
    schema:'codex-native2-resolution-v1',source:'local-mcp-probe',
    workspaceRolloutPassed:true,hostInventoryAnnounced:true,nativeReadSucceeded:true,
    checkedAt:new Date().toISOString(),
  }),/INVALID_HOST_PROOF/);
});

test('explicit recent proof requires all three remote checks',()=>{
  assert.equal(validateProof({
    schema:'codex-native2-resolution-v1',source:'authorized-chatgpt-task',
    workspaceRolloutPassed:true,hostInventoryAnnounced:true,nativeReadSucceeded:true,
    checkedAt:new Date().toISOString(),
  }),true);
  assert.throws(()=>validateProof({
    schema:'codex-native2-resolution-v1',source:'authorized-chatgpt-task',
    workspaceRolloutPassed:true,hostInventoryAnnounced:true,nativeReadSucceeded:true,
    checkedAt:'2020-01-01T00:00:00Z',
  }),/STALE_HOST_PROOF/);
});
