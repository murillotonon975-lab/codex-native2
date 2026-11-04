#!/usr/bin/env node
// Codex Native2 — inventario LOCAL, sem tokens nem chamadas de ferramentas.
// As ferramentas do ChatGPT so podem ser descobertas no host da conversa autorizada.
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { homedir } from 'node:os';
import { pathToFileURL } from 'node:url';
import { readLauncherConfig, verifyRuntimeConfig, probeStdio } from './Verificar-Catalogo-MCP.mjs';

const run = promisify(execFile);
const SAFE_STATUSES = new Set(['authenticated', 'unauthenticated', 'not_supported', 'unknown', 'oauth', 'api_key', 'error']);
const SERVER_NAME = /^[a-zA-Z0-9_.-]{1,120}$/;

export function summarizeCliMcp(raw) {
  if (!Array.isArray(raw)) throw new Error('MCP_LIST_SHAPE_INVALID');
  return raw.map(row => {
    if (!row || typeof row !== 'object' || !SERVER_NAME.test(row.name)) {
      throw new Error('MCP_SERVER_NAME_INVALID');
    }
    const status = typeof row.auth_status === 'string' && SAFE_STATUSES.has(row.auth_status.toLowerCase())
      ? row.auth_status.toLowerCase() : 'unspecified';
    return {
      source: 'codex-cli',
      name: row.name,
      enabled: row.enabled === true,
      authStatus: status,
      toolsEnumerated: false,
    };
  }).sort((a, b) => a.name.localeCompare(b.name));
}

export function summarizeSessionTools(raw) {
  // Somente um host explicitamente autorizado pode fornecer esse catalogo.
  // Nao copia tokens, URLs, objetos de argumentos ou resultados para este processo.
  if (!Array.isArray(raw)) throw new Error('HOST_CATALOG_SHAPE_INVALID');
  return raw.map(row => {
    if (!row || typeof row.name !== 'string' || !SERVER_NAME.test(row.name)) throw new Error('HOST_TOOL_NAME_INVALID');
    return { source: 'chatgpt-session', name: row.name, callableInThisSession: row.callable === true };
  });
}

export function snapshot({ cli, native, host }) {
  return {
    format: 'codex-native2-inventory',
    version: 1,
    computer: {
      status: cli ? 'listed' : 'unavailable',
      servers: cli ?? [],
    },
    nativeMcp: native ?? { status: 'not_tested', toolNames: [] },
    chatgpt: host === undefined
      ? { status: 'requires_authorized_chatgpt_session', tools: [] }
      : { status: 'host_provided', tools: summarizeSessionTools(host) },
    endToEndVerified: false,
    note: 'Listar servidores e ferramentas locais nao comprova acesso ao ChatGPT nem autoriza tools/call.',
  };
}

export async function detectLocalSources({ executable, readConfig = readLauncherConfig, timeoutMs = 10000 } = {}) {
  const defaultExe = process.platform === 'win32'
    ? join(process.env.LOCALAPPDATA || join(homedir(), 'AppData', 'Local'),
      'Programs', 'OpenAI', 'Codex', 'bin', 'codex.exe')
    : 'codex';
  const exe = executable || (existsSync(defaultExe) ? defaultExe : 'codex');
  let cli = null;
  let native = null;
  const problems = [];
  try {
    const { stdout } = await run(exe, ['mcp', 'list', '--json'], {
      timeout: timeoutMs, maxBuffer: 256 * 1024, windowsHide: true, shell: false,
    });
    // JSON bruto pode conter argumentos, caminhos e variaveis secretas: jamais registrar.
    cli = summarizeCliMcp(JSON.parse(stdout));
  } catch { problems.push('CODEX_CLI_MCP_LIST_UNAVAILABLE'); }
  try {
    const res = await probeStdio(verifyRuntimeConfig(readConfig()));
    native = { status: res.missing.length ? 'incomplete' : 'announced',
      toolNames: res.toolNames, expected: res.expected, found: res.found };
  } catch { problems.push('NATIVE_MCP_TOOLS_LIST_UNAVAILABLE'); }
  return { ...snapshot({ cli, native }), problems };
}

async function main() {
  const args = process.argv.slice(2);
  if (args.includes('--help')) {
    console.log('node scripts/Inventariar-Integracoes.mjs [--json]');
    console.log('Lista MCPs do Codex CLI e tools/list do runtime local, sem executar ferramentas.');
    console.log('Plugins do ChatGPT so sao enumerados dentro de sessoes autorizadas no proprio ChatGPT.');
    return;
  }
  if (args.some(x => x !== '--json')) {
    console.error('UNKNOWN_OPTION');
    process.exitCode = 1;
    return;
  }
  const state = await detectLocalSources();
  if (args.includes('--json')) {
    console.log(JSON.stringify(state, null, 2));
    return;
  }
  console.log('CODEX NATIVE2 — FONTES DE FERRAMENTAS (SOMENTE LEITURA)');
  console.log('Codex CLI: ' + (state.computer.status === 'listed' ? state.computer.servers.length + ' MCPs registrados' : 'nao disponivel'));
  for (const server of state.computer.servers) {
    console.log('  - ' + server.name + ' | ' + (server.enabled ? 'habilitado' : 'desabilitado'));
  }
  console.log('Runtime MCP local: ' + (state.nativeMcp.status || 'nao testado'));
  console.log('  - ' + (state.nativeMcp.toolNames || []).join(', '));
  console.log('Ferramentas/plugins ChatGPT: exigem descoberta na conversa autorizada.');
  console.log('O inventario local NAO prova encaminhamento nem execucao das ferramentas na tarefa.');
  if (state.problems.length) console.log('Pendencias: ' + state.problems.join(', '));
}
if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) await main();
