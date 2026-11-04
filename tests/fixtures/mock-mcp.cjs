// Isolated fake MCP stdio server used by CI. Never opens the local broker or ChatGPT.
const { createInterface } = require('node:readline');
const names = ['codex_exec', 'codex_write_stdin', 'codex_apply_patch',
  'codex_view_image', 'codex_tool_inventory', 'codex_tool_call'];
const rl = createInterface({ input: process.stdin, crlfDelay: Infinity });
rl.on('line', text => {
  let request;
  try { request = JSON.parse(text); } catch { return; }
  if (request.method === 'initialize') {
    console.log(JSON.stringify({
      jsonrpc: '2.0', id: request.id,
      result: { protocolVersion: '2025-03-26', capabilities: { tools: {} },
        serverInfo: { name: 'mock-native2-mcp', version: '0.0.1' } },
    }));
  } else if (request.method === 'tools/list') {
    console.log(JSON.stringify({
      jsonrpc: '2.0', id: request.id,
      result: { tools: names.map(name => ({ name, description: 'Mock only', inputSchema: { type: 'object', properties: {} } })) },
    }));
  }
});
