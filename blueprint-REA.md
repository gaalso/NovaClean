# Blueprint REA — CleanMyMac 5.7.2 (MAS) → NovaClean

Documento gerado a partir de **evidências coletadas via REA** sobre `/Applications/CleanMyMac_5_MAS.app`, na máquina do usuário, como insumo para a recriação (`NovaClean`, em `~/NovaClean`).

---

## 1. Identidade do alvo (evidência REA)

| Fator | Valor observado |
|---|---|
| Caminho | `/Applications/CleanMyMac_5_MAS.app` |
| Info.plist (`ev_0e2f72c8…`) | `com.macpaw.CleanMyMac-mas`, versão `5.7.2` (build `50702.0.2610141000`) |
| Palesta de compilação (regime dev) | Xcode 2660 (17F113), SDK macOS 26.5, LLVM clang |
| Copyright | "Copyright © 2026 MacPaw Way Ltd. All rights reserved." |
| Executável | `Contents/MacOS/CleanMyMac_5_MAS` — Mach-O **universal** (`ev_d6d4ccf9…`, `format "Mach-O universal (x86_64 arm64)"`), SHA-256 `2fa527e9…cafa343cc`; fatia x86_64 ~6,9 MB + arm64 ~6,7 MB |
| Arquiteturas | x86_64 (offset 16384), arm64 (offset 6930432) — `total: 2, exhaustive: true` |
| OS mínimo | macOS 11.0 (`LSMinimumSystemVersion`) |
| Category | `public.app-category.utilities` |
| URL schemes | `cleanmymac5`, `cleanmymac5-mas` (ativação) + `db-hfn3qmlc7uq9kxd` (Dropbox) |
| Keychain | grupo `S8EX82NJP6.com.macpaw.CleanMyMac-mas` |

## 2. Assinatura e sandbox (evidência `ev_d6d4ccf9…`)

Assinatura **de distribuição pela Mac App Store** ("Apple Mac OS Application Signing"), time `S8EX82NJP6` (MacPaw), **hardened runtime: true** e **app-sandbox: true**, com entitlements:

- `com.apple.security.files.user-selected.read-write` + `files.bookmarks.app-scope`
- `com.apple.security.network.client` / `network.server`
- `com.apple.security.personal-information.photos-library`
- Application groups: `…CleanMyMac-mas`, `…CleanMyMac5.CLI` → existe um **CLI companion** fora do sandbox que executa ações privilegiadas em nome do app sandboxado
- Keychain extra: `S8EX82NJP6.com.macpaw.moonlock-mas` e `.interoperability` → integração com o motor **Moonlock** (antimalware da MacPaw)

Implicação para a recriação: no MAS, tudo que exige escrita ampla é delegado ao CLI/privilege helper; uma recriação *não sandboxada* dispensa esse nó inteiro (NovaClean não usa sandbox nem helpers).

## 3. Saídas no bundle

- `Contents/Frameworks` (~100 MB): **~140 frameworks** — a lógica real vive neles; o executável principal é só o casco.
- `Contents/Library/LoginItems`: dois apps ancilares
  - `CleanMyMac_5_MAS_HealthMonitor.app` (`…CleanMyMac-mas.HealthMonitor`) — monitor de saúde em background (inclui `MalwareNotification.m4a`)
  - `CleanMyMac_5_MAS_Menu.app` (`…CleanMyMac-mas.Menu`) — app de barra de menus/Assistant
- `Contents/Resources`: `Assets.car` (4,2 MB), `Features_*.bundle` (IntroFlow, PurchaseFlow, EmailSubscription, RealTimeProtection, Settings, CarouselFlow, KeepMenuOpen, FDAResolutionUIKit), `info.cmmkb`/`userInfo.cmmkb` (bases de knowledge base locais), 15 idiomas (`pt-BR` incluso), `license_plan`, CMMError.wav
- Terceiras partes incorporadas (bundles): AppAuth, GTMAppAuth, GTMSessionFetcher, GoogleAPIClientForREST, SwiftProtobuf, SwiftyDropbox, GRDB, SnapKit, Kingfisher, CocoaLumberjack, Sparkle, RiveRuntime, MSAL (Microsoft), CombineExt/CombineSchedulers

