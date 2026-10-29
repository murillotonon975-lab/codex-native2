---
name: codex-native2-health

description: Diagnostique falhas de tunnel, proxy 17841, Codex Web GPT e registro do Codex Native2 interpretando testes PowerShell fornecidos pelo usuario; nao executar mudancas sem autorizacao.
---

# Diagnóstico de comunicação Codex Web GPT

Ative quando o usuário relatar "stream disconnected", conector ausente, timeout, falha MCP ou quiser conferir o proxy local.

1. Peça a execução **pelo usuário** do script `scripts/Check-CodexNative2.ps1` incluído neste skill, quando o ambiente de execução local não estiver disponível.
2. Interprete os indicadores individualmente: modo do launcher (`full`/`browser-only`), processo do proxy Bun, conexão local 17841, processo `tunnel-client`, conexão TCP 443 e status do registro no ChatGPT.
3. `Established` na porta 443 comprova apenas o estado TCP, não autenticação ou interoperabilidade MCP; porta local 17841 escutando também não comprova chamadas MCP.
4. Conector criado no ChatGPT, ferramentas listadas e teste de chamada com êxito são etapas distintas. Não infira sucesso de etapas anteriores.
5. Evite encerrar processos, remover arquivos ou reconfigurar o modo de transporte como primeira resposta; priorize orientação e backup.
6. Se o usuário preferir modo `browser-only`, explique que não se obtém ferramentas locais MCP por esse caminho.
7. Nunca trate nome do plugin como ID registrado de servidor; não invente `plugin_asdk_app...`.

Informe resultados confirmados, não confirmados e uma próxima ação isolada com menor risco.
