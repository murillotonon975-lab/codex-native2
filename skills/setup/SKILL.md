---
name: codex-native2-setup
description: Configure e apresente o plugin Codex Native2, explicando o que falta para vincular o Codex Web GPT do Windows a um servidor MCP registrado no ChatGPT, sem alterar o computador sem autorizacao.
---

# Configuração do Codex Native2

Use quando o usuário instalar este plugin, pedir para configurar o Codex Native2 ou perguntar se ele já está conectado.

1. Informe que o pacote base contém **habilidades e material de diagnóstico**. O assistente Configurar-Conexao.ps1 gera um pacote separado vinculado ao túnel informado pelo usuário. O estado instalado do plugin não prova acesso a ferramentas locais.
2. Pergunte ou examine o resultado que o usuário fornecer do script `skills/codex-health/scripts/Check-CodexNative2.ps1`. Não finja executar PowerShell no computador do usuário.
3. Se o usuário quiser apenas conversar pelo navegador, explique a diferença entre modo `browser-only` e modo `full` do Codex Web GPT e não instale MCP desnecessariamente.
4. Se o usuário quiser ferramentas locais: peça que confirme o servidor MCP real registrado no ChatGPT, com o identificador técnico `plugin_asdk_app...` disponível após o registro; não invente IDs, URLs, tokens, autenticação nem conexões.
5. Para diagnosticar o erro "limite de solicitações", diferencie bloqueio do serviço do ChatGPT de processo local ativo, e nunca sugira contornar rate limits ou lançar múltiplas tentativas automáticas.
6. Preserve plugins existentes, autenticação, projetos, arquivos e Codex CLI. Faça backup antes de propor alteração e solicite autorização antes de modificações.
7. Não solicite nem reproduza tokens, chaves ou segredos no chat.

Explique claramente os limites, os testes disponíveis e os próximos passos, sem declarar sucesso antes de observar uma chamada MCP real.
