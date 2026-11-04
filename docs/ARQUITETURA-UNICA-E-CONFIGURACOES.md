# Codex Native2 — uma única edição, configurações por usuário

**Estado:** implementação incremental; NÃO declarar que a página de configurações no ChatGPT está ativa até que o runtime MCP a anuncie e os testes de ponta a ponta sejam aprovados.

## Decisão de produto

- **Um único repositório:** `murillotonon975-lab/codex-native2`.
- **Um único nome e versionamento:** `Codex Native2`, sem edições “personal”, “public” ou “lite”.
- A instalação do desenvolvedor e a de usuários externos executam **o mesmo pacote e código**.
- O ambiente privado do desenvolvedor serve para homologar **a mesma versão** antes da publicação. Não há bifurcação funcional.
- **Cada pessoa tem seus próprios dados de conexão**, nunca incorporados à distribuição pública: túnel, contas, estado de login, permissões e credenciais.
- O `Codex Native` legado e ambientes produtivos existentes não são alterados automaticamente.

## Arquitetura necessária para a experiência solicitada

```
Codex Native2 (versão única no GitHub)
  ├─ instalador/atualizador (Windows; outros sistemas futuramente)
  ├─ primeiro acesso: assistente de configuração
  ├─ painel local seguro: estado, perfil e diagnóstico
  └─ servidor MCP real (com integração ao Codex Web GPT)
       ├─ ferramentas de tarefa nativa: inventário, exec, patch etc.
       ├─ openai/settings: settings.read e settings.update
       ├─ gerenciamento seguro de perfis do usuário
       └─ testes de conexão, logs redigidos e rollback
          ↕
  ChatGPT → Plugins → Codex Native2 → Configurações
```

**Limite atual:** o repositório público v0.4.0 contém instalador de um painel local e gerador de pacote; não hospeda o servidor MCP da integração. O plugin privado 0.5.x empacota skills e configura uma conexão MCP a um túnel específico. Instruções de skills/manifests NÃO criam sozinhas a tela nativa de configurações. Para uma tela no ChatGPT, o servidor MCP precisa anunciar `openai/settings` e implementar `settings.read` / `settings.update`, conforme https://github.com/openai/mcp-extensions/blob/main/docs/spec.md#structured-settings.

**Ponto de integração:** o servidor MCP utilizado hoje pertence ao runtime do `codex-chatgpt-web`, que é um projeto de terceiros. Implementar capacidades de settings nele exige uma integração compatível com esse servidor, uma contribuição upstream ou um backend próprio que realmente encaminhe as ferramentas e autentique cada usuário. Não gravar um túnel global único no pacote universal. Não fazer proxy “genérico” dos túneis sem revisão de identidade, autenticação e autorização.

## Configurações desejadas

### Primeiro acesso

1. Detectar sistema, Codex CLI, versão do launcher e estado dos processos (somente leitura).
2. Informar o modo de acesso e explicar o requisito de conta/túnel independente.
3. Detectar identificador do túnel local (não segredo) e permitir inserção/edição manual.
4. Verificar a associação com o conector ChatGPT; nunca assumir que `codex mcp list` prova acesso no ChatGPT.
5. Testar catálogo da tarefa e execução inofensiva usando token autorizado da tarefa, quando disponível.
6. Registrar claramente “configurado”, “conectado”, “ferramentas anunciadas” e “chamada real concluída”.

### Painel de configuração

- Estado do runtime, túnel, autenticação, ligação ao conector, versão do app, versão do plugin e última verificação.
- Alterar o túnel pessoal: validar ID e propriedade da conexão; confirmação explícita; preservar opção anterior; testar e oferecer rollback.
- Trocar contas/chaves **somente via fluxo seguro do launcher/host**; não solicitar segredo em conversas, exportações, URLs ou GitHub.
- MCPs: visualizar, listar ferramentas, habilitar/desabilitar e adicionar/remover por APIs reais e autorizadas.
- Permissões por recurso; não habilitar tudo por padrão para terceiros.
- Reconnect idempotente com timeout, erro detalhado sem credenciais e sem loop agressivo após 401.
- Atualização assinada/verificada, staged release, notas, confirmação e rollback.

### Requisitos de implementação na interface do ChatGPT

