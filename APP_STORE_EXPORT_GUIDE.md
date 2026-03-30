# 📱 Guia Completo: Exportar Gimie para App Store

## 🎯 Pré-requisitos

### **Contas e Certificados:**
- ✅ Apple Developer Account ativo ($99/ano)
- ✅ Xcode instalado (versão mais recente)
- ✅ macOS atualizado
- ✅ Certificados de desenvolvimento e distribuição

### **Configurações Necessárias:**
- ✅ Bundle Identifier único
- ✅ Provisioning Profiles
- ✅ App Store Connect configurado
- ✅ Ícones e assets preparados

## 📋 **Passo a Passo Completo**

### **1. Preparação Inicial**

#### A. Instalar Dependências
```bash
# No diretório do projeto
flutter pub get
cd ios
pod install
cd ..
```

#### B. Verificar Configuração Flutter
```bash
flutter doctor
flutter clean
flutter pub get
```

### **2. Configuração no Xcode**

#### A. Abrir Projeto no Xcode
```bash
open ios/Runner.xcworkspace
```

⚠️ **IMPORTANTE:** Sempre abra o arquivo `.xcworkspace`, não o `.xcodeproj`

#### B. Configurar Bundle Identifier
1. Selecione o projeto "Runner" na navegação à esquerda
2. Selecione o target "Runner"
3. Na aba "General":
   - **Bundle Identifier**: `com.seudominio.gimie` (deve ser único)
   - **Version**: `1.0.0`
   - **Build**: `1`

#### C. Configurar Share Extension
1. Selecione o target "ShareExtension"
2. Configure:
   - **Bundle Identifier**: `com.seudominio.gimie.ShareExtension`
   - **Version**: `1.0.0`
   - **Build**: `1`

#### D. Configurar Signing & Capabilities
1. **Para o target "Runner":**
   - Team: Selecione seu Apple Developer Team
   - Signing Certificate: Apple Distribution
   - Provisioning Profile: App Store

2. **Para o target "ShareExtension":**
   - Team: Mesmo do Runner
   - Signing Certificate: Apple Distribution
   - Provisioning Profile: App Store

#### E. Configurar App Groups
1. **Target "Runner":**
   - Adicione capability "App Groups"
   - Adicione: `group.com.seudominio.gimie.shareextension`

2. **Target "ShareExtension":**
   - Adicione capability "App Groups"
   - Adicione: `group.com.seudominio.gimie.shareextension`

### **3. Atualizar Configurações no Código**

#### A. Atualizar Bundle IDs no Código
Substitua nos seguintes arquivos:

**`ios/ShareExtension/ShareViewController.swift`:**
```swift
private let appGroupId = "group.com.seudominio.gimie.shareextension"
```

**`ios/Runner/AppDelegate.swift`:**
```swift
private let appGroupId = "group.com.seudominio.gimie.shareextension"
```

**`lib/services/share_service.dart`:**
```dart
static const String _appGroupId = 'group.com.seudominio.gimie.shareextension';
```

### **4. Preparar Assets**

#### A. Ícones da App
Certifique-se de ter os ícones nas seguintes resoluções:
- 20x20, 29x29, 40x40, 58x58, 60x60, 80x80, 87x87, 120x120, 180x180, 1024x1024

#### B. Launch Screen
Verifique se `ios/Runner/Assets.xcassets/LaunchImage.imageset/` contém as imagens corretas.

#### C. App Store Assets
Prepare para o App Store Connect:
- Ícone 1024x1024 (PNG, sem transparência)
- Screenshots para diferentes tamanhos de tela
- Descrição da app
- Palavras-chave
- Política de privacidade (URL)

### **5. Build para App Store**

#### A. Configurar Build Settings
No Xcode:
1. Selecione "Any iOS Device (arm64)" como destino
2. Vá em Product > Scheme > Edit Scheme
3. Selecione "Release" em Build Configuration

#### B. Archive da App
1. No Xcode: Product > Archive
2. Aguarde o build completar
3. A janela "Organizer" abrirá automaticamente

#### C. Validar Archive
1. Na janela Organizer, selecione seu archive
2. Clique em "Validate App"
3. Escolha "App Store Connect"
4. Siga as instruções e aguarde validação

#### D. Distribuir para App Store
1. Clique em "Distribute App"
2. Escolha "App Store Connect"
3. Selecione "Upload"
4. Aguarde o upload completar

### **6. Configurar App Store Connect**

