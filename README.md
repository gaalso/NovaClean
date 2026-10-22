# NovaClean

Reimplementação **original e independente** inspirada na CleanMyMac 5 (5.7.2, Mac App Store), construída a partir de uma análise estática via REA do app instalado nesta máquina. Código, nomes, ícones, textos e identidade são 100% originais — nenhum asset, ícone, string ou código da MacPaw foi copiado. Os módulos fazem o mesmo *tipo* de trabalho (saneamento de disco), por implementação própria.

Sem afiliação com a MacPaw. Use por sua conta: as ações de "limpeza" movem arquivos para a **Lixeira** (recuperável) exceto "Esvaziar Lixeira", que é permanente.

## Identidade visual (v1.1 "Nova")

Conceito, paleta e logo documentados em [`IDENTITY.md`](IDENTITY.md). Logo "nova nos cuidados": gradiente `#7A2CFF → #A52CFF → #FF3E8E`, anel orbital e sparkle de 4 pontas — o ícone do app é gerado por [`tools/gen_icon.swift`](tools/gen_icon.swift) e empacotado em `src/AppIcon.icns`.

**v1.2 — grafismo analítico:** orbit chart de bolhas em "Meu Espaço" (clique = drill-down), barra espectral de categorias e uso do disco no "Cuidado Inteligente", **pré-seleção automática de sugestões** ao abrir cada tela (Lixo: removíveis ≥ 128 MB; Arquivos Grandes: ≥ 300 MB) e botão **Selecionar tudo ↔ Deselecionar tudo**. Detalhes em [`IDENTITY.md`](IDENTITY.md).

**v1.3 — tudo num clique + sistema:**
- **Cuidado Inteligente** executa os 4 módulos **em paralelo** e tudo acontece na mesma tela: dial + espectro + listas de sugestão com toggles + botão **"Aplicar limpeza"** (com opção de esvaziar a Lixeira ao concluir). Nada de trocar de aba.
- **Acelerar**: memória física em uso/livre, liberar caches em disco (`purge`) e lista de apps ≥ 100 MB com CPU/RAM — seleção pré-marcada (≥ 600 MB) e encerramento com quit normal.
- **Sistema**: CPU (user/sys/ocioso), memória, estado térmico do kernel (xcpm), disco e **top processos por RAM** — auto-atualiza a cada 6 s.
- **Meu Espaço** redesenhado: **treemap squarified** (mapa de áreas sem sobreposição, estilo Space View) como herói da tela + listas de pastas/destaques com remoção por item.

## Construir e executar

Requisito: macOS 12+ e **Xcode Command Line Tools**. Binários: `intel` (x86_64), `silicon` (Apple Silicon arm64) ou `universal`.

```sh
./build.sh             # universal (Intel + Apple Silicon) — padrão
./build.sh intel       # apenas x86_64
./build.sh silicon     # apenas arm64 (Apple Silicon)
open build/NovaClean.app
```

Instaladores prontos (`.dmg`) ficam em `dist/` — ver [`GITHUB.md`](GITHUB.md).

## Módulos

| Módulo | O que faz |
|---|---|
| Cuidado Inteligente | Orquestra as 4 análises (caches, arquivos grandes, lixeira, apps) e resume o liberável |
| Lixo do Sistema | Mede `~/Library/Caches` (removível → Lixeira) e `/Library/Caches` (só informativo) |
| Arquivos Grandes | Varre Desktop/Documents/Downloads/Movies/Music/Pictures por arquivos ≥ 50 MB |
| Meu Espaço | Visualização por pastas do diretório home com drill-down, arquivos por nível e destaques ≥ 100 MB |
| Aplicativos | Inventário de `/Applications` + `~/Applications` (nome, versão, tamanho), desinstalar move para a Lixeira |
| Lixeira | Tamanho, contagem e esvaziar com confirmação |

## Blueprint

`blueprint-REA.md` documenta como a CleanMyMac real está organizada (descoberto via REA: Info.plist, assinatura/entitlements, 140+ frameworks, strings de localização) e como o NovaClean mapeia esses módulos — incluindo tudo o que a recriação **não** cobre (verificação de malware real, XPC/health monitor, remoção de leftovers, contas em nuvem etc.).

## Notas técnicas

- SwiftUI + AppKit, compilado com `swiftc` (sem dependências externas), alvo `x86_64-apple-macos12.0`.
- Scans rodam em `Task.detached` com limite de entradas para manter a UI responsiva.
- Ações destrutivas movem para a Lixeira via `FileManager.trashItem`.