1. O servidor MCP deve anunciar `capabilities.extensions["openai/settings"]` com `readTool` e `updateTool`.
2. `settings.read` aceita `{}`, não altera dados, retorna schema, values e layout atuais.
3. `settings.update` autentica a identidade, valida formato de cada campo e grava apenas o escopo daquele usuário.
4. Um campo `tunnelId` da tela NÃO pode, por si só, substituir o túnel de transporte já associado ao plugin. O host precisa oferecer migração suportada ou manter um endpoint estável e mapear usuários com autenticação própria. Até existir essa integração, mostrar “alteração pendente de aplicar no conector” em vez de fingir sucesso.
5. API keys permanecem em armazenamento protegido do dispositivo/serviço, nunca no manifesto, no GitHub nem na resposta das tools.
6. Testar no ChatGPT real: tela abre, alteração persiste, fica visível após reiniciar, e MCP continua apto a executar uma chamada autorizada.

## Escopo de implementação e entrega

- **Fase A — já possível neste repositório:** diagnóstico, instalador preservando versões, painel local de configuração não secreta, importação/exportação, teste somente leitura e cobertura CI.
- **Fase B — exige backend/runtime:** settings nativos no ChatGPT, troca do túnel associada ao conector, reconnect funcional, autenticação, auditoria, rollback.
- **Fase C — distribuição:** manifest universal sem identificador de usuário, instalador/auto-update GitHub Releases com checksum, testes Windows, documentação e pacote de submissão.
- Não declarar o lançamento público pronto enquanto as fases B e C não estiverem validadas.

## Segurança e compatibilidade

- Sem chaves, IDs de conta pessoais, tokens, cookies ou credenciais nos artefatos públicos.
- Arquivo de configurações local separado do diretório do código, com dados não secretos. Não tratar `tunnelId` como prova de autorização.
- Nunca sobrescrever diretórios Codex, configuração do launcher ou projetos sem backup e consentimento.
- Reinstalar o launcher não deve ser condição para salvar um perfil local.
- Não alterar `AGENTS.md`, resetar repositórios, subir alterações de projetos ou instalar permissões amplas automaticamente.

## Critérios de aceite (requeridos antes do lançamento)

- [ ] Uma mesma versão instala e funciona para dois usuários com IDs de túnel distintos.
- [ ] Interface inicial detecta configuração ausente, explica o estado e permite editar o ID.
- [ ] Tela do ChatGPT tem controles reais em Configurações (não apenas documentação).
- [ ] Alteração de túnel realmente muda o destino autorizado do conector ou oferece o passo oficial quando impossível.
- [ ] Erros 401, composer ausente, conflito de turn ID e falta do catálogo aparecem como diagnósticos distintos.
- [ ] Um teste real de `codex_tool_inventory` e uma chamada de leitura terminam com confirmação.
- [ ] Atualização mantém perfis e reverte em falha.
- [ ] ZIP público não contém túnel, chaves ou arquivos pessoais.
- [ ] Pipeline CI/testes de instalação e segurança são aprovados.
- [ ] Documentação não descreve “configurado” como “conectado” sem evidência.

## Compartilhamento de ferramentas em dois ambientes

O mesmo plugin deve oferecer uma interface de descoberta para **MCPs e ferramentas locais** e **plugins internos/conectados do ChatGPT**. Cada item inclui sua origem, disponibilidade **na tarefa atual**, escopo de acesso e última chamada real. Não duplicar ou importar credenciais de uma origem para a outra.

- **Codex CLI/Windows**: `codex mcp list --json` descobre servidores configurados; `tools/list` do runtime confirma seis ferramentas de entrada. O inventário de ferramentas do Codex usa `codex_tool_inventory` com `turn_token` da tarefa corrente. Comandos locais não são executados durante o inventário.
- **ChatGPT**: o host disponibiliza plugins e ferramentas numa sessão autorizada. Esses recursos podem ser utilizados pelo assistente **quando realmente presentes**; não são automaticamente exportáveis ao Windows, nem o plugin pode prometer acesso a funcionalidades internas que o host não anunciou.
- **Apps comuns instalados**: exigem adaptadores, APIs ou ferramentas MCP próprias, mesmo se disponíveis no sistema operacional.
- **Roteamento**: preferir a ferramenta correspondente à ação desejada, respeitar autorização para cada chamada; opcionalmente usar Remote Desktop Commander como contingência se Native2 não estiver disponível, e vice-versa, sem duplicar efeitos colaterais.

Implementação inicial nesta PR: inventário local com identificação de origem, menu Windows, janela de configuração e skill de uso de ferramentas do host. **Fase seguinte (ainda não implementada)**: descoberta efetiva dos plugins do ChatGPT diretamente pelo host, sincronização controlada da visualização, comandos de ligação MCP e prova de execução nos dois ambientes. Ver [catálogo de ferramentas](CATALOGO-FERRAMENTAS.md).
