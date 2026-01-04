#!/bin/bash

# Gimie Build Script
# Script para automatizar builds de produção

set -e

echo "🚀 Gimie Build Script"
echo "====================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
success() {
    echo -e "${GREEN}✓ $1${NC}"
}

error() {
    echo -e "${RED}✗ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check Flutter
if ! command -v flutter &> /dev/null; then
    error "Flutter não encontrado. Instale o Flutter primeiro."
    exit 1
fi

# Clean
echo "🧹 Limpando projeto..."
flutter clean
success "Projeto limpo"

# Get dependencies
echo "📦 Instalando dependências..."
flutter pub get
success "Dependências instaladas"

# Analyze
echo "🔍 Analisando código..."
flutter analyze
success "Análise completa"

# Menu
echo ""
echo "Escolha o tipo de build:"
echo "1) Android APK"
echo "2) Android App Bundle (AAB)"
echo "3) iOS"
echo "4) Todos"
echo "5) Sair"
echo ""
read -p "Opção: " choice

case $choice in
    1)
        echo "📱 Buildando Android APK..."
        flutter build apk --release
        success "APK criado em: build/app/outputs/flutter-apk/app-release.apk"
        ;;
    2)
        echo "📱 Buildando Android App Bundle..."
        flutter build appbundle --release
        success "AAB criado em: build/app/outputs/bundle/release/app-release.aab"
        ;;
    3)
        echo "🍎 Buildando iOS..."
        flutter build ios --release
        success "Build iOS completo"
        warning "Abra o Xcode para arquivar: open ios/Runner.xcworkspace"
        ;;
    4)
        echo "📱 Buildando Android APK..."
        flutter build apk --release
        success "APK criado"
        
        echo "📱 Buildando Android App Bundle..."
        flutter build appbundle --release
        success "AAB criado"
        
        echo "🍎 Buildando iOS..."
        flutter build ios --release
        success "iOS buildado"
        
        echo ""
        success "Todos os builds completos!"
        ;;
    5)
        echo "👋 Saindo..."
        exit 0
        ;;
    *)
        error "Opção inválida"
        exit 1
        ;;
esac

echo ""
echo "✨ Build concluído com sucesso!"
echo ""
echo "📋 Próximos passos:"
echo "- Para Android: Upload do AAB na Play Store"
echo "- Para iOS: Archive no Xcode e upload na App Store"
echo ""