#### A. Criar App Record
1. Acesse [App Store Connect](https://appstoreconnect.apple.com)
2. Vá em "My Apps" > "+" > "New App"
3. Configure:
   - **Platform**: iOS
   - **Name**: Gimie
   - **Primary Language**: Portuguese (Brazil)
   - **Bundle ID**: Selecione o que você configurou
   - **SKU**: gimie-ios (ou similar)

#### B. Preencher Informações da App
1. **App Information:**
   - Nome: Gimie
   - Subtitle: Conectando pessoas através de desejos em comum
   - Category: Shopping ou Social Networking

2. **Pricing and Availability:**
   - Price: Free
   - Availability: All countries

3. **App Privacy:**
   - Configure conforme coleta de dados do app

#### C. Preparar para Review
1. **Version Information:**
   - Version: 1.0.0
   - Copyright: © 2026 Seu Nome/Empresa

2. **App Review Information:**
   - Contact Information
   - Demo Account (se necessário)
   - Notes for Review

3. **Version Release:**
   - Automatic ou Manual release

### **7. Screenshots e Metadata**

#### A. Screenshots Necessários
Para cada tamanho de dispositivo:
- iPhone 6.7": 1290 x 2796 pixels
- iPhone 6.5": 1242 x 2688 pixels  
- iPhone 5.5": 1242 x 2208 pixels
- iPad Pro (6th Gen): 2048 x 2732 pixels
- iPad Pro (2nd Gen): 2048 x 2732 pixels

#### B. Descrição da App
```
Gimie - Conectando pessoas através de desejos em comum

Descubra, compartilhe e realize seus desejos com a comunidade Gimie!

🎯 PRINCIPAIS RECURSOS:
• Adicione produtos de qualquer loja online
• Compartilhe sua lista de desejos
• Descubra produtos através de outros usuários
• Share Extension para adicionar produtos rapidamente
• Extração automática de dados de produtos
• Categorização inteligente
• Interface moderna e intuitiva

✨ FUNCIONALIDADES EXCLUSIVAS:
• Scraping automático de dados de produtos
• Compartilhamento entre apps
• Sugestões personalizadas por categoria
• Sistema de likes e interações sociais

🔒 PRIVACIDADE:
Seus dados são protegidos e você controla o que compartilhar.

Baixe agora e comece a descobrir seus próximos desejos!
```

### **8. Comandos Úteis**

#### A. Build via Terminal (Alternativo)
```bash
# Limpar projeto
flutter clean
flutter pub get
cd ios && pod install && cd ..

# Build para iOS
flutter build ios --release

# Archive via xcodebuild (avançado)
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -destination generic/platform=iOS -archivePath build/Runner.xcarchive archive
```

#### B. Verificar Configurações
```bash
# Verificar certificados
security find-identity -v -p codesigning

# Verificar provisioning profiles
ls ~/Library/MobileDevice/Provisioning\ Profiles/
```

### **9. Checklist Final**

#### Antes do Upload:
- [ ] Bundle IDs únicos e corretos
- [ ] Certificados válidos
- [ ] App Groups configurados
- [ ] Ícones em todas as resoluções
- [ ] Versão e build number corretos
- [ ] Teste em dispositivo físico
- [ ] Validação no Xcode passou
- [ ] Share Extension funcionando

#### App Store Connect:
- [ ] App record criado
- [ ] Screenshots uploaded
- [ ] Descrição preenchida
- [ ] Política de privacidade
- [ ] Informações de contato
- [ ] Pricing configurado
- [ ] Build selecionado para review

### **10. Troubleshooting**

#### Problemas Comuns:

**"No suitable application records were found"**
- Verifique se o Bundle ID no Xcode corresponde ao App Store Connect

**"Invalid Bundle"**
- Verifique se todos os targets têm o mesmo version/build
- Confirme que Share Extension está incluído no archive

**"Missing Compliance"**
- Configure Export Compliance no App Store Connect

**"Invalid Signature"**
- Verifique certificados e provisioning profiles
- Certifique-se de usar Apple Distribution certificate

### **11. Após Aprovação**

#### A. Monitoramento:
- App Store Connect Analytics
- Crash reports
- User reviews

#### B. Atualizações:
- Incremente build number para cada upload
- Incremente version para releases públicas

## 🎉 **Resultado Final**

Seguindo este guia, você terá:
- ✅ App configurado corretamente
- ✅ Archive válido para App Store
- ✅ Upload bem-sucedido
- ✅ App pronto para review
- ✅ Share Extension funcionando
- ✅ Scraping API integrado

## 📞 **Suporte**

Se encontrar problemas:
1. Verifique Apple Developer Documentation
2. Consulte logs no Xcode
3. Use App Store Connect Help
4. Verifique status dos serviços Apple

**Boa sorte com o lançamento do Gimie! 🚀**