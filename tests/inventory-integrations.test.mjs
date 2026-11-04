import { test } from 'node:test';
import assert from 'node:assert/strict';
import { summarizeCliMcp, summarizeSessionTools, snapshot } from '../scripts/Inventariar-Integracoes.mjs';

test('lists authorized Codex server names but does not echo env, command, URLs or credentials', () => {
  const rows = [{
    name: 'remote-desktop-commander', enabled: true,
    auth_status: 'oauth', command: 'secret-command', args: ['--token=private'],
    transport: { type: 'stdio', env: { TOKEN: 'secret' }, url: 'https://secret.invalid/token' },
  }, { name: 'node_repl', enabled: false, auth_status: 'unknown' }];
  const output = summarizeCliMcp(rows);
  assert.deepEqual(output.map(x => x.name), ['node_repl', 'remote-desktop-commander']);
  const dump = JSON.stringify(output);
  for (const secret of ['secret', 'private', 'secret.invalid', 'TOKEN']) {
    assert.equal(dump.includes(secret), false);
  }
});

test('host catalog is absent unless session explicitly supplies it', () => {
  const result = snapshot({ cli: [], native: { status: 'announced', toolNames: ['codex_tool_inventory'] } });
  assert.equal(result.chatgpt.status, 'requires_authorized_chatgpt_session');
  assert.deepEqual(result.chatgpt.tools, []);
  assert.equal(result.endToEndVerified, false);
});

test('host tool names from a trusted session are included without capabilities or arguments', () => {
  const res = snapshot({ cli: [], native: null, host: [
    { name: 'mcp__Drive__search', callable: true, authToken: 'private-token', inputSchema: { secret: 'secret-schema' } },
  ] });
  assert.deepEqual(res.chatgpt.tools, [
    { source: 'chatgpt-session', name: 'mcp__Drive__search', callableInThisSession: true },
  ]);
  assert.equal(JSON.stringify(res).includes('private-token'), false);
  assert.equal(JSON.stringify(res).includes('secret-schema'), false);
});

test('rejects malformed data, rather than treating it as tool instructions', () => {
  assert.throws(() => summarizeCliMcp([{ name: 'tool; rm -rf /', enabled: true }]), /MCP_SERVER_NAME_INVALID/);
  assert.throws(() => summarizeSessionTools([{ name: '../path', callable: true }]), /HOST_TOOL_NAME_INVALID/);
});
