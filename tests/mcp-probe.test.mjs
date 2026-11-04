import { test } from 'node:test';
import assert from 'node:assert/strict';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { dirname } from 'node:path';
import { REQUIRED_TOOLS, summarizeCatalog, verifyRuntimeConfig, probeStdio } from '../scripts/Verificar-Catalogo-MCP.mjs';

test('expects exactly six bridge tools without claiming a task', () => {
  const result = summarizeCatalog(REQUIRED_TOOLS.map(name => ({ name })));
  assert.equal(result.expected, 6);
  assert.equal(result.found, 6);
  assert.deepEqual(result.missing, []);
  assert.equal(result.remoteConnectorVerified, false);
  assert.equal(result.turnBoundExecutionVerified, false);
});
test('detects partial catalog', () => {
  const result = summarizeCatalog([{ name: 'codex_tool_inventory' }]);
  assert.equal(result.found, 1);
  assert.equal(result.missing.length, 5);
});
test('rejects malformed catalog or runtime', () => {
  assert.throws(() => summarizeCatalog([{ other: 'x' }]), /MCP_CATALOG_INVALID/);
  assert.throws(() => verifyRuntimeConfig({ mode: 'browser-only' }), /FULL_HARNESS_NOT_ENABLED/);
  assert.throws(() => verifyRuntimeConfig({ mode: 'full', runtimeCommand: ['powershell', 'evil.ps1'] }), /UNRECOGNIZED_RUNTIME_COMMAND/);
});
test('speaks MCP initialize and tools/list over isolated stdio', async () => {
  const fixture = join(dirname(fileURLToPath(import.meta.url)), 'fixtures', 'mock-mcp.cjs');
  const result = await probeStdio({ exe: process.execPath, entrypoint: fixture, brokerSocketPath: 'mock-no-real-broker', timeoutMs: 3000 });
  assert.equal(result.found, 6);
  assert.equal(result.remoteConnectorVerified, false);
  assert.equal(result.turnBoundExecutionVerified, false);
});