## 4. Mapa de módulos (extraído do framework inventory + strings localizadas em `en.lproj`)

**Lista lateral observada no app** (chaves `menu_item_view_*`): *Assistant, My Clutter, Space Lens, Cloud Cleanup, Performance, Cleanup (junkCleanup), Protection, Smart Care*.

### Módulos de feature (UI + scanning em pares)
| Framework | Papel | Evidências de strings |
|---|---|---|
| **SmartCareModule** | "Smart Care" — scan composto | `intro_screen_title => Smart Care`; agregados: `Vital Updates`, `Duplicate Downloads`, `%@ of large files`, `Real-Time Protection by Moonlock`, log `Smart Care Log` |
| **JunkCleanupModule** + SystemJunk/MailJunk/TrashJunk/DownloadsScanning | "Cleanup" | `intro_screen_title => Junk Cleanup`; grupos: System Junk, Xcode Caches, Mail Attachments/Downloads, Document Versions, AI Junk Files (`ai_clutter_agents_junk_group_title`), Universal Binaries, Deleted User Accounts |
| **ApplicationsModule** + Uninstaller/UpdaterScanning | "Applications" | `intro_screen_title => Applications`; Updater, Installers/Unused DMG Files, App Leftovers, Unused Applications |
| **OrganizeModule** | "My Clutter" | `intro_screen_title => My Clutter`; Large&Old Files, Duplicate Finder, Similar Photos ("Visual Flaws"), Downloads |
| **SpaceLensModule/Scanning/UI** | "Space Lens" | `module_name => Space Lens`; visualização de armazenamento, `Clean Purgeable Space` |
| **ProtectionModule** + MalwareScanning/Moonlock* | "Protection" | Malware Removal (by Moonlock), Privacy (history de Safari/Chrome/Firefox), Vulnerabilities, Application Permissions (Input Monitoring etc.), cross-promo Moonlock |
| **PerformanceModule** + PerformanceScanning/Service | "Performance" | Free Up RAM, Login Items/Background Items, Maintenance Tasks, Thin Time Machine Snapshot, purgeable space |
| **EmailCleanupModule** + Mailbox/Gmail services | "Email Cleanup" | Conexão Gmail, Unsubscribe, Scan, "moved to trash/archive" |
| **CloudStorage*** | "Cloud Cleanup" | iCloud Drive, Dropbox, Google Drive, OneDrive; "Review cloud files and unsync" |
| **ToolboxModule** | "My Tools" | `module_name => My Tools`; "Browser Care" (tabs do Chrome, CPU/mem por tab) |
| **AssistantModule** + AssistantCore/UI | "Assistant" (painel/dashboard IA) | `Mac Health:`, recommendations dashboard |
| **StatisticsDashboard(UI)/StatisticsService** | dashboards de contagem histórico | — |
| **ScreenCleaningMode, TerminatorUI, LegacyUI, MainAppUI, NavigationUI, SettingsUI, DataManagerUI, SharedUI, DesignSystem** | camada de UI compartilhada | — |

