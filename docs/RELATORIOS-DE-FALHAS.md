# Relatorios de falhas do Codex Native2 no GitHub

O painel Windows possui tres acoes: **Previa de falha**, **Enviar Issue no GitHub** e **Apagar Issue corrigida**. A mesma funcionalidade esta disponivel por CLI em scripts/Relatorio-Falhas-GitHub.mjs.

## Coleta e privacidade

O relatorio utiliza uma lista fechada de campos: data UTC, quantidade de rollouts e turnos analisados, quantidade de falhas de validacao de workspace, ultima data da falha e resultado da consulta local de ferramentas MCP. O script examina somente os registros session_meta, turn_context e o **tipo** de erro reconhecido. Ele nao inclui linhas de log, textos de conversas, IDs de turnos, IDs de tunel, caminhos locais, credenciais, comandos, detalhes do processo ou chaves.

O repositorio murillotonon975-lab/codex-native2 e **publico**. Antes de enviar, abra a previa para revisar. O envio ocorre somente apos uma acao separada e confirmacao do usuario. No Windows, o painel usa GitHub CLI: execute uma vez `gh auth login` com sua conta autorizada antes da primeira publicacao ou exclusao. A conexao GitHub instalada no ChatGPT nao autentica automaticamente o CLI do computador.

## Comandos de operacao

Execute na raiz do repositorio ou na pasta instalada do plugin:

~~~powershell
node scripts/Relatorio-Falhas-GitHub.mjs
node scripts/Relatorio-Falhas-GitHub.mjs --json
node scripts/Relatorio-Falhas-GitHub.mjs --publish --confirm-publish
~~~

A publicacao cria uma GitHub Issue identificada pelo marcador codex-native2-diagnostic-report:v1. Nao usa Issues antigas, nao altera PRs, nao faz merge nem publica codigo. Nao publica os logs originais.

## Apagar no GitHub apos corrigir

**A falha so esta comprovadamente corrigida quando tres checagens forem aprovadas na tarefa ChatGPT/Codex autorizada:**

1. Novo rollout com cwd dentro das raizes da propria sessao, sem erro de workspace.
2. O host anunciou codex_tool_inventory na tarefa, e o inventario foi obtido.
3. Uma chamada nativa de leitura (por exemplo, obter o cwd) foi concluida com resultado real.

O coletor local **nao consegue verificar as etapas 2 e 3**. A consulta local de seis ferramentas, o sucesso do launcher e uma Issue fechada nao comprovam o funcionamento remoto.

Apos completar essa verificacao, o operador responsavel pela tarefa fornece um arquivo JSON *de atestacao*, revisado contra os resultados reais do ChatGPT, com o seguinte formato:

~~~json
{
  "schema": "codex-native2-resolution-v1",
  "source": "authorized-chatgpt-task",
  "checkedAt": "2026-11-04T18:00:00.000Z",
  "workspaceRolloutPassed": true,
  "hostInventoryAnnounced": true,
  "nativeReadSucceeded": true
}
~~~

A data deve corresponder ao teste real e ter no maximo 24 horas. **O JSON e uma declaracao do operador e nao uma assinatura criptografica.** Nao gere um arquivo com valores positivos sem os testes reais; a ferramenta valida o formato, mas nao consegue autenticar a origem do arquivo.

Depois, selecione **Apagar Issue corrigida** no painel ou execute:

~~~powershell
node scripts/Relatorio-Falhas-GitHub.mjs --delete NUMERO_DA_ISSUE --proof CAMINHO_DO_COMPROVANTE.json --confirm-delete
~~~

O comando confere se a Issue foi criada pelo gerador, exige a atestacao recente e confirmacao explicita, depois usa a mutacao GraphQL deleteIssue. Isso exclui a Issue de diagnostico no GitHub, incluindo seus comentarios associados; requer permissao do repositorio para excluir Issues. Se o GitHub rejeitar a exclusao ou a prova estiver incompleta, o programa informa falha e **mantem a Issue**. Ele nunca troca a exclusao por fechamento ou simples apagamento do corpo, que manteriam os dados no historico de revisoes.

A exclusao no GitHub nao garante remover copias de terceiros, notificacoes por email, caches e eventuais backups do provedor. Por isso o relatorio ja e minimizado antes do envio. O recurso nao apaga nenhum log original do computador ou arquivos de trabalho.

## Estado atual do defeito

Enquanto codex_tool_inventory nao aparecer no catalogo **do host ChatGPT** e nao houver chamada nativa de leitura aprovada na tarefa, o relatorio permanece aberto e a limpeza nao deve ser acionada. O status de origem local 6/6 nao equivale a resolucao.

## Desenvolvimento e verificacoes

~~~powershell
node --test tests/failure-report.test.mjs
node --test tests/mcp-probe.test.mjs tests/inventory-integrations.test.mjs
python scripts/validate.py
~~~

A validacao da interface grafica requer Windows com Node.js e GitHub CLI. Publicar uma Issue real e exclui-la devem ser testados em uma Issue **de teste criada especificamente para isso**, apos confirmar que a conta tem permissao no repositorio e que nenhum dado pessoal foi incluido.
