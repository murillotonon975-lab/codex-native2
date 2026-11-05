---
name: codex-native2-integrations
description: "Descobrir MCPs e apps do computador, ferramentas da tarefa Codex e plugins disponibilizados ao ChatGPT; encaminhar chamadas apenas com autorização e disponibilidade reais."
---

# Codex Native2 — catálogo integrado de ferramentas

O usuário quer **um único Codex Native2** com visão das ferramentas do PC e dos plugins disponíveis no ChatGPT. A fonte de cada ferramenta é separada; não prometa acesso irrestrito entre as fontes.

## Fontes e prova de disponibilidade

1. **MCPs do computador / Codex CLI:** `codex mcp list --json` enumera servidores registrados. Não liste argumentos, variáveis de ambiente, URLs com credenciais, chaves ou linhas de comando. O novo inventário local está em `scripts/Inventariar-Integracoes.mjs`, e a consulta ao servidor MCP local em `scripts/Verificar-Catalogo-MCP.mjs`.
2. **Ferramentas da tarefa Codex:** descubra `codex_tool_inventory` na sessão **atual** do ChatGPT, usando somente o `turn_token` da tarefa recebida pelo host. Quando disponível, ele fornece inventário de ferramentas da tarefa nativa, incluindo as de MCPs e apps autorizados; use `codex_tool_call` com o wire name e parâmetros realmente anunciados. Não reutilize token entre tarefas.
3. **Plugins internos/externos do ChatGPT:** utilize exclusivamente as ferramentas e conectores **que o host disponibilizar na conversa ou tarefa atual**, obedecendo autenticação, schema, escopo e permissões de cada um. Um plugin do ChatGPT não é automaticamente um servidor MCP disponível ao Windows. Não copie cookies, OAuth tokens, chaves, nem simule autorização que não foi concedida.
4. **Aplicativos comuns do computador:** um executável instalado não se torna uma ferramenta MCP sem adaptador autorizado, API ou fluxo real de acesso. Mostre **compatível com integração** separadamente de **ferramenta MCP acessível**.

## Fluxo de seleção

- Se o usuário pedir a ação em uma plataforma específica, prefira ferramenta autorizada daquela plataforma.
- Para descoberta, informe por origem se está: **registrado**, **conectado**, **anunciado à sessão**, **testado com chamada real** ou **indisponível**.
- Mantenha um único catálogo visual, mas nunca misture disponibilidade local com disponibilidade no ChatGPT; enumeração local não significa que o host criou aquela ferramenta.
- Antes de executar ações mutáveis, use verificação de leitura, confira ambiente, aprovação e escopo. Não faça `deploy`, `merge`, mudanças em produção, alterações de permissões ou operações destrutivas sem autorização.
- Em ausencia das ferramentas Codex Native2 na sessao, use **Remote Desktop Commander** apenas quando a integracao estiver anunciada pelo host, a conta a autorizar e o computador-alvo estiver online. Consulte `list_devices` e selecione o dispositivo correto antes de operar. Informe o fallback pelo nome: `remote_desktop_commander`.
- A contingencia e **roteamento semantico**, nao um proxy MCP transparente nem um desbloqueio de permissao do plano/workspace. Descubra os nomes e esquemas reais antes de chamar:
  - Leitura e busca: `read_file`, `read_multiple_files`, `start_search`.
  - Diagnostico: `list_devices`, `list_processes`, `get_file_info`.
  - Equivalente operacional de `codex_exec`: `start_process`, com diretorio e comando autorizados; continuidade via `read_process_output` e `interact_with_process`.
  - Edicao textual sob autorizacao: `edit_block` ou `write_file`.
  - Imagem local: `read_file` quando suportado no dispositivo autorizado.
  - Catalogo de seis entradas Native2: executar o script local `Verificar-Catalogo-MCP.mjs` pelo Commander, caso permitido; isso **nao** valida `codex_tool_inventory` de tarefa ativa.
- Nunca envie `turn_token`, segredos, cookies, chaves de API, credenciais ou objetos internos de sessao por outro plugin. Preserve UAC, sandbox e escopo. Se a chamada remota retornar `call_id` em andamento, use `get_tool_result` e nao repita operacoes com efeitos colaterais.
- Relate exatamente qual ferramenta executou o trabalho; uma operacao bem-sucedida pelo Commander nao altera o estado `0/6` do catalogo Native2.

- Não exponha ferramentas do ChatGPT para o computador criando um servidor público aberto, capturando sessão ou fazendo proxy de credenciais. Uma ponte **bidirecional** requer implementação específica do host, consentimento e identidade separada por usuário/tarefa.

## Vinculação do ChatGPT

Quando o catálogo MCP local anunciar 6/6 ferramentas mas o host não disponibilizar `codex_tool_inventory`, siga o fluxo oficial de ChatGPT web > Plugins > + > Adicionar servidor MCP personalizado > Conexão: Túnel. Selecione o túnel autorizado, revise as seis ferramentas e habilite a conexão na conversa. Antes disso, execute `Vincular-ChatGPT.cmd` no Windows autorizado: o assistente informa somente o estado local e não cria uma conexão remota. Verifique associação ao workspace e permissões Tunnels Read + Use se o túnel não aparecer. Não passe credenciais, não crie novo túnel automaticamente nem altere o plugin existente.

A aprovação depende da chamada real de `codex_tool_inventory` e de uma operação inofensiva com `codex_exec` na sessão. Consulte https://help.openai.com/pt-br/articles/12584461-connecting-custom-mcp-servers-in-chatgpt .

## Verificação

1. Consultar servidores MCP locais sem imprimir configuração sensível.
2. Consultar `tools/list` no runtime MCP local. Isso confirma apenas seis entradas/compatibilidade do servidor.
3. Em uma tarefa Codex ativa, confirmar que o ChatGPT realmente recebeu `codex_tool_inventory`.
4. Chamar inventário com token fornecido pelo host. Paginar até completar o conjunto necessário, preservando tipos/schema.
5. Executar uma **chamada inofensiva de leitura**, se autorizada, e registrar resultado/erro. Não usar `tools/call` em diagnóstico local sem tarefa.
6. Para plugins internos do ChatGPT, confirmar diretamente na conversa atual se a ferramenta específica está exposta e pode ser invocada; se não, marcar **não disponibilizada nesta sessão**.

Nenhum arquivo do repositório universal deve conter IDs de túneis pessoais, segredos ou listas privadas de conectores.
