# Codex Native2 — Catálogo unificado de ferramentas

**Situação:** fase de desenvolvimento da [PR #1](https://github.com/murillotonon975-lab/codex-native2/pull/1). Mantém um único produto e código para todos. **Não declarar compartilhamento bidirecional pronto antes de um teste de ponta a ponta.**

## Objetivo

O Codex Native2 deve oferecer uma visão unificada, mas tecnicamente fiel, de:

| Origem | Descoberta | É executável automaticamente? |
|---|---|---|
| Servidores MCP instalados no **Codex CLI** | `codex mcp list --json` | **Não**. Cadastro não prova ferramentas carregadas ou autorização |
| Ferramentas de execução do **runtime MCP local** | Protocolo `initialize` e `tools/list` | **Não** sem `turn_token` autorizado e tarefa ativa |
| Ferramentas dos MCPs/apps da **tarefa Codex** | `codex_tool_inventory` com `turn_token` da tarefa atual | **Somente se anunciadas e permitidas**; `codex_tool_call` encaminha ao runtime |
| Plugins **internos e conectados no ChatGPT** | Catálogo autorizado disponibilizado pelo **host ChatGPT na sessão atual** | **Somente no ChatGPT**, por chamada com permissão específica. Não são automaticamente compartilhados com Codex/PC |
| Aplicativos locais comuns (Git, editor, automação, etc.) | Detectores/adaptadores locais adicionais | Somente com adaptador real e permissão, não basta estar instalado |

### Limites reais

- O **servidor local MCP do Codex Web GPT 6.1.17** anuncia seis ferramentas de entrada: `codex_exec`, `codex_write_stdin`, `codex_apply_patch`, `codex_view_image`, `codex_tool_inventory`, `codex_tool_call`.
- O `codex_tool_inventory` obtém ferramentas **da tarefa ativa**, incluindo MCPs e apps que o Codex realmente expõe. Sem tarefa/turn_token, essa expansão não existe.
- A sessão ChatGPT disponibiliza outro conjunto de ferramentas. O plugin não consegue descobrir, baixar, copiar ou injetar silenciosamente essas ferramentas no Codex CLI a partir de um manifesto.
- **Integração bidirecional** requer uma ponte de execução implementada pelo host com autenticação por identidade, consentimento e auditoria. Não estabelecer um proxy aberto que encaminhe qualquer ação.
- Uma mesma ferramenta pode existir em ambas as origens; manter namespace/origem, escopos de autorização e semântica de erro distintos para evitar confusão.

## Comandos de diagnóstico na versão em desenvolvimento

Execute em uma pasta da branch `feature/unified-settings-mcp-20261104`, no Windows:

```powershell
# Primeiro: configurações locais e status geral
.\Diagnosticar.cmd

# Segundo: listar MCPs cadastrados no CLI e seis ferramentas do runtime local
.\Inventariar-Integracoes.cmd

# Terceiro: teste estrito de tools/list (sem executar nenhuma ferramenta)
.\Verificar-Catalogo-MCP.cmd
```

Também estão disponíveis `node scripts/Inventariar-Integracoes.mjs --json` e `node scripts/Verificar-Catalogo-MCP.mjs --json`. O inventário exibe apenas nomes de servidores, flags habilitado/desabilitado e nomes de ferramentas. **Não imprime tokens, API keys, comandos dos servidores, variáveis de ambiente ou URLs privadas.**

No painel gráfico `scripts/Configurar-Native2-GUI.ps1`, há o botão **Integrações** para consultar o inventário local.

### Teste funcional em ChatGPT

1. Concluir `MCP → Verify runtime` no Codex Web GPT.
2. Criar uma tarefa nova e autorizada usando modelo `(Web)`.
3. Na conversa gerada por ela, verificar se `codex_tool_inventory` foi de fato **anunciado** pelo host.
4. Utilizar exclusivamente o `turn_token` daquela tarefa (não inventar, guardar ou compartilhar).
5. Chamar `codex_tool_inventory` e, se permitido, fazer uma chamada inofensiva de leitura.
6. Para um plugin interno ChatGPT, verificar **na própria conversa** se o conector específico está disponível e autorizado. Sua ausência não significa que ele foi desinstalado.
7. Reportar claramente qual origem executou a ação; nenhum diagnóstico local é substituto dessa verificação.

## Estados exibidos

- `registrado`: existe na configuração do Codex/ChatGPT.
- `conectado`: transportes e autenticação passaram verificação apropriada.
- `anunciado`: host retornou nome/schema para aquela sessão/tarefa.
- `executado`: uma chamada real retornou, respeitando permissões.
- `inacessível`: não anunciado, sem autorização, incompatível ou indisponível.
- `não verificável localmente`: instrumentos locais não podem provar disponibilidade do ChatGPT.

## Segurança, distribuição e próximo trabalho

- **Nunca** distribuir túnel pessoal, cookies, senha, chave de API, token de tarefa ou catálogo privado de conectores no ZIP do GitHub.
- Pedir aprovação para comandos que alterem o computador; não habilitar `Allow all actions` por padrão para todos.
- Não clonar credenciais nem assumir permissão cruzada entre ChatGPT e Codex.
- Não mudar a infraestrutura do `codex-chatgpt-web` automaticamente para “liberar ferramentas”.
- Próxima etapa antes de divulgar como concluído: implementar servidor/integração real de configurações, suporte de host para descoberta no ChatGPT e testes de chamadas nas duas direções.

**O que esta PR já faz:** inventário de MCPs registrados localmente, consulta das seis ferramentas nativas, menu e interface inicial. **O que ainda não faz:** habilitar um conector ChatGPT na tarefa por conta própria, executar plugins ChatGPT no computador ou oferecer compartilhamento universal bidirecional.
