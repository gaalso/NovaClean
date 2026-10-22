# Publicando o NovaClean no GitHub (com .dmg instaláveis)

## 1) Arquivos de distribuição (já gerados)

```
dist/NovaClean-1.3.0-mac-Universal.dmg       ← RECOMENDADO: Intel + Apple Silicon num só arquivo
dist/NovaClean-1.3.0-mac-Intel.dmg           ← só Intel (x86_64), menor
dist/NovaClean-1.3.0-mac-AppleSilicon.dmg    ← só M1/M2/M3 (arm64, nativo)
dist/NovaClean-1.3.0-mac-*.zip               ← alternativas em zip (uma por arquitetura)
```

- **Requisito**: macOS 12+ nas três variantes (`lipo -info` confirma x86_64 + arm64 na Universal).
- A Universal roda nativo nos dois lados (o macOS escolhe a slice automaticamente).
- Assinatura **ad-hoc** (sem certificado Apple Developer) — aviso do Gatekeeper na primeira abertura; ver a seção 4.

> **Nota sobre o `.gitignore`**: é um arquivo oculto (começa com ponto). No Finder ative `Cmd+Shift+.` para vê-lo; no terminal, `ls -la ~/NovaClean`. Ele evita que `build/`, `dist/` e binários locais vazem para o repositório GitHub.

## 2) Publicar via interface web (sem instalar nada)

1. Acesse **github.com** e, se não tiver conta, crie uma.
2. Botão **`+` → New repository**:
   - Repository name: `nova-clean`
   - Visibilidade: **Public** (ou Private — releases funcionam igual)
   - **Não** marque "Add a README" (vamos subir o que já temos)
   - Clique **Create repository**.
3. Na página do repositório vazio, clique **"uploading an existing file"** (ou *Add file → Upload files*).
4. Arraste os arquivos do projeto (**exceto** `build/`, `dist/`, `tools/gen_icon` — o `.gitignore` já indica):
   - `src/NovaCleanApp.swift`, `src/Info.plist`, `src/AppIcon.icns`
   - `tools/gen_icon.swift`, `build.sh`
   - `README.md`, `IDENTITY.md`, `blueprint-REA.md`, `GITHUB.md`, `.gitignore`
5. Mensagem: `NovaClean v1.3.0 — fonte, identidade e build` → **Commit changes**.
6. Criar o **Release** (é daí que as pessoas baixam o DMG, no lado direito da página do repo):
   - **Releases → Draft a new release**
   - **Choose a tag** → digite `v1.3.0` → *Create new tag on publish*
   - Release title: `NovaClean 1.3.0 (Intel + Apple Silicon)`
   - Description:
     ```md
     NovaClean 1.3.0 — macOS 12+

     - Cuidado Inteligente: análise paralela + aplicação em um clique
     - Treemap do espaço em disco (clique = drill-down)
     - Acelerar: encerra apps pesados e libera caches
     - Sistema: CPU/RAM/térmico/disco e top processos

     Downloads:
     - `NovaClean-1.3.0-mac-Universal.dmg` — recomendado (Intel + Apple Silicon num arquivo)
     - `NovaClean-1.3.0-mac-Intel.dmg` — Macs Intel
     - `NovaClean-1.3.0-mac-AppleSilicon.dmg` — Macs M1/M2/M3 (nativo)

     Instalação: abra o DMG e arraste o NovaClean para Applications.
     Primeira abertura: botão direito no app → Abrir (veja instruções abaixo).
     ```
   - Arraste os **4 arquivos** da pasta `dist/` para a área **"Attach binaries by dropping them here"**.
   - Clique **Publish release**.
7. Pronto — o link de download fica `https://github.com/SEU-USUARIO/nova-clean/releases`.

## 3) Publicar via linha de comando (opcional)

Se preferir terminal (requer `git`):

```sh
cd ~/NovaClean
git init
git add .                 # .gitignore já pula build/ e dist/
git commit -m "NovaClean v1.3.0"

# crie o repositório vazio 'nova-clean' no github.com (opção A, passo 2)
git remote add origin https://github.com/SEU-USUARIO/nova-clean.git
git branch -M main
git push -u origin main
```

Para autenticar o push, o GitHub pede **username + Personal Access Token** (não a senha):
GitHub → Settings → Developer settings → **Personal access tokens (classic)** → Generate (escopo `repo`) — cole como senha no push. (O `gh auth login` do GitHub CLI automatiza isso: `brew install gh`.)

Criar o release pelo terminal (opcional, após instalar o `gh`):

```sh
gh auth login
gh release create v1.3.0 dist/*.dmg dist/*.zip \
  --title "NovaClean 1.3.0 (Intel + Apple Silicon)" \
  --notes "macOS 12+. Abra o DMG e arraste para Applications."
```

## 4) Aviso do Gatekeeper para quem for instalar

Como o app está assinado ad-hoc (sem notarização da Apple), o macOS bloqueia o **primeiro** abrir. Basta uma destas opções:

- **Botão direito no `NovaClean.app` → Abrir → Abrir** (recomendado; só a primeira vez).
- macOS 12: **Preferências do Sistema → Segurança e Privacidade → Geral** → "NovaClean foi bloqueado…" → **Abrir Mesmo Assim**.
- Ou, no terminal: `xattr -dr com.apple.quarantine NovaClean.app` (remove a marca de "baixado da internet").

Depois disso abre normalmente. Se um dia você obtiver um **Apple Developer ID** (US$99/ano), assine + notarize o app e esse aviso desaparece.

## 5) Rebuild local (e gerar os DMGs)

```sh
cd ~/NovaClean
./build.sh                     # universal (Intel + Apple Silicon) — padrão
./build.sh intel               # só x86_64
./build.sh silicon             # só arm64 (Apple Silicon)
open build/NovaClean.app

# DMG de qualquer arquitetura já compilada:
rm -rf dist/staging && mkdir -p dist/staging \
  && cp -R build/NovaClean.app dist/staging/ \
  && ln -s /Applications dist/staging/Applications \
  && hdiutil create -volname "NovaClean" -srcfolder dist/staging -ov -format UDZO dist/NovaClean-1.3.0-mac-Intel.dmg
# (troque o nome do .dmg para -mac-AppleSilicon se o build atual for `silicon`)
```

Nota: o binário arm64 é gerado por *cross-compile* nesta máquina Intel — o artefato é verificado com `lipo -info`/`codesign`, mas teste-o também num Mac Apple Silicon antes de divulgar o release.
