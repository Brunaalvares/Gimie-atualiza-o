#!/bin/bash

# Script para preparar o app Gimie para App Store
# Execute: chmod +x scripts/prepare_app_store.sh && ./scripts/prepare_app_store.sh

set -e

echo "🚀 Preparando Gimie para App Store..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para print colorido
print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar se estamos no diretório correto
if [ ! -f "pubspec.yaml" ]; then
    print_error "Execute este script no diretório raiz do projeto Flutter"
    exit 1
fi

print_step "Verificando ambiente Flutter..."

# Verificar Flutter
if ! command -v flutter &> /dev/null; then
    print_error "Flutter não está instalado ou não está no PATH"
    exit 1
fi

# Verificar Xcode
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode não está instalado"
    exit 1
fi

print_success "Ambiente verificado"

# Limpar projeto
print_step "Limpando projeto..."
flutter clean
print_success "Projeto limpo"

# Instalar dependências
print_step "Instalando dependências Flutter..."
flutter pub get
print_success "Dependências Flutter instaladas"

# Instalar pods
print_step "Instalando CocoaPods..."
cd ios
if [ -f "Podfile.lock" ]; then
    rm Podfile.lock
fi
pod install
cd ..
print_success "CocoaPods instalados"

# Verificar doctor
print_step "Executando Flutter Doctor..."
flutter doctor

# Verificar se há problemas críticos
if flutter doctor | grep -q "✗"; then
    print_warning "Flutter Doctor encontrou problemas. Verifique antes de continuar."
else
    print_success "Flutter Doctor OK"
fi

# Criar workspace se não existir
if [ ! -f "ios/Runner.xcworkspace/contents.xcworkspacedata" ]; then
    print_error "Workspace não encontrado. Execute 'pod install' no diretório ios/"
    exit 1
fi

# Verificar configurações importantes
print_step "Verificando configurações..."

# Verificar Bundle ID no pubspec
BUNDLE_ID=$(grep -A 5 "flutter_launcher_icons:" pubspec.yaml | grep "bundle_id:" | cut -d'"' -f2 || echo "")
if [ -z "$BUNDLE_ID" ]; then
    print_warning "Bundle ID não encontrado no pubspec.yaml"
fi

# Verificar versão
VERSION=$(grep "version:" pubspec.yaml | cut -d' ' -f2)
print_success "Versão atual: $VERSION"

# Verificar ícones
if [ ! -d "assets/images" ]; then
    print_warning "Diretório assets/images não encontrado"
else
    print_success "Assets encontrados"
fi

# Build de teste
print_step "Executando build de teste..."
if flutter build ios --release --no-codesign; then
    print_success "Build de teste bem-sucedido"
else
    print_error "Build de teste falhou"
    exit 1
fi

# Verificar arquivos importantes
print_step "Verificando arquivos importantes..."

IMPORTANT_FILES=(
    "ios/Runner/Info.plist"
    "ios/ShareExtension/Info.plist"
    "ios/ShareExtension/ShareViewController.swift"
    "ios/Runner/AppDelegate.swift"
    "lib/services/share_service.dart"
)

for file in "${IMPORTANT_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "✓ $file"
    else
        print_error "✗ $file não encontrado"
    fi
done

# Instruções finais
echo ""
echo "🎉 Preparação concluída!"
echo ""
echo "📋 Próximos passos:"
echo "1. Abra o Xcode: open ios/Runner.xcworkspace"
echo "2. Configure Bundle IDs únicos"
echo "3. Configure certificados e provisioning profiles"
echo "4. Configure App Groups"
echo "5. Execute Product > Archive"
echo ""
echo "📖 Consulte APP_STORE_EXPORT_GUIDE.md para instruções detalhadas"
echo "🚀 Nova API Gimie 2.0 conectada: https://api2gimie.vercel.app"
echo ""

# Verificar se workspace pode ser aberto
if command -v open &> /dev/null; then
    read -p "Deseja abrir o Xcode agora? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "Abrindo Xcode..."
        open ios/Runner.xcworkspace
        print_success "Xcode aberto"
    fi
fi

print_success "Script concluído com sucesso!"