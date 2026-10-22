# NovaClean — Identidade Visual v1.0

## Conceito: "Nova"

Uma **nova** é uma explosão de brilho de uma estrela — a metáfora do app: dar brilho (de volta) ao Mac limpando o que pesa. Identidade escura "deep space" com energia em gradient violeta→magenta e um sparkle de 4 pontas como símbolo.

## Paleta

| Papel | Cor | Hex |
|---|---|---|
| Fundo (deep space) | quase-preto azulado | `#0E0E16` |
| Fundo de painel/sidebar | tomb violeta-escuro | `#171723` |
| Card | superfície elevada | `#1E1E2C` |
| Traço/borda sutil | white alpha | `#FFFFFF 7%` |
| Texto primário | branco | `#FFFFFF` |
| Texto secundário | cinza frio | `#9DA0B0` |
| **Brand start** | indigo elétrico | `#7A2CFF` |
| **Brand mid** | violeta | `#A52CFF` |
| **Brand end** | magenta | `#FF3E8E` |
| Sucesso | verde | `#34C77B` |
| Perigo | vermelho | `#FF453A` |

Gradiente de marca: `#7A2CFF → #A52CFF → #FF3E8E`, diagonal 45° (topo-esquerda → baixo-direita). É usado em: chips de ícone selecionados, botão "Analisar agora", barras de Meu Espaço, o dial do Cuidado Inteligente e a logo.

## Tipografia

- **SF Pro Rounded** em títulos de hero/título do dial (peso heavy) — voz "amigável-cósmica".
- **SF Pro Text** no resto; números com `.monospacedDigit()`.
- Hierarquia: título de tela `largeTitle bold`, sub `callout` secundário, dados `headline`.

## Logo

Quadro arredondado (raio ≈ 22,5%) com o gradiente de marca, um **anel orbital** branco translúcido (35%) — o "escaneamento" em volta — e um **sparkle de 4 pontas** branco levemente descentralizado, com uma mini-estrela inferior esquerda (o "detalhe limpo").

Arquivos:
- `build/RE-Collected icon set → src.iconset → Resources/AppIcon.icns` (ícone do app/Finder/Dock)
- Componente in-app: `NovaLogo(size:)` no código (mesma geometria, desenhada em SwiftUI/Core Graphics / Path)
- Fonte do desenho: `tools/gen_icon.swift`

## Componentes de identidade no código

- `Theme` — cores e gradientes centralizados
- `BrandChip` — quadrado arredondado 28–32px com gradiente para ícones das rows
- `PillButton` — botão gradiente com glow suave (ação primária, sempre gradients, nunca cinza)
- `NovaDial` — anel AngularGradient com número central grande
- `Card` — superfície `#1E1E2C` com borda `white 7%` e raio 14

## Regras

1. Dark sempre. A identidade não tem modo claro (o contraste é parte da marca).
2. Gradiente **only** em elementos de energia (ação primária, métricas hero, barra/dial). Nunca em textos de corpo.
3. Emoji não; SF Symbols apenas.
4. Rows selecionadas ganham borda do gradiente; nunca fundo claro.

## v1.2 — grafismo analítico

- **Órbita do espaço** (`BubbleCanvas`): packing de bolhas em espiral de ângulo dourado (`Engine.packBubbles`), raio ∝ √bytes, 8 gradientes cíclicos da paleta, clique = drill-down. Visual "Space Lens" próprio.
- **Barra espectral** (`SpectrumBar`): categorias de limpeza empilhadas com legenda pontilhada por cor `spectrumColors`.
- **Uso do disco** (`DiskUsageLine`): "Macintosh HD · total · livre" com barra de preenchimento; acima de 90% o traço muda para vermelho→magenta.
- **Sugestão automática** (`SuggestedTag`): pré-seleção ao abrir — Lixo do Sistema marca itens removíveis ≥ 128 MB; Arquivos Grandes marca ≥ 300 MB.
- **Selecionar tudo ↔ Deselecionar tudo** (`SelectAllToggle`): botão alterna o rótulo conforme o estado da seleção.
- Mini-barra de participação de volume nas rows de Lixo/Arquivos Grandes.

## v1.3 — mapa, aceleração e sistema

- **Treemap squarified** (`TreemapView` + `Engine.squarify`): substituiu a órbita de bolhas em "Meu Espaço" — áreas proporcionais sem sobreposição, cores cíclicas e clique = drill-down.
- **Acelerar** (`AccelView`): barra de memória, `purge` de caches de disco e apps ≥ 100 MB com encerramento normal (sugestões ≥ 600 MB pré-marcadas; processos de sistema travados).
- **Sistema** (`SystemView`): StatCards de CPU/memória/térmico (`machdep.xcpm.*_thermal_level`) e disco + **Top memória** por processo (parser do `top -l 2`), auto-refresh de 6 s.
- **Cuidado Inteligente em modo "aplicação única"**: varreduras paralelas (`Task.detached`×4), sugestões listadas na própria tela e botão **Aplicar limpeza** (mover para Lixeira + opção de esvaziar).
