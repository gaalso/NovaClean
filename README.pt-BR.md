# NovaClean

**Limpeza, organização e monitoramento do macOS.**

NovaClean é um aplicativo open source para macOS que reúne ferramentas para analisar o uso do disco, localizar arquivos grandes, gerenciar aplicativos e monitorar o desempenho do sistema.

[**Baixar NovaClean v1.3.0**](https://github.com/gaalso/NovaClean/releases/tag/v1.3.0) · [Código-fonte](https://github.com/gaalso/NovaClean)

**Idioma:** [English](README.md) | Português (Brasil)

## Funcionalidades

- **Cuidado Inteligente:** reúne análises de limpeza e apresenta sugestões em um só lugar.
- **Lixo do Sistema:** identifica caches que podem ser removidos.
- **Arquivos Grandes:** encontra arquivos grandes em pastas pessoais.
- **Explorador de Espaço:** visualiza a distribuição dos arquivos e permite navegar pelas pastas.
- **Aplicativos:** lista os aplicativos instalados e oferece a opção de movê-los para a Lixeira.
- **Lixeira:** consulta o espaço ocupado e permite esvaziá-la.
- **Acelerar:** apresenta informações sobre o uso da memória e os aplicativos em execução.
- **Monitor do Sistema:** acompanha CPU, memória, armazenamento, estado térmico e processos.

## Download e instalação

**Requisito:** macOS 12 ou posterior.

1. Acesse a [página de lançamento do NovaClean v1.3.0](https://github.com/gaalso/NovaClean/releases/tag/v1.3.0).
2. Expanda a seção **Assets**, se necessário.
3. Escolha o instalador `.dmg` adequado ao seu Mac.
4. Abra a imagem de disco e arraste o NovaClean para a pasta Aplicativos.

Confira os nomes dos arquivos na página de lançamento para distinguir as versões Intel, Apple Silicon e Universal.

### Aviso de segurança

Esta versão não possui notarização da Apple. O macOS pode exibir um aviso de segurança na primeira abertura do aplicativo. Só prossiga se confiar na origem e tiver verificado o arquivo baixado.

Revise as ações de limpeza antes de aplicá-las. A maioria das remoções é enviada para a Lixeira, mas esvaziá-la pode excluir arquivos permanentemente.

## Requisitos para desenvolvimento

- macOS 12 ou posterior
- Xcode Command Line Tools
- Swift e as ferramentas de compilação necessárias

## Compilar a partir do código-fonte

Clone o repositório:

```sh
git clone https://github.com/gaalso/NovaClean.git
cd NovaClean
```

Compile a versão Universal:

```sh
./build.sh
```

Outras opções de compilação:

```sh
./build.sh intel
./build.sh silicon
```

Abra o aplicativo compilado:

```sh
open build/NovaClean.app
```

Os instaladores são gerados na pasta `dist/`, conforme o processo de compilação e empacotamento do projeto.

## Tecnologias

- Swift
- SwiftUI
- AppKit

## Escopo do projeto

NovaClean é uma implementação independente de ferramentas de limpeza e monitoramento do sistema. Não possui afiliação com, patrocínio de ou endosso da MacPaw ou do CleanMyMac.

O aplicativo não pretende substituir ferramentas especializadas de detecção de malware, monitoramento da saúde do sistema ou desinstalação completa de aplicativos.

## Documentação

- [`IDENTITY.md`](IDENTITY.md) — identidade visual do projeto.
- [`blueprint-REA.md`](blueprint-REA.md) — documentação técnica e análise de referência.
- [`GITHUB.md`](GITHUB.md) — instruções de publicação e distribuição.

## Como contribuir

Contribuições, sugestões e relatos de erros são bem-vindos. Use a seção [Issues](https://github.com/gaalso/NovaClean/issues) para relatar problemas ou sugerir melhorias.

## Licença

Uma licença ainda não foi especificada. Até que uma licença open source seja adicionada, não presuma que o código pode ser reutilizado, modificado ou redistribuído livremente.

---

Desenvolvido por [@gaalso](https://github.com/gaalso).
