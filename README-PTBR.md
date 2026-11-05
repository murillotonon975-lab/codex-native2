# Codex Native2

Assistente comunitário para configurar e diagnosticar a integração entre Codex Web GPT e ChatGPT no Windows. **0.4.1 BETA.** Não é um produto oficial da OpenAI e não distribui o launcher, o Codex CLI nem um servidor MCP próprio.

[Baixar código e instalador (ZIP)](https://github.com/murillotonon975-lab/codex-native2/archive/refs/heads/main.zip) · [Ver arquivos](https://github.com/murillotonon975-lab/codex-native2)

O ZIP contém o projeto completo. Extraia antes de executar os arquivos CMD. Não envie o ZIP de código-fonte como atualização de um plugin instalado; o assistente gera um pacote pessoal separado.

## Instalar em poucos passos

1. Baixe o código em **Code → Download ZIP** e extraia em uma pasta.
2. Execute `Instalar-Native2.cmd`. Não precisa abrir como administrador. O PowerShell usa uma exceção de execução somente neste processo.
3. Aceite a unidade fixa com mais espaço ou informe outra pasta. O instalador verifica espaço, escrita e integridade das cópias.
4. Abra `Iniciar.cmd` na pasta indicada ao final. Também é possível usar o menu diretamente na pasta extraída, sem instalar.

O menu oferece painel de perfis, configuração do túnel, diagnóstico e este guia. Windows PowerShell 5.1 ou posterior; sem Node, Python ou dependências adicionais para usar.

## Escolher modo de conexao automaticamente ou manualmente

O instalador consulta a configuracao existente e salva uma preferencia em `%LOCALAPPDATA%\CodexNative2\transporte.json`, sem sobrescrever o launcher nem recriar tunel ativo. O menu **8. Selecionar transporte local ou tunel online** permite trocar essa preferencia.

- **Auto:** prioriza o tunel existente quando o processo esta ativo; caso contrario seleciona **Local** se o runtime MCP completo ja estiver disponivel.
- **Local:** usa o MCP `stdio` no computador, aproveitando o runtime e o broker socket locais. Nao e acesso remoto por si so.
- **Existing:** reutiliza o tunel configurado e em execucao no launcher, sem duplicar processo.
- **Online:** usa o cliente oficial `tunnel-client`. Exige `tunnel_id` existente/criado na OpenAI Platform, credencial de controle no ambiente local e permissao da conta. O assistente executa `init`, `doctor` e `run` apenas nas acoes explicitamente selecionadas, sem gravar API keys.

Em contas/workspaces sem a ferramenta MCP nativa anunciada, a habilidade de integracao pode usar **Remote Desktop Commander** como executor independente: leitura (`read_file`), comando (`start_process`), edicao (`edit_block`), acompanhamento (`interact_with_process`) e imagens autorizadas (`read_file`). O agente precisa descobrir e chamar cada ferramenta real do Commander, confirmar o computador e respeitar as permissoes. Nenhuma chave ou `turn_token` do Codex e transferido para ele.

Este mecanismo permite executar tarefas locais autorizadas por uma via alternativa; nao cria ferramentas `codex_exec` no host que as omitiu e nao elimina as regras da plataforma.

Consulte [Transporte e contingencia](docs/TRANSPORTE-E-CONTINGENCIA.md) para operacao, seguranca e criterios de homologacao.

## Conectar ao ChatGPT (fluxo oficial de servidor MCP)

O runtime local que anuncia 6/6 ferramentas via `tools/list` nao comprova que elas estejam visiveis no ChatGPT. O pacote local e o plugin de habilidades nao conseguem registrar ou autorizar ferramentas no host por conta propria.

**Antes de instalar ou vincular:** confira a elegibilidade do plano e do workspace. Na documentacao oficial consultada em 05/11/2026, o **MCP completo com ferramentas de execucao** esta disponivel em ChatGPT **Business e Enterprise/Edu** com permissoes adequadas. O plano **Pro** permite conexoes MCP personalizadas com permissoes de leitura/busca (`read/fetch`); o **Plus** nao oferece MCP completo. Portanto, `codex_exec` pode continuar indisponivel mesmo com as seis ferramentas anunciadas localmente. Nenhum instalador, skill ou ZIP muda a permissao da conta. Confira sempre a documentacao oficial, pois as regras de disponibilidade podem mudar.

Para o plano **Plus**, o caminho operacional imediato e usar o **Remote Desktop Commander** disponivel no ChatGPT, caso esteja conectado e autorizado. Ele e uma integracao **independente**; nao torna `codex_exec` uma ferramenta da conexao Native2. O fluxo de uso nativo completo continua condicionado a plano e permissao de workspace elegiveis. Evite reinstalacoes repetidas do launcher ou do plugin quando o bloqueio for de elegibilidade da conta.

No PowerShell, o diagnostico pode ser executado com `powershell -NoProfile -File .\\scripts\\Vincular-ChatGPT.ps1 -Json -ChatGPTPlan Plus`. O parametro e uma **declaracao manual** e nunca comprova o plano; o campo `chatgptPlanMcpEntitlement` permanece `not_verified`.

O script local nao consegue consultar a elegibilidade da conta ChatGPT nem a associacao do tunel ao workspace. Ambos permanecem explicitamente `not_verified` no relatorio; nao interprete isso como erro de autenticacao.

1. Execute `Vincular-ChatGPT.cmd` no menu 7. Ele consulta a instalacao em modo somente leitura, sem imprimir identificadores de tunel, tokens ou credenciais.
2. No **ChatGPT web**, abra **Plugins → + → Adicionar servidor MCP personalizado** (Add custom MCP server).
3. Escolha **Conexao: Tunel** (Tunnel), selecione o tunel ja existente da conta/workspace e configure a autenticacao apropriada. Nao recrie o tunel automaticamente.
4. Confirme o aviso de risco e confira as **seis ferramentas** detectadas na revisao do servidor; entao crie/habilite o plugin de conexao.
5. Abra uma **nova conversa** com o plugin habilitado, use `codex_tool_inventory` e execute uma leitura inofensiva via `codex_exec`. Somente a resposta real da ferramenta valida a integracao.

Se a opcao **Adicionar servidor MCP personalizado** nao aparecer ou nao aceitar ferramentas de execucao, verifique primeiro o plano e as permissoes do workspace; esse bloqueio nao e corrigido reinstalando o Windows. Se o tunel nao estiver na lista, confira a associacao ao workspace ChatGPT e as permissoes de tunel `Tunnels Read + Use`. Se as ferramentas nao aparecerem na revisao do servidor, nao continue com a instalacao como se estivesse concluida: investigue autenticação, canal remoto e catalogo. Se a opcao de servidor MCP personalizado nao existir, verifique as politicas da conta/workspace.

O menu 3 (`Configurar-Conexao.cmd`) continua como **modo legado** de geracao de ZIP pessoal para hosts compatíveis. Ele nao substitui o fluxo oficial de adicionar e testar um servidor MCP no ChatGPT e nao deve ser usado para sobrescrever um plugin 0.5.x com um pacote 0.4.x.

Documentacao oficial: https://help.openai.com/pt-br/articles/12584461-connecting-custom-mcp-servers-in-chatgpt e https://developers.openai.com/api/docs/guides/secure-mcp-tunnels . Nunca publique o ZIP pessoal gerado nem insira chaves de API em conversas.

## Painel de conexões

Abra **Painel de perfis**. Cadastre nome, endpoint, autenticação prevista e ambiente. Edite, remova, importe ou exporte até 100 perfis. O painel valida o formato, não conectividade MCP. Nenhuma requisição de rede é feita pelo painel.

Perfis ficam na memória até exportar; fechar a página perde alterações. Importe o JSON para recuperar. Não inclua credenciais. O assistente de túnel é separado dos perfis de endpoints HTTPS; a porta 17841 não deve ser presumida como endpoint MCP.

## Atualizar e voltar à versão anterior

Instale uma nova versão no mesmo destino. Cada execução usa uma pasta exclusiva em `releases`; versões e perfis anteriores permanecem intactos. Exporte os perfis da versão antiga e importe na nova. Para voltar, execute `Iniciar.cmd` na pasta anterior. Não existe atualização silenciosa nem migração automática de dados.

## Relatorio de falhas no GitHub

No painel Windows, utilize **Previa de falha** para consultar um resumo sanitizado e **Enviar Issue no GitHub** para registrar o problema com confirmacao. O relatorio inclui somente contagens, estado do MCP local e codigos de falha, nunca caminhos completos, tokens ou logs originais. O GitHub e publico.

Quando a correcao for **comprovada** por um rollout valido, pelo inventario real `codex_tool_inventory` no ChatGPT e por uma chamada nativa de leitura aprovada, utilize **Apagar Issue corrigida** para excluir o relatorio no GitHub. O painel exige uma atestacao recente dos testes e confirmacao expressa. Logs originais do computador permanecem intocados. Consulte [docs/RELATORIOS-DE-FALHAS.md](docs/RELATORIOS-DE-FALHAS.md) para o procedimento e as limitacoes de verificacao.

## Diagnóstico

- **ENOSPC:** libere espaço na unidade do perfil Windows e dos temporários. Instalar o painel em D: não move Codex Web GPT de C:.
- **Proxy ativo, MCP indisponível:** confira o túnel selecionado, o conector no host, as ferramentas disponíveis e o resultado de Verify runtime.
- **Sem listener 17841:** abra o launcher e examine seu diagnóstico; não encerre processos aleatoriamente.
- **Limite de solicitações:** respeite o prazo mostrado pelo serviço; não crie ciclos de novas tentativas.
- **Bloqueio de script:** confirme a origem e revise os arquivos. Não altere a política global do Windows.

`Diagnosticar.cmd` consulta modo, CLI, porta, processo do túnel e espaço livre. Não mostra configuração completa, tokens nem linhas de comando de processos. Revise resultados antes de compartilhar: eles podem conter caminhos locais.

## Remover

Feche o painel e apague somente a pasta da versão instalada, após exportar os perfis desejados. O projeto não cria serviço, tarefa agendada, entrada no Registro ou inicialização automática. Remover o painel não remove o conector no ChatGPT nem o launcher.

## Desenvolvimento e verificações

Execute `python3 scripts/validate.py` e `node --test tests/profiles.test.cjs`. Gere uma distribuição limpa com `python3 scripts/package.py`. O pacote exclui dados, logs, credenciais, arquivos Git e testes. `SHA256SUMS` permite conferir integridade, mas não substitui assinatura digital ou verificação de origem.

O workflow executa esses testes em Linux e análise de sintaxe PowerShell em Windows. A instalação interativa, a importação no ChatGPT e a comunicação com um túnel real precisam de validação no ambiente de destino. Nenhuma dessas etapas é comprovada pelos testes de empacotamento.

Veja [SECURITY.md](SECURITY.md) e [CHANGELOG.md](CHANGELOG.md). Para contribuir, descreva o ambiente, o comportamento esperado e os passos de reprodução, sem segredos.

## Links de download no chat

O Native2 configura a conexão MCP e fornece orientação. O transporte das mensagens e a renderização da conversa pertencem ao launcher/host Codex Web GPT, cujo código não está neste repositório.

Use links HTTPS do GitHub em respostas destinadas ao usuário. Links de código-fonte podem apontar para o ZIP da branch; versões fixas devem usar tags ou Releases efetivamente existentes. Não invente URLs de assets ou anuncie downloads antes de publicar. Links sandbox dependem da sessão que contém o arquivo. Não existe neste projeto um serviço próprio de hospedagem de arquivos ou conversão automática desses links.
