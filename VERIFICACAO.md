# Verificação da versão 0.4.0 BETA

Executado neste ambiente:

- Validação do manifesto, arquivos obrigatórios e ausência de identificadores pessoais de túnel.
- Quatro testes Node: HTTPS/loopback aceitos; HTTP remoto e credenciais rejeitados; importações malformadas rejeitadas; campos extras descartados.
- Geração do ZIP público e checksum SHA-256.

Pendente no ambiente de destino:

- Análise PowerShell pelo workflow Windows após publicar no GitHub.
- Instalação interativa, seleção da unidade e cópia em Windows PowerShell 5.1.
- Geração e importação do ZIP pessoal no host.
- Verify runtime, descoberta de ferramentas e chamada MCP real.

Não foi feita instalação no computador do usuário, mudança do launcher ou publicação de um servidor. Os testes locais não demonstram comunicação MCP.
