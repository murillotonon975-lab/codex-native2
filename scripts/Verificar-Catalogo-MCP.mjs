#!/usr/bin/env node
// Codex Native2 - verifica tools/list no runtime MCP local, SEM token e SEM tools/call.
import { existsSync, readFileSync, statSync } from 'node:fs';
import { spawn } from 'node:child_process';
import { basename, join, resolve } from 'node:path';
import { homedir } from 'node:os';
import { pathToFileURL } from 'node:url';

export const REQUIRED_TOOLS = Object.freeze([
  'codex_exec', 'codex_write_stdin', 'codex_apply_patch',
  'codex_view_image', 'codex_tool_inventory', 'codex_tool_call',
]);

export function verifyRuntimeConfig(config) {
  if (!config || typeof config !== 'object' || Array.isArray(config)) throw new Error('CONFIG_INVALID');
  if (config.mode !== 'full') throw new Error('FULL_HARNESS_NOT_ENABLED');
  if (!Array.isArray(config.runtimeCommand) || config.runtimeCommand.length !== 2 ||
      !config.runtimeCommand.every(x => typeof x === 'string' && x.length > 0)) {
    throw new Error('RUNTIME_COMMAND_INVALID');
  }
  const [exe, entrypoint] = config.runtimeCommand;
  if (!['bun.exe', 'bun', 'node.exe', 'node'].includes(basename(exe).toLowerCase()) ||
      basename(entrypoint).toLowerCase() !== 'cli.js') throw new Error('UNRECOGNIZED_RUNTIME_COMMAND');
  if (!existsSync(exe) || !existsSync(entrypoint)) throw new Error('RUNTIME_FILES_MISSING');
  if (typeof config.brokerSocketPath !== 'string' || !config.brokerSocketPath.trim())
    throw new Error('BROKER_SOCKET_NOT_CONFIGURED');
  return { exe, entrypoint, brokerSocketPath: config.brokerSocketPath };
}

export function summarizeCatalog(tools) {
  if (!Array.isArray(tools) || tools.some(t => !t || typeof t.name !== 'string')) {
    throw new Error('MCP_CATALOG_INVALID');
  }
  const names = [...new Set(tools.map(t => t.name))];
  const missing = REQUIRED_TOOLS.filter(name => !names.includes(name));
  return {
    catalogVisible: true, expected: REQUIRED_TOOLS.length,
    found: names.filter(n => REQUIRED_TOOLS.includes(n)).length,
    missing, toolNames: names.filter(n => REQUIRED_TOOLS.includes(n)).sort(),
    remoteConnectorVerified: false, turnBoundExecutionVerified: false,
  };
}

