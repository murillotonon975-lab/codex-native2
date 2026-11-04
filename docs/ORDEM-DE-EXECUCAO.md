# Ordem de execução do Codex Native2 no Windows

> **Versão disponível na branch `main`: 0.4.0 BETA (painel local/diagnóstico).** A configuração unificada para todos os usuários está em desenvolvimento na [PR #1](https://github.com/murillotonon975-lab/codex-native2/pull/1). **Não confunda um painel de perfis com o conector MCP funcionando dentro do ChatGPT.**

Este guia serve ao mesmo Codex Native2 para o desenvolvedor e a comunidade. Cada pessoa terá sua própria conta, túnel e autorização. **Não há edição pessoal e pública com recursos diferentes**; existe uma versão estável e uma versão futura em teste.

## 1. Comece aqui: qual é o seu caso?

### A. Primeira instalação — versão atual da branch main

1. Baixe o [ZIP da branch main](https://github.com/murillotonon975-lab/codex-native2/archive/refs/heads/main.zip) e **extraia** o ZIP. Se a pasta extraída estiver aninhada (`codex-native2-main\codex-native2-main`), abra a pasta **interna**, onde está `Instalar-Native2.cmd`.
2. **Opcional, recomendado:** abra o PowerShell nessa pasta e rode o ensaio sem escrita:
   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Instalar-Native2.ps1" -PlanOnly
   ```
3. Execute **`Instalar-Native2.cmd`** uma única vez. Ele instala **somente o painel local**, copiando os arquivos para uma pasta de versão isolada no disco escolhido; **não instala Codex CLI, Codex Web GPT, servidor MCP ou conector ChatGPT**.
4. O instalador normalmente abre **`Iniciar.cmd`** da pasta instalada. Se não abrir, vá à pasta indicada ao final e execute **`Iniciar.cmd`**. **Não precisa executar ambos simultaneamente**.
5. No menu **0.4.0**, use primeiro **3 — Diagnosticar conexão (somente leitura)**. Em seguida, **1 — Abrir painel de perfis**, caso queira cadastrar endpoints de referência. O painel não conecta MCP por si.
6. Instale e configure **Codex CLI** e **Codex Web GPT** separadamente, usando seus fluxos oficiais. Entre no ChatGPT no navegador incorporado, execute `Run browser smoke test`, instale a integração em `Setup → Install into Codex`, conecte seu túnel em `MCP → Connect harness` e associe o conector no ChatGPT.
7. Em `MCP → Verify runtime`, verifique associação e permissões. Finalmente, inicie **uma nova tarefa Web** e faça uma **chamada MCP somente de leitura**. Túnel saudável, MCP registrado e ferramenta executando são verificações distintas.

### B. Você já usa Codex Web GPT / já tem túnel (caso de manutenção)

1. **Não reinstale nem recrie chaves/túneis desnecessariamente.** Preserve o conector `Codex Native` legado, suas chaves e o projeto atual.
2. Da pasta extraída da versão 0.4.0, execute **`Diagnosticar.cmd`**; ele é o primeiro teste somente de leitura.
3. Opcionalmente execute **`Abrir-Painel.cmd`** para visualizar/cadastrar perfis locais. Isso **não** altera o túnel real do ChatGPT.
4. Se a tarefa for testar a **nova configuração unificada** na PR #1, consulte a seção de desenvolvimento abaixo. **Não use o instalador 0.4.0 esperando obter a interface nova**.

### C. Desenvolvedor/testador da PR #1 (código em andamento)

1. Baixe/extraia a [branch `feature/unified-settings-mcp-20261104`](https://github.com/murillotonon975-lab/codex-native2/tree/feature/unified-settings-mcp-20261104) **em outra pasta**, sem substituir a instalação atual.
2. Faça primeiro o teste **somente leitura**, no PowerShell aberto na pasta da branch:
   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\Configurar-Native2-GUI.ps1" -CheckOnly
   ```
3. Para abrir a **nova interface gráfica local de configuração de perfil**, execute **`Iniciar.cmd` → 1 — Configuração inicial** na pasta da **branch**, ou:
   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\Configurar-Native2-GUI.ps1"
   ```
4. A interface permite **detectar e salvar o ID do túnel em um perfil local por usuário** (em `%LOCALAPPDATA%\CodexNative2\settings.json`); **não** grava chaves de API e **não** muda automaticamente o túnel associado no launcher/ChatGPT.
5. Para realmente alterar a conexão MCP, use os controles autorizados do Codex Web GPT e o conector do ChatGPT, seguido de `Verify runtime` e uma chamada real de leitura. A configuração nativa no ChatGPT (`openai/settings`) e a reconexão integrada ainda estão **pendentes**.

## 2. Para que serve cada arquivo?

| Arquivo | Quando usar | O que faz |
|---|---|---|
| **`Diagnosticar.cmd`** | **Primeiro** se já tem Codex / antes de mudar configuração | Consulta versão, processo e estado local, sem alterar configurações |
| **`Instalar-Native2.cmd`** | **Uma vez**, somente ao instalar o painel 0.4.0 | Copia o pacote para uma pasta própria, com verificação de integridade; **não instala MCP** |
| **`Instalar-Native2.ps1`** | Opcional, para `-PlanOnly` ou instalação com parâmetros | Script chamado pelo CMD de instalação |
| **`Iniciar.cmd`** | Depois de instalar, ou diretamente da pasta extraída | Menu de opções; seu conteúdo depende da branch/versão |
| **`Abrir-Painel.cmd`** | Opcional | Abre HTML local para perfis de endpoints; não autentica nem testa MCP |
| **`Configurar-Conexao.cmd`** | **Fluxo legado 0.4.0**; use apenas se o host aceitar um pacote individual e isso for necessário | Gera ZIP vinculado ao túnel informado; **não** altera launcher/host |
| **`Configurar-Conexao.ps1`** | Chamado por `Configurar-Conexao.cmd` | Valida o ID e cria o pacote legado |
| **`scripts\Configurar-Native2-GUI.ps1`** | **Somente na PR #1**; após diagnóstico de leitura | Interface gráfica local do perfil e testes; não reconfigura o conector remoto |
| **`Publicar-GitHub.ps1`** | **Somente mantenedores criando um repositório novo**; **não executar neste repositório existente** | Usa `gh repo create`; pode tentar criar/publicar repositório indevido |
| **`scripts\validate.py` / `scripts\package.py`** | Mantenedores/CI | Validar estrutura/empacotar, não são instaladores |
| **`tests\...`** | Desenvolvimento/CI | Testes automatizados, não são instaladores |

## 3. O que ainda NÃO é automático

- Instalação e atualização do **Codex Web GPT**: aplicativo externo, instalado por seu próprio processo.
- Criação de contas, chaves, workspace e túnel OpenAI: exige login, consentimento e configuração na conta de cada usuário.
- Instalação/associação/permissões do conector ChatGPT: dependem dos controles reais oferecidos pelo host.
- Um `tunnelId` no perfil local **não substitui** o ID efetivamente associado ao conector ChatGPT.
- A tela **Plugins → Codex Native2 → Configurações do servidor MCP** ainda precisa de backend `settings.read` / `settings.update`; ela não surge apenas de uma skill ou manifesto.
- Atualização automática e rollback de conexões ainda requerem implementação e testes; **não** executar scripts de terceiros com privilégios amplos sem revisão.

## 4. Procedimento de segurança e resolução de problemas

- Nunca publique ou envie para suporte uma API key, OAuth token, cookie, arquivo de `secrets` ou ZIP ligado ao seu túnel.
- `401 Unauthorized` ao ler `/v1/tunnels/... ` indica autorização inválida/insuficiente: não resolver por mudar permissões locais indiscriminadamente.
- `Embedded launcher browser is unavailable` e `ChatGPT composer is unavailable` são problemas da sessão do navegador incorporado; não são prova de que o túnel foi apagado.
- `codex mcp list` mostra MCPs **registrados no Codex CLI**, não prova que as ferramentas `codex_exec` e `codex_tool_inventory` chegaram ao ChatGPT.
- Manter backup e evitar apagar pastas do Codex, repositórios de trabalho, perfis e conectores existentes.
- Se o Native2 não for anunciado no ChatGPT, diagnosticar com uma ferramenta alternativa autorizada (como Remote Desktop Commander) e registrar o resultado real.

## 5. Atualizações e publicação

**Apenas a versão 0.4.0 está na branch main na data desta documentação.** A evolução unificada permanece na [PR #1 em rascunho](https://github.com/murillotonon975-lab/codex-native2/pull/1). Não faça merge ou declare compatibilidade pública completa antes de testar Windows, ferramentas MCP no ChatGPT, recuperação de credenciais e atualização/rollback.

Um único produto = **um repositório, mesmo código e mesma versão para todos**; configurações, credenciais e permissões são individuais.