### Camada de infraestrutura
- **ScanningCore / LegacyScanningCore / LegacyScanningWrapperCore** — motor de varredura (Heritage + novo)
- **PrivilegedOperationsPerformerService / PrivilegedRoutines** — ações que precisam de privilégio (equivalente interno do CLI companion)
- **IPCProtocol** — protocolo de XPC com os apps de LoginItems/CLI
- **CleanMyLiveBackground, CleanMyMacLoginItems, CleanMyMacNFRService** — background/NFR (novas releases)
- **ActivationService, MASUpdaterServiceAPI, RemotePreferences, PreferencesStorage.SharedPreferences** — ativação/licença e preferências remotas
- **AnalyticsService, StatisticsService, RateFlow** — telemetria/avaliação
- **HealthMonitoring{API,Core,Reports}** — monitor de saúde contínuo (o app HealthMonitor separado)
- **PANEngine / PantherEngineService** — bem inconsistente nas strings: engine de malware/privacidade Moonlock
- **AIToolScanning, LocalModelScanning, TipsServiceAI** — recursos de IA local (Novidades 5.x)
- **Services de contas**: GmailService, GoogleDriveService, AppAuth/GTMSessionFetcher, DropboxService (SwiftyDropbox), MicrosoftService (MSAL), GoogleAppAuthService

## 5. Notas de engenharia observadas

- Arquitetura em camadas **módulo → scanning → service** fortemente fatorada (o espelhamento `XModule/XScanning/XService` aparece sistematicamente).
- ~15 idiomas; strings-driven UI (os títulos de módulos aparecem como chaves e não hardcoded).
- O executável de 13 MB both-arquiteturas confirma que o app é virtualmente todo "framework-as-module".
- O par `Menu.app` + `HealthMonitor.app` roda fora da janela principal — recriação de paridade completa incluiria um menu bar app e um agente de background.

## 6. Como o NovaClean mapeia (e o que não mapeia)

| CleanMyMac real | NovaClean 1.0 |
|---|---|
| Smart Care (composto) | **Cuidado Inteligente** — orquestra 4 scans e resume |
| Junk Cleanup (System/Mail/Trash/Downloads/Xcode/AI groups) | **Lixo do Sistema** — ~/Library/Caches removível→Lixeira + /Library/Caches informativo |
| My Clutter / Large & Old | **Arquivos Grandes** (≥50 MB, 6 pastas do usuário) |
| Space Lens | **Meu Espaço** — breakdown por 1º nível com 1 passe profundo + drill-down + destaques ≥100 MB |
| Applications (Uninstaller/Updater/Leftovers) | **Aplicativos** — inventário com versão/tamanho; uninstall = move para a Lixeira |
| Performance, Protection/Moonlock, Email Cleanup, Cloud Cleanup, Assistant/AI, Toolbox/Browser Care, HealthMonitor, Menu bar | **Não recriados** nesta versão (ver §7) |

### Fora do escopo da recriação (por design)
- **Remoção real de malware/antivírus** (Moonlock/PANEngine) e monitoramento contínuo.
- **Leftovers de desinstalação** (plists, launch agents, preferências) — o NovaClean move só o .app.
- **Integrações de contas** (Gmail/Dropbox/GoogleDrive/OneDrive/MSAL) — exigiriam OAuth e third-party SDKs próprios.
- **Ativação/licenciamento, telemetria, compras no app, sub/store flows** — não faz sentido replicar.
- **Assistente IA local**, Browser Care, e o app de menu bar.

## 7. Estado da análise profunda (Hopper/Ghidra)

Durante a sessão, o REA selecionou **Hopper automaticamente** para o executável principal conforme a primeira abertura; o bridge estourou o timeout de startup (`REA_HOPPER_STARTUP_TIMEOUT_MS` e diálogo de licença), deixando **cleanup retido** (`cleanup_pending`), o que bloqueia novas aberturas até `close_binary` autenticar. A análise nativa de *deep disassembly* (Ghidra) ficou pendente: Ghidra exige fatia fina (`lipo -thin x86_64` já produzida em `/private/var/folders/_t/t5254hfd31q_ll5c0r36tlmc0000gn/T/opencode/rea-thin/`). Com o Hopper fechado manualmente, o `close_binary` conclude e o `open_binary(provider_id: ghidra)` na fatia fina habilita `binary_overview`/`list_strings`/`analyze_function` para complemento deste blueprint.

Todas as demais evidências (§1–5) são nativas/estáticas e suficientes para o desenho do NovaClean.
