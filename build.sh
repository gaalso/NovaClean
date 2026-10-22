#!/bin/zsh
# Build do NovaClean — compila com swiftc (Command Line Tools, sem Xcode),
# monta o bundle .app e assina ad-hoc.
#
# Uso: ./build.sh [intel|silicon|universal]   (default: universal)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/src/NovaCleanApp.swift"
PLIST="$ROOT/src/Info.plist"
APP="$ROOT/build/NovaClean.app"
MODE="${1:-universal}"

SDK_PATH="$(xcrun --show-sdk-path)"
echo "SDK: $SDK_PATH"
echo "swiftc: $(swiftc --version | head -1)"

build_for() {
  local target="$1" out="$2"
  echo "→ compilando $target"
  swiftc \
    -parse-as-library \
    -sdk "$SDK_PATH" \
    -target "$target" \
    -O \
    -o "$out" \
    "$SRC"
}

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$PLIST" "$APP/Contents/Info.plist"
cp "$ROOT/src/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

BIN="$APP/Contents/MacOS/NovaClean"

case "$MODE" in
  intel)
    build_for x86_64-apple-macos12.0 "$BIN"
    ;;
  silicon)
    build_for arm64-apple-macos12.0 "$BIN"
    ;;
  universal)
    build_for x86_64-apple-macos12.0 "$ROOT/build/nova_x86_64"
    build_for arm64-apple-macos12.0 "$ROOT/build/nova_arm64"
    lipo -create "$ROOT/build/nova_x86_64" "$ROOT/build/nova_arm64" -output "$BIN"
    rm -f "$ROOT/build/nova_x86_64" "$ROOT/build/nova_arm64"
    ;;
  *)
    echo "uso: ./build.sh [intel|silicon|universal]" >&2
    exit 2
    ;;
esac

if codesign --force --sign - "$APP" >/dev/null 2>&1; then
  echo "Assinado ad-hoc: OK"
fi

echo "Arquitetura(s): $(lipo -info "$BIN" | sed 's/^.*: //')"
echo "Build em: $APP"
ls -la "$APP/Contents/MacOS"
