#!/bin/bash

# Script avançado para build e export do Gimie para App Store
# Execute: chmod +x scripts/build_and_export.sh && ./scripts/build_and_export.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Configurações
SCHEME="Runner"
WORKSPACE="ios/Runner.xcworkspace"
CONFIGURATION="Release"
ARCHIVE_PATH="build/ios/Runner.xcarchive"
EXPORT_PATH="build/ios/ipa"
EXPORT_OPTIONS="ios/ExportOptions.plist"

echo "🚀 Build e Export do Gimie para App Store"
echo "=========================================="

# Verificar se estamos no diretório correto
if [ ! -f "pubspec.yaml" ]; then
    print_error "Execute este script no diretório raiz do projeto Flutter"
    exit 1
fi

# Verificar se workspace existe
if [ ! -f "$WORKSPACE/contents.xcworkspacedata" ]; then
    print_error "Workspace não encontrado. Execute 'pod install' primeiro."
    exit 1
fi

# Verificar ExportOptions.plist
if [ ! -f "$EXPORT_OPTIONS" ]; then
    print_error "ExportOptions.plist não encontrado. Configure primeiro."
    exit 1
fi

# Limpar builds anteriores
print_step "Limpando builds anteriores..."
if [ -d "build" ]; then
    rm -rf build
fi
mkdir -p build/ios
print_success "Builds anteriores limpos"

# Preparar projeto
print_step "Preparando projeto Flutter..."
flutter clean
flutter pub get
print_success "Projeto Flutter preparado"

# Instalar pods
print_step "Instalando CocoaPods..."
cd ios
pod install
cd ..
print_success "CocoaPods instalados"

# Build Flutter
print_step "Executando build Flutter para iOS..."
flutter build ios --release
print_success "Build Flutter concluído"

# Archive com xcodebuild
print_step "Criando archive..."
xcodebuild \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    archive

if [ $? -eq 0 ]; then
    print_success "Archive criado com sucesso"
else
    print_error "Falha ao criar archive"
    exit 1
fi

# Verificar se archive foi criado
if [ ! -d "$ARCHIVE_PATH" ]; then
    print_error "Archive não foi encontrado em $ARCHIVE_PATH"
    exit 1
fi

# Export para App Store
print_step "Exportando para App Store..."
xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS"

if [ $? -eq 0 ]; then
    print_success "Export concluído com sucesso"
else
    print_error "Falha no export"
    exit 1
fi

# Verificar IPA gerado
IPA_FILE=$(find "$EXPORT_PATH" -name "*.ipa" | head -1)
if [ -f "$IPA_FILE" ]; then
    print_success "IPA gerado: $IPA_FILE"
    
    # Mostrar informações do IPA
    IPA_SIZE=$(du -h "$IPA_FILE" | cut -f1)
    print_success "Tamanho do IPA: $IPA_SIZE"
else
    print_error "IPA não foi encontrado"
    exit 1
fi

# Upload para App Store (opcional)
read -p "Deseja fazer upload para App Store Connect? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Fazendo upload para App Store Connect..."
    
    # Verificar se altool está disponível (Xcode antigo) ou xcrun altool
    if command -v xcrun &> /dev/null; then
        xcrun altool --upload-app \
            --type ios \
            --file "$IPA_FILE" \
            --username "YOUR_APPLE_ID" \
            --password "YOUR_APP_SPECIFIC_PASSWORD"
    else
        print_warning "xcrun altool não encontrado. Use Xcode Organizer para upload manual."
    fi
fi

# Resumo final
echo ""
echo "🎉 Build e Export Concluídos!"
echo "=============================="
echo "📁 Archive: $ARCHIVE_PATH"
echo "📱 IPA: $IPA_FILE"
echo "📊 Tamanho: $IPA_SIZE"
echo ""
echo "📋 Próximos passos:"
echo "1. Abra Xcode Organizer para validar"
echo "2. Faça upload para App Store Connect"
echo "3. Configure metadata no App Store Connect"
echo "4. Submeta para review"
echo ""

print_success "Script concluído com sucesso!"