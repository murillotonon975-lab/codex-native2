#!/usr/bin/env node
// Codex Native2: publica somente contagens e codigos diagnosticos; nunca logs brutos.
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { homedir } from 'node:os';
import { join, win32, resolve } from 'node:path';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { pathToFileURL } from 'node:url';
import { REQUIRED_TOOLS, probeStdio, readLauncherConfig, verifyRuntimeConfig } from './Verificar-Catalogo-MCP.mjs';

export const REPO='murillotonon975-lab/codex-native2';
export const MARKER='<!-- codex-native2-diagnostic-report:v1 -->';
export const TITLE='[Codex Native2] Relatorio sanitizado de falha MCP';
const run=promisify(execFile);
const MAX_ROLLOUT=5*1024*1024;
const MAX_BODY=16000;
const date=s=>{const d=new Date(s);return Number.isNaN(d.getTime())?null:d.toISOString().slice(0,10)};
export function inWindowsRoot(root,cwd){
  if(typeof root!=='string'||typeof cwd!=='string'||!win32.isAbsolute(root)||!win32.isAbsolute(cwd))return false;
  const rel=win32.relative(win32.normalize(root),win32.normalize(cwd));
  return rel===''||(rel!=='..'&&!rel.startsWith('..\\')&&!win32.isAbsolute(rel));
}
export function summarizeRollout(raw){
  if(typeof raw!=='string'||Buffer.byteLength(raw)>MAX_ROLLOUT)return null;
  let roots=[],turns=0,outside=0,errors=0,lastError=null;
  for(const line of raw.split(/\r?\n/)){
    if(!line.trim())continue;
    let x;try{x=JSON.parse(line)}catch{continue}
    if(x.type==='session_meta'){
      roots=Array.isArray(x.payload?.runtime_workspace_roots)?x.payload.runtime_workspace_roots:[];
    }else if(x.type==='turn_context'){
      turns++;
      const p=x.payload??{};
      const current=Array.isArray(p.workspace_roots)?p.workspace_roots:roots;
      if(!current.some(root=>inWindowsRoot(root,p.cwd)))outside++;
    }else if(x.type==='event_msg'){
      const message=x.payload?.error?.message;
      if(typeof message==='string'&&message.includes('Codex rollout cwd is outside its workspace roots')){
        errors++;lastError=date(x.timestamp);
      }
    }
  }
  return {turns,outside,errors,lastError};
}
export function summarizeMultiple(raws){
  const all=raws.map(summarizeRollout).filter(Boolean);
  return {files:all.length,turns:all.reduce((a,v)=>a+v.turns,0),outside:all.reduce((a,v)=>a+v.outside,0),errors:all.reduce((a,v)=>a+v.errors,0),lastError:all.map(x=>x.lastError).filter(Boolean).sort().at(-1)??null};
}
function safeSessionFiles(){
  const base=join(homedir(),'.codex','sessions'),files=[];
  for(let offset=0;offset<5;offset++){
    const d=new Date(Date.now()-offset*86400000);
    const folder=join(base,String(d.getFullYear()),String(d.getMonth()+1).padStart(2,'0'),String(d.getDate()).padStart(2,'0'));
    let names=[];try{names=readdirSync(folder)}catch{continue}
    for(const name of names.filter(x=>/^rollout-.*\.jsonl$/.test(x))){
      const path=join(folder,name);
      try{const s=statSync(path);if(s.isFile()&&s.size<=MAX_ROLLOUT)files.push({path,mtime:s.mtimeMs})}catch{}
    }
  }
  return files.sort((a,b)=>b.mtime-a.mtime).slice(0,15).map(x=>x.path);
}
export async function safeDiagnostics(raws){
  let inputs=raws;
  if(!inputs){
    inputs=[];for(const path of safeSessionFiles())try{inputs.push(readFileSync(path,'utf8'))}catch{}
  }
  let local={status:'unavailable',found:0,expected:REQUIRED_TOOLS.length,errorCode:'LOCAL_MCP_NOT_VERIFIED'};
  try{
    const x=await probeStdio(verifyRuntimeConfig(readLauncherConfig()));
    local={status:x.missing.length?'incomplete':'announced',found:x.found,expected:x.expected,errorCode:x.missing.length?'MISSING_LOCAL_TOOLS':null};
  }catch{}
  return {schema:'codex-native2-safe-report-v1',dateUTC:date(new Date()),local,rollouts:summarizeMultiple(inputs),host:'not_verified_locally',nativeRead:'not_verified'};
}
export function buildIssue(data){
  const local=data.local??{}, roll=data.rollouts??{};
  const num=n=>Number.isSafeInteger(n)&&n>=0?n:0;
  const status=['announced','incomplete','unavailable'].includes(local.status)?local.status:'unknown';
  const body=[
    MARKER,
    '## Diagnostico de falha MCP (sanitizado)',
    '',
    '- Data UTC: '+(date(data.dateUTC)??'desconhecida'),
    '- MCP local: '+status+' ('+num(local.found)+'/'+REQUIRED_TOOLS.length+')',
    '- Falha no MCP local: '+(local.errorCode==='LOCAL_MCP_NOT_VERIFIED'?'LOCAL_MCP_NOT_VERIFIED':local.errorCode==='MISSING_LOCAL_TOOLS'?'MISSING_LOCAL_TOOLS':'nenhuma detectada'),
    '- Arquivos de rollout analisados: '+num(roll.files),
    '- Turnos com diretorio fora da raiz: '+num(roll.outside),
    '- Erros de raiz registrados: '+num(roll.errors),
    '- Data da ultima falha: '+(date(roll.lastError)??'nao identificada'),
    '- codex_tool_inventory anunciado no host: PENDENTE DE CONFIRMACAO',
    '- Chamada nativa de leitura: PENDENTE',
    '',
    '## Investigacao',
    '1. Conferir a vinculacao do workspace entre session_meta e turn_context.',
    '2. Conferir registro do conector do ChatGPT e anuncio de ferramentas.',
    '3. Validar codex_tool_inventory e uma chamada de leitura na tarefa autorizada.',
    '4. Apos a verificacao real da correcao, excluir este relatorio do GitHub.',
    '',
    'Nenhuma mensagem de usuario, linha de log bruto, caminho, ID de tunel, token ou segredo foi enviado.',
  ].join('\n');
  if(Buffer.byteLength(body)>MAX_BODY)throw new Error('REPORT_TOO_LARGE');
  return {title:TITLE,body,repository:REPO};
}
async function gh(args){
  try {
    const x=await run('gh',args,{windowsHide:true,maxBuffer:65536,timeout:20000});
    return JSON.parse(x.stdout);
  } catch {
    try { await run('gh',['auth','status'],{windowsHide:true,maxBuffer:8192,timeout:10000}); }
    catch { throw new Error('GITHUB_AUTH_REQUIRED'); }
    throw new Error('GITHUB_API_CALL_FAILED');
  }
}
async function publish(report){
  const x=await gh(['api','--method','POST','repos/'+REPO+'/issues','-f','title='+report.title,'-f','body='+report.body]);
  if(!x?.html_url||!Number.isSafeInteger(x.number))throw new Error('ISSUE_CREATION_UNVERIFIED');
  return {status:'published',url:x.html_url,number:x.number};
}
export function validateProof(p){
  if(!p||p.schema!=='codex-native2-resolution-v1'||p.source!=='authorized-chatgpt-task')throw new Error('INVALID_HOST_PROOF');
  if(p.workspaceRolloutPassed!==true||p.hostInventoryAnnounced!==true||p.nativeReadSucceeded!==true)throw new Error('REMOTE_TESTS_REQUIRED');
  const check=new Date(p.checkedAt);
  if(!Number.isFinite(check.getTime())||check>Date.now()||Date.now()-check.getTime()>86400000)throw new Error('STALE_HOST_PROOF');
  return true;
}
async function deleteReport(issueNumber,proofFile){
  if(!/^[1-9]\d{0,8}$/.test(issueNumber))throw new Error('INVALID_ISSUE_NUMBER');
  let p;try{if(statSync(proofFile).size>16384)throw Error();p=JSON.parse(readFileSync(proofFile,'utf8'))}catch{throw new Error('HOST_PROOF_MISSING')}
  validateProof(p);
  const x=await gh(['api','repos/'+REPO+'/issues/'+issueNumber]);
  if(x.pull_request||x.title!==TITLE||typeof x.body!=='string'||!x.body.startsWith(MARKER)||!x.node_id)throw new Error('NOT_A_NATIVE2_REPORT');
  // Exclusao efetiva da Issue. Fechar ou limpar corpo nao equivale a apagar log no GitHub.
  const query='mutation($issueId:ID!){deleteIssue(input:{issueId:$issueId}){clientMutationId}}';
  const result=await gh(['api','graphql','-f','query='+query,'-F','issueId='+x.node_id]);
  if(!result?.data?.deleteIssue||result.errors?.length)throw new Error('GITHUB_DELETE_UNVERIFIED');
  return {status:'deleted_on_github',issueNumber:Number(issueNumber)};
}
async function main(argv){
  if(argv.includes('--help')){console.log('Uso: node scripts/Relatorio-Falhas-GitHub.mjs [--json | --publish --confirm-publish | --delete ISSUE --proof FILE --confirm-delete]');return}
  if(argv.includes('--delete')){
    if(argv.length!==5||argv[0]!=='--delete'||argv[2]!=='--proof'||argv[4]!=='--confirm-delete')throw new Error('DELETION_NEEDS_PROOF_AND_CONFIRMATION');
    console.log(JSON.stringify(await deleteReport(argv[1],argv[3])));return;
  }
  if(argv.some(x=>!['--json','--publish','--confirm-publish'].includes(x)))throw new Error('UNKNOWN_ARGUMENT');
  if(argv.includes('--publish')!==argv.includes('--confirm-publish'))throw new Error('PUBLICATION_NEEDS_CONFIRMATION');
  const issue=buildIssue(await safeDiagnostics());
  if(argv.includes('--publish')){console.log(JSON.stringify(await publish(issue)));return}
  console.log(argv.includes('--json')?JSON.stringify(issue,null,2):issue.title+'\n\n'+issue.body+'\n\nPREVIA: nenhum dado publicado.');
}
if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href){
  main(process.argv.slice(2)).catch(e=>{
    const known=new Set(['REPORT_TOO_LARGE','ISSUE_CREATION_UNVERIFIED','INVALID_HOST_PROOF','REMOTE_TESTS_REQUIRED','STALE_HOST_PROOF','INVALID_ISSUE_NUMBER','HOST_PROOF_MISSING','NOT_A_NATIVE2_REPORT','GITHUB_DELETE_UNVERIFIED','DELETION_NEEDS_PROOF_AND_CONFIRMATION','UNKNOWN_ARGUMENT','PUBLICATION_NEEDS_CONFIRMATION','GITHUB_AUTH_REQUIRED','GITHUB_API_CALL_FAILED']);
    console.error('ERRO: '+(known.has(e.message)?e.message:'GITHUB_OR_RUNTIME_UNAVAILABLE'));process.exitCode=1;
  });
}
