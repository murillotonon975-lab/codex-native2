---
name: codex-native2-setup
description: Configure e apresente o plugin Codex Native2, explicando o que falta para vincular o Codex Web GPT do Windows a um servidor MCP registrado no ChatGPT, sem alterar o computador sem autorizacao.
---

# Configuração do Codex Native2

Use quando o usuário instalar este plugin, pedir para configurar o Codex Native2 ou perguntar se ele já está conectado.

1. Informe que o pacote base contém **habilidades e material de diagnóstico**. Para usar ferramentas locais, priorize o fluxo oficial: ChatGPT web > Plugins > + > Adicionar servidor MCP personalizado > Conexão: Túnel, selecionar o túnel existente e revisar as ferramentas detectadas. O ZIP de Configurar-Conexao.ps1 é legado e não ativa automaticamente ferramentas no host.
2. Quando disponível, execute `scripts/Vincular-ChatGPT.ps1 -Json` no Windows autorizado e compare health do launcher, estado do tunnel-client, manifesto do plugin e catálogo MCP local. Nunca apresente esses sinais locais como prova de execução pelo ChatGPT. Se o acesso não existir, analise somente evidências fornecidas.
3. Se o usuário quiser apenas conversar pelo navegador, explique a diferença entre modo `browser-only` e modo `full` do Codex Web GPT e não instale MCP desnecessariamente.
4. Se o usuário quiser ferramentas locais, confira que ele adicionou o servidor MCP personalizado pelo túnel na conta/workspace correta, revisou as seis ferramentas e habilitou o conector na conversa. Só marque a integração como aprovada depois de `codex_tool_inventory` e uma chamada real somente leitura usando `codex_exec`. Não invente IDs, URLs, tokens ou conexões.
5. Para diagnosticar o erro "limite de solicitações", diferencie bloqueio do serviço do ChatGPT de processo local ativo, e nunca sugira contornar rate limits ou lançar múltiplas tentativas automáticas.
6. Preserve plugins existentes, autenticação, projetos, arquivos e Codex CLI. Faça backup antes de propor alteração e solicite autorização antes de modificações.
7. Não solicite nem reproduza tokens, chaves ou segredos no chat.

Explique claramente os limites, os testes disponíveis e os próximos passos, sem declarar sucesso antes de observar uma chamada MCP real.
