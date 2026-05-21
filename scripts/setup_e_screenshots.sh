#!/bin/bash
# ============================================================
# Execute este script no Terminal do seu Mac:
# bash scripts/setup_e_screenshots.sh
# ============================================================

set -e

FLUTTER="/Users/brunaalvares/Downloads/flutter 2/bin/flutter"
PROJECT_DIR="/Users/brunaalvares/Documents/Gimie atualiza-o/Gimie-atualiza-o-1"
SCREENSHOTS_DIR="$PROJECT_DIR/screenshots/app_store"

# IDs dos simuladores
SIM_67="64DD6831-B33C-4AEB-BA08-201B0208DB04"  # iPhone 16 Pro Max (6.7")
SIM_55="DBD14AE4-8857-4F5F-8F67-6CB70B903B31"  # iPhone 16e (5.5" equiv)
SIM_65="34CD27C3-8C2E-4BD1-84D7-3F0384EC5798"  # iPhone 16 Pro (6.1")

echo ""
echo "=========================================="
echo "  Gimie — Setup + Screenshots App Store"
echo "=========================================="

# ── Passo 1: Homebrew ────────────────────────────────────────
if ! command -v brew &>/dev/null; then
    echo ""
    echo "▶ Instalando Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || \
    eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null
fi
echo "✅ Homebrew: $(brew --version | head -1)"

# ── Passo 2: CocoaPods ────────────────────────────────────────
if ! command -v pod &>/dev/null; then
    echo ""
    echo "▶ Instalando CocoaPods..."
    brew install cocoapods
fi
echo "✅ CocoaPods: $(pod --version)"

# ── Passo 3: Flutter pub get + pod install ───────────────────
echo ""
echo "▶ Preparando projeto Flutter..."
cd "$PROJECT_DIR"
"$FLUTTER" pub get

cd "$PROJECT_DIR/ios"
pod install --repo-update
cd "$PROJECT_DIR"
echo "✅ Pods instalados"

# ── Passo 4: Ligar simuladores ────────────────────────────────
echo ""
echo "▶ Iniciando simuladores..."
open -a Simulator

xcrun simctl boot "$SIM_67" 2>/dev/null || true
xcrun simctl boot "$SIM_65" 2>/dev/null || true
sleep 5
echo "✅ Simuladores prontos"

# ── Passo 5: Build para simulador ────────────────────────────
echo ""
echo "▶ Compilando app para simulador..."
"$FLUTTER" build ios --simulator --no-codesign
echo "✅ Build concluído"

# ── Passo 6: Instalar app nos simuladores ─────────────────────
APP_PATH=$(find "$PROJECT_DIR/build/ios/iphonesimulator" -name "*.app" | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ .app não encontrado. Verifique a build."
    exit 1
fi

echo ""
echo "▶ Instalando app nos simuladores..."
xcrun simctl install "$SIM_67" "$APP_PATH"
xcrun simctl install "$SIM_65" "$APP_PATH"
echo "✅ App instalado"

# ── Passo 7: Lançar app e tirar screenshots ───────────────────
mkdir -p "$SCREENSHOTS_DIR/67inch"
mkdir -p "$SCREENSHOTS_DIR/55inch"

BUNDLE_ID="com.gimie.app"

echo ""
echo "▶ Capturando screenshots — iPhone 16 Pro Max (6.7\")..."
xcrun simctl launch "$SIM_67" "$BUNDLE_ID"
sleep 4

# Screenshot 1 — Tela inicial (Splash)
xcrun simctl io "$SIM_67" screenshot "$SCREENSHOTS_DIR/67inch/01_splash.png"
echo "  📸 01_splash.png"
sleep 2

# Screenshot 2 — Login
xcrun simctl io "$SIM_67" screenshot "$SCREENSHOTS_DIR/67inch/02_login.png"
echo "  📸 02_login.png"
sleep 2

# Screenshot 3 — Home (aguarda navegar manualmente se necessário)
xcrun simctl io "$SIM_67" screenshot "$SCREENSHOTS_DIR/67inch/03_home.png"
echo "  📸 03_home.png"

echo ""
echo "▶ Capturando screenshots — iPhone 16e (5.5\")..."
xcrun simctl launch "$SIM_65" "$BUNDLE_ID"
sleep 4
xcrun simctl io "$SIM_65" screenshot "$SCREENSHOTS_DIR/55inch/01_splash.png"
xcrun simctl io "$SIM_65" screenshot "$SCREENSHOTS_DIR/55inch/02_login.png"
echo "  📸 Screenshots 5.5\" capturados"

# ── Resultado ─────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  ✅ Screenshots salvos em:"
echo "  $SCREENSHOTS_DIR"
echo ""
echo "  Tamanhos exigidos pela App Store:"
echo "  • 6.7\" (iPhone 16 Pro Max) → 1320×2868"
echo "  • 5.5\" (iPhone 8 Plus)     → 1242×2208"
echo ""
echo "  Próximo passo:"
echo "  Faça upload em appstoreconnect.apple.com"
echo "=========================================="
