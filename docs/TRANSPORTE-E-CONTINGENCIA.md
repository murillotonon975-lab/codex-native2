# Transporte local, Secure MCP Tunnel e contingencia no ChatGPT

## Modos disponiveis

| Modo | O que acontece | Requisitos | Disponibilidade ao ChatGPT |
| --- | --- | --- | --- |
| Auto | Reutiliza tunel existente se configurado e o cliente estiver ativo; caso contrario seleciona MCP local stdio se houver runtime | Launcher existente | So ha descoberta remota quando o host autoriza |
| Local | Configura preferencia de runtime MCP stdio da tarefa no computador, sem servidor publico | Codex Web GPT em modo full, runtime e broker socket | **Nao** cria automaticamente ferramenta no ChatGPT |
| Existing | Reutiliza a identidade de tunel ja presente no launcher e preserva o cliente ativo | Tunel configurado no launcher | Depende da vinculacao autenticada a conta/workspace |
| Online | Inicializa perfil no tunnel-client oficial, verifica por `doctor` e executa quando solicitado | tunnel_id fornecido pela Platform, permissao Tunnels Read + Manage/Use, chave de runtime no ambiente local | Depende de app/conector e plano/workspace |

O Secure MCP Tunnel e um servico gerenciado: o cliente Windows conecta por HTTPS a um **endpoint de tunel da Platform**. Um localhost MCP nao equivale a um tunel remoto. Nao e possivel criar esse endpoint sem permissao da conta/organizacao; a interface oficial gera o `tunnel_id`.

## Uso e testes

O script `scripts/Selecionar-Transporte.ps1` e incluido no ZIP da PR. Em Windows PowerShell:

```powershell
# Descoberta sem efeitos colaterais:
.\scripts\Selecionar-Transporte.ps1 -Mode Auto -Action Inspect -Json

# Reutiliza identidade configurada, sem reiniciar o tunnel-client:
.\scripts\Selecionar-Transporte.ps1 -Mode Existing -Action Configure

# Registra preferencia local para uso stdio no PC, sem acesso remoto:
.\scripts\Selecionar-Transporte.ps1 -Mode Local -Action Configure

# Usa tunnel-client oficial ja instalado, ID existente da configuracao ou fornecido:
# A chave runtime deve ser inserida de forma segura no ambiente local antes da chamada.
.\scripts\Selecionar-Transporte.ps1 -Mode Online -Action Configure
.\scripts\Selecionar-Transporte.ps1 -Mode Online -Action Doctor
# Executa o tunel em primeiro plano apenas quando explicitamente solicitado:
.\scripts\Selecionar-Transporte.ps1 -Mode Online -Action Run
```

`Configure` grava somente nome do perfil e modo, sem chaves, em `%LOCALAPPDATA%\CodexNative2\transporte.json`; preserva copia `.bak` se substituir preferencia existente. `Inspect` nao faz modificacoes. Se faltar runtime, ID, cliente ou credencial, registra falha e preserva instalacoes anteriores.

Para o modo Online, a documentacao oficial do `tunnel-client` mostra `init --sample sample_mcp_stdio_local --profile ... --tunnel-id ... --mcp-command ...`, depois `doctor --profile ... --explain` e `run --profile ...`. Este assistente nao cria a identidade na Platform. Credenciais devem ficar no ambiente local (`CONTROL_PLANE_API_KEY`) e nunca no GitHub ou nas mensagens do ChatGPT.

## Contingencia pelo Remote Desktop Commander

A habilidade de integracoes detecta o catalogo Native2 **da tarefa**. Quando indisponivel, e possivel usar o conector independente Remote Desktop Commander (se anunciado e autorizado) para completar o mesmo objetivo operacional:

| Objetivo da tarefa | Executor de contingencia |
| --- | --- |
| Consulta de arquivos | `read_file`, `read_multiple_files` |
| Busca de fontes locais | `start_search` |
| Comando terminal | `start_process` |
| Continuar terminal | `read_process_output`, `interact_with_process` |
| Alteracao de arquivo textual | `edit_block` ou `write_file` |
| Ler imagem autorizada | `read_file` |
| Catalogar 6/6 ferramentas do runtime local | `start_process` executando `Verificar-Catalogo-MCP.mjs --json` no computador autorizado |

Isso **nao transforma** `codex_exec` em ferramenta anunciada, nao transmite `turn_token`, nem falsifica ferramentas nativas. Cada acao usa o proprio esquema e as autorizacoes do Commander. Para comandos com `call_id` pendente, consultar `get_tool_result` antes de reenviar qualquer alteracao.

## Erros de workspace_roots

Os metadados `session_meta.runtime_workspace_roots` e `turn_context.cwd` devem pertencer a mesma sessao/tarefa. Um diretorio de outra tarefa pode provocar `Codex rollout cwd is outside its workspace roots`, ainda que o runtime e o tunel estejam ativos.

- Verifique a raiz do workspace escolhida na tarefa ativa do Codex Web GPT e o diretorio de trabalho enviado no turno. Corrija a associacao na propria tarefa, usando uma raiz autorizada.
- Nao acrescente automaticamente `C:\\`, `D:\\` nem todas as pastas do usuario a `workspace_roots`; isso ampliaria indevidamente o acesso.
- O relatorio sanitizado conta `outside` apenas quando existem diretorio e raizes Windows absolutos. Quando faltam esses metadados, registra `unknown` e nao afirma que houve erro de raiz.
- A correcao da selecao de tarefa e de `workspace_roots` no broker/host exige alterar e validar o runtime Codex Web GPT. O assistente desta PR nao substitui esse componente; requer teste nativo com uma tarefa autorizada.

## Diagnostico do executavel do tunel

O seletor primeiro procura `tunnel-client.exe` no PATH; se nao encontrar, consulta apenas o caminho do processo `tunnel-client` ja em execucao. O caminho completo nao aparece no relatorio. O campo `tunnelClientExecutableSource` informa `PATH`, `running_process` ou `not_detected`. Esse resultado **nao** prova autenticacao do tunel nem autoriza criar outro processo. Se houver multiplos executaveis diferentes de processos ativos, o seletor nao escolhe um arbitrariamente.

## Criterios de homologacao

1. Detectar status e nao expor secrets/IDs em JSON.
2. Configuracao local repetida e sem sobrescrever launcher, socket ou tunel existentes.
3. Online: sucesso real de `tunnel-client doctor`, `/readyz` e verificacao do conector no host.
4. ChatGPT: prova separada de descoberta das 6 ferramentas e `codex_tool_inventory` com contexto de tarefa valido.
5. Executar leitura real com `codex_exec` **ou**, se a sessao nao o disponibilizar, uma leitura explicitamente identificada como feita pelo Remote Desktop Commander.
6. Preservar instalacao anterior, credenciais e dados; nenhum deploy/merge/publicacao automatica.

## Limitacoes da plataforma

O ChatGPT nao e obrigado a expor ferramentas de um MCP por apenas existir um plugin com skills. As politicas do plano e workspace se aplicam a conexoes MCP, inclusive por tunel. A contingencia via Remote Desktop Commander so funciona quando essa **outra** integracao esta disponivel e autorizada.

Fontes oficiais: https://developers.openai.com/api/docs/guides/secure-mcp-tunnels e https://help.openai.com/en/articles/12584461-connecting-custom-mcp-servers-in-chatgpt
