# NovaClean
Open-source alternative to CleanMyMac using REA
# NovaClean

Reimplementação **original e independente** inspirada na CleanMyMac 5 (5.7.2, Mac App Store), construída a partir de uma análise estática via REA do app instalado nesta máquina. Código, nomes, ícones, textos e identidade são 100% originais — nenhum asset, ícone, string ou código da MacPaw foi copiado. Os módulos fazem o mesmo *tipo* de trabalho (saneamento de disco), por implementação própria.

Sem afiliação com a MacPaw. Use por sua conta: as ações de "limpeza" movem arquivos para a **Lixeira** (recuperável) exceto "Esvaziar Lixeira", que é permanente.


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
