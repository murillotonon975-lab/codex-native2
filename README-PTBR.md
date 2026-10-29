# Codex Native2

Assistente comunitário para configurar e diagnosticar a integração entre Codex Web GPT e ChatGPT no Windows. **0.4.0 BETA.** Não é um produto oficial da OpenAI e não distribui o launcher, o Codex CLI nem um servidor MCP próprio.

[Baixar código e instalador (ZIP)](https://github.com/murillotonon975-lab/codex-native2/archive/refs/heads/main.zip) · [Ver arquivos](https://github.com/murillotonon975-lab/codex-native2)

O ZIP contém o projeto completo. Extraia antes de executar os arquivos CMD. Não envie o ZIP de código-fonte como atualização de um plugin instalado; o assistente gera um pacote pessoal separado.

## Instalar em poucos passos

1. Baixe o código em **Code → Download ZIP** e extraia em uma pasta.
2. Execute `Instalar-Native2.cmd`. Não precisa abrir como administrador. O PowerShell usa uma exceção de execução somente neste processo.
3. Aceite a unidade fixa com mais espaço ou informe outra pasta. O instalador verifica espaço, escrita e integridade das cópias.
4. Abra `Iniciar.cmd` na pasta indicada ao final. Também é possível usar o menu diretamente na pasta extraída, sem instalar.

O menu oferece painel de perfis, configuração do túnel, diagnóstico e este guia. Windows PowerShell 5.1 ou posterior; sem Node, Python ou dependências adicionais para usar.

## Conectar ao ChatGPT

Pré-requisito: Codex Web GPT instalado separadamente, modo `full` e túnel ativo na sua conta. Use o fluxo mostrado pelo launcher para criar o túnel e registrar o conector. Recursos e permissões disponíveis dependem da conta e do host.

1. No menu, escolha **Configurar meu túnel**.
2. Informe o seu identificador `tunnel_` seguido de 32 caracteres hexadecimais. Não informe chave API ou senha. Outros formatos não são aceitos nesta versão.
3. O assistente gera um ZIP pessoal na pasta `dados`; importe esse ZIP no host que aceita esse formato de plugin. Se o host não oferecer importação, registre o conector pelo fluxo do launcher.
4. Autorize as ações necessárias no host e mantenha o launcher aberto. Execute **Verify runtime**.
5. Peça para listar as ferramentas e executar uma chamada somente de leitura. Somente a chamada bem-sucedida comprova funcionamento MCP.

O pacote público não inclui `mcp.json` vinculado a uma conta. O assistente gera esse arquivo localmente com seu túnel. Autenticação `none` reproduz o transporte de túnel gerenciado pelo host, não uma recomendação para expor servidores públicos sem autenticação. Não publique o ZIP pessoal gerado.

## Painel de conexões

Abra **Painel de perfis**. Cadastre nome, endpoint, autenticação prevista e ambiente. Edite, remova, importe ou exporte até 100 perfis. O painel valida o formato, não conectividade MCP. Nenhuma requisição de rede é feita pelo painel.

Perfis ficam na memória até exportar; fechar a página perde alterações. Importe o JSON para recuperar. Não inclua credenciais. O assistente de túnel é separado dos perfis de endpoints HTTPS; a porta 17841 não deve ser presumida como endpoint MCP.

## Atualizar e voltar à versão anterior

Instale uma nova versão no mesmo destino. Cada execução usa uma pasta exclusiva em `releases`; versões e perfis anteriores permanecem intactos. Exporte os perfis da versão antiga e importe na nova. Para voltar, execute `Iniciar.cmd` na pasta anterior. Não existe atualização silenciosa nem migração automática de dados.

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