export async function probeStdio({ exe, entrypoint, brokerSocketPath, timeoutMs = 12000 }) {
  const child = spawn(exe, [entrypoint, 'mcp', '--contract', 'native', '--broker-socket', brokerSocketPath], {
    stdio: ['pipe', 'pipe', 'pipe'], windowsHide: true, shell: false,
  });
  let buffer = '';
  let completed = false;
  let timer;
  let resolveResult;
  let rejectResult;
  const done = new Promise((res, rej) => { resolveResult = res; rejectResult = rej; });

  function finish(error, value) {
    if (completed) return;
    completed = true;
    clearTimeout(timer);
    child.stdin.end();
    // Encerra apenas este processo temporario, nao o runtime gerenciado pelo launcher.
    if (child.exitCode === null) child.kill();
    if (error) rejectResult(error); else resolveResult(value);
  }
  function send(message) {
    if (!child.stdin.destroyed) child.stdin.write(JSON.stringify(message) + '\n');
  }
  function processMessage(message) {
    if (message.id === 1) {
      if (message.error) return finish(new Error('MCP_INITIALIZE_REJECTED'));
      send({ jsonrpc: '2.0', method: 'notifications/initialized' });
      send({ jsonrpc: '2.0', id: 2, method: 'tools/list', params: {} });
    } else if (message.id === 2) {
      if (message.error) return finish(new Error('MCP_TOOLS_LIST_REJECTED'));
      try { finish(null, summarizeCatalog(message.result?.tools)); }
      catch { finish(new Error('MCP_CATALOG_INVALID')); }
    }
  }
  child.stdout.setEncoding('utf8');
  child.stdout.on('data', chunk => {
    if (completed) return;
    buffer += chunk;
    if (buffer.length > 512 * 1024) return finish(new Error('MCP_OUTPUT_TOO_LARGE'));
    while (buffer.includes('\n')) {
      const index = buffer.indexOf('\n');
      const line = buffer.slice(0, index).trim();
      buffer = buffer.slice(index + 1);
      if (!line) continue;
      try { processMessage(JSON.parse(line)); } catch { /* nao exibir linhas inesperadas */ }
    }
  });
  child.stderr.resume(); // descartado: pode conter caminhos, tokens e dados privados
  child.on('error', () => finish(new Error('MCP_RUNTIME_SPAWN_FAILED')));
  child.on('exit', () => { if (!completed) finish(new Error('MCP_RUNTIME_EXITED_EARLY')); });
  timer = setTimeout(() => finish(new Error('MCP_TOOLS_LIST_TIMEOUT')), timeoutMs);
  send({ jsonrpc: '2.0', id: 1, method: 'initialize', params: {
    protocolVersion: '2025-03-26',
    capabilities: {}, clientInfo: { name: 'codex-native2-read-only-probe', version: '0.1.0' },
  }});
  return done;
}

export function readLauncherConfig(configPath = join(homedir(), '.codex-chatgpt-web', 'config.json')) {
  if (statSync(configPath).size > 256 * 1024) throw new Error('CONFIG_TOO_LARGE');
  return JSON.parse(readFileSync(configPath, 'utf8'));
}

async function main() {
  const argv = process.argv.slice(2);
  if (argv.some(x => !['--json', '--help'].includes(x))) throw new Error('UNKNOWN_OPTION');
  if (argv.includes('--help')) {
    console.log('node scripts/Verificar-Catalogo-MCP.mjs [--json]');
    console.log('Somente leitura: consulta tools/list local; nao verifica ChatGPT ou uma tarefa.');
    return;
  }
  try {
    const result = await probeStdio(verifyRuntimeConfig(readLauncherConfig()));
    if (argv.includes('--json')) console.log(JSON.stringify(result));
    else {
      console.log('Catalogo MCP local: ' + result.found + '/' + result.expected + ' ferramentas esperadas');
      console.log('Nomes anunciados: ' + (result.toolNames.join(', ') || '(nenhum)'));
      if (result.missing.length) console.log('Ausentes: ' + result.missing.join(', '));
      console.log('Conector ChatGPT: NAO TESTADO; execucao com turn_token: NAO TESTADA');
    }
    if (result.missing.length) process.exitCode = 2;
  } catch (e) {
    const codes = new Set(['CONFIG_INVALID', 'CONFIG_TOO_LARGE', 'FULL_HARNESS_NOT_ENABLED',
      'RUNTIME_COMMAND_INVALID', 'UNRECOGNIZED_RUNTIME_COMMAND', 'RUNTIME_FILES_MISSING',
      'BROKER_SOCKET_NOT_CONFIGURED', 'MCP_INITIALIZE_REJECTED', 'MCP_TOOLS_LIST_REJECTED',
      'MCP_CATALOG_INVALID', 'MCP_OUTPUT_TOO_LARGE', 'MCP_RUNTIME_SPAWN_FAILED',
      'MCP_RUNTIME_EXITED_EARLY', 'MCP_TOOLS_LIST_TIMEOUT', 'UNKNOWN_OPTION']);
    console.error('Falha do teste MCP local: ' + (codes.has(e?.message) ? e.message : 'CONFIG_OR_RUNTIME_UNAVAILABLE'));
    process.exitCode = 1;
  }
}
if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) await main();
