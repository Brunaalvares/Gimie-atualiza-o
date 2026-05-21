#!/bin/bash
# ============================================================
# Script de Exportação — Gimie App Store
# Execute com: bash scripts/exportar_app_store.sh
# ============================================================

set -e

# Apple Developer Team ID (sobrescreva com: TEAM_ID=... bash scripts/exportar_app_store.sh)
TEAM_ID="${TEAM_ID:-55RTDLA93V}"

FLUTTER="/Users/brunaalvares/Downloads/flutter 2/bin/flutter"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IOS_DIR="$PROJECT_DIR/ios"
OUTPUT_DIR="$PROJECT_DIR/build/ios_export"
ARCHIVE_PATH="$OUTPUT_DIR/Gimie.xcarchive"
WORKSPACE="$IOS_DIR/Runner.xcworkspace"

echo ""
echo "============================================"
echo "  Gimie — Exportação para App Store"
echo "============================================"
echo ""

# ── Passo 1: Verificar pré-requisitos ────────────────────────
echo "▶ Verificando pré-requisitos..."

if ! command -v pod &> /dev/null; then
    echo ""
    echo "❌ CocoaPods não encontrado."
    echo "   Instale com: sudo gem install cocoapods"
    echo "   Depois execute este script novamente."
    exit 1
fi

if ! xcodebuild -version &> /dev/null; then
    echo "❌ Xcode não encontrado. Instale pelo App Store."
    exit 1
fi

echo "✅ Xcode $(xcodebuild -version | head -1)"
echo "✅ CocoaPods $(pod --version)"

# ── Passo 2: Flutter clean + pub get ─────────────────────────
echo ""
echo "▶ Limpando projeto Flutter..."
cd "$PROJECT_DIR"
"$FLUTTER" clean
"$FLUTTER" pub get
echo "✅ Dependências atualizadas"

# ── Passo 3: Pod install ──────────────────────────────────────
echo ""
echo "▶ Instalando pods iOS..."
cd "$IOS_DIR"
pod install --repo-update
echo "✅ Pods instalados"

# ── Passo 4: Criar pasta de output ───────────────────────────
mkdir -p "$OUTPUT_DIR"

# ── Passo 5: Archive ──────────────────────────────────────────
echo ""
echo "▶ Gerando Archive (isso pode levar alguns minutos)..."
cd "$PROJECT_DIR"

xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme Runner \
  -configuration Release \
  -sdk iphoneos \
  -archivePath "$ARCHIVE_PATH" \
  clean archive \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  | xcpretty 2>/dev/null || true

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo ""
    echo "❌ Archive falhou."
    echo "   Abra o Xcode e use: Product → Archive"
    echo "   Workspace: $WORKSPACE"
    exit 1
fi

echo "✅ Archive gerado em: $ARCHIVE_PATH"

# ── Passo 6: Export IPA ───────────────────────────────────────
echo ""
echo "▶ Exportando IPA..."

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$OUTPUT_DIR" \
  -exportOptionsPlist "$IOS_DIR/ExportOptions.plist" \
  | xcpretty 2>/dev/null || true

IPA_FILE=$(find "$OUTPUT_DIR" -name "*.ipa" | head -1)

if [ -z "$IPA_FILE" ]; then
    echo ""
    echo "❌ Exportação falhou."
    echo "   Use o Xcode manualmente: Product → Archive → Distribute App"
    exit 1
fi

echo ""
echo "============================================"
echo "  ✅ IPA gerado com sucesso!"
echo "  📦 $IPA_FILE"
echo "============================================"
echo ""
echo "Próximos passos:"
echo "  1. Abra o Transporter (App Store) ou use:"
echo "     xcrun altool --upload-app -f \"$IPA_FILE\" -t ios -u SEU_EMAIL_APPLE"
echo "  2. Ou arraste o .ipa para o Transporter"
echo "  3. Acesse appstoreconnect.apple.com para finalizar"
echo ""
