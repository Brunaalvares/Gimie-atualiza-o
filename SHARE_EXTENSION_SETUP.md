# Implementação do Share Extension - Gimie iOS

Este documento contém todas as instruções para configurar e usar o Share Extension no app Gimie.

## ✅ Arquivos Criados

Os seguintes arquivos foram criados e configurados:

### Flutter/Dart
- `lib/services/share_service.dart` - Serviço principal para gerenciar compartilhamento
- `pubspec.yaml` - Adicionada dependência `receive_sharing_intent: ^1.4.5`
- `lib/main.dart` - Inicialização do ShareService
- `lib/screens/add_product_screen.dart` - Integração com conteúdo compartilhado
- `lib/services/firebase_service.dart` - Método para upload de imagens via bytes

### iOS Native
- `ios/ShareExtension/ShareViewController.swift` - Controller principal do Share Extension
- `ios/ShareExtension/MainInterface.storyboard` - Interface visual do Share Extension
- `ios/ShareExtension/Info.plist` - Configurações do Share Extension
- `ios/ShareExtension/README.md` - Instruções específicas do iOS
- `ios/Podfile` - Target do Share Extension adicionado
- `ios/Runner/Info.plist` - URL schemes e App Groups configurados
- `ios/Runner/AppDelegate.swift` - Métodos nativos para comunicação

## 🚀 Próximos Passos

### 1. Instalar Dependências Flutter
```bash
flutter pub get
```

### 2. Instalar Pods iOS
```bash
cd ios
pod install
```

### 3. Configurar no Xcode

Abra o projeto no Xcode (`ios/Runner.xcworkspace`) e siga estas etapas:

#### A. Adicionar Target do Share Extension
1. Clique no projeto na navegação à esquerda
2. Clique no botão "+" na seção "TARGETS"
3. Selecione "Share Extension" em "Application Extension"
4. Configure:
   - **Product Name**: `ShareExtension`
   - **Bundle Identifier**: `[SEU_BUNDLE_ID].ShareExtension`
   - **Language**: Swift

#### B. Adicionar Arquivos ao Target
1. Selecione os arquivos em `ios/ShareExtension/`:
   - `ShareViewController.swift`
   - `MainInterface.storyboard`
   - `Info.plist`
2. No File Inspector, marque "ShareExtension" como target

#### C. Configurar App Groups
1. Selecione o target "Runner"
2. Vá para "Signing & Capabilities"
3. Adicione "App Groups" capability
4. Adicione o grupo: `group.com.gimie.shareextension`

5. Repita para o target "ShareExtension"

#### D. Configurar Bundle Identifiers
- **Runner**: Seu bundle ID principal
- **ShareExtension**: `[SEU_BUNDLE_ID].ShareExtension`

### 4. Atualizar Bundle Identifiers no Código

Substitua `com.gimie.app` pelos seus bundle identifiers reais nos seguintes arquivos:

- `ios/ShareExtension/ShareViewController.swift` (linha 9)
- `ios/Runner/AppDelegate.swift` (linha 8)
- `lib/services/share_service.dart` (linha 9)

## 🎯 Como Funciona

### Fluxo de Compartilhamento

1. **Usuário compartilha** conteúdo de outro app
2. **Share Extension** processa o conteúdo (texto, URL, imagem)
3. **Dados são salvos** no App Group UserDefaults
4. **App principal abre** via URL scheme (`gimie://share`)
5. **Flutter carrega** o conteúdo na tela de adicionar produto

### Tipos de Conteúdo Suportados

- ✅ **Texto**: Descrições, comentários
- ✅ **URLs**: Links de produtos  
- ✅ **Imagens**: Fotos de produtos (até 10)
- ✅ **Vídeos**: Vídeos curtos (1 vídeo)
- ✅ **Páginas Web**: URLs de páginas

## 🧪 Como Testar

1. **Compile** o app no dispositivo iOS
2. **Abra outro app** (Safari, Fotos, etc.)
3. **Toque em "Compartilhar"**
4. **Procure "Gimie Share"** na lista de opções
5. **Toque para compartilhar**
6. **O Gimie deve abrir** com conteúdo pré-preenchido

## 🔧 Troubleshooting

### Share Extension não aparece
- ✅ Verifique se o target ShareExtension está sendo compilado
- ✅ Confirme as configurações de App Groups
- ✅ Verifique o Info.plist do Share Extension

### App não abre após compartilhar
- ✅ Confirme o URL scheme no Info.plist do app principal
- ✅ Verifique a implementação do AppDelegate
- ✅ Teste o URL scheme: `gimie://share`

### Conteúdo não é carregado no Flutter
- ✅ Verifique os App Groups (mesmo ID nos dois targets)
- ✅ Confirme os métodos nativos no AppDelegate
- ✅ Verifique os logs do console

### Erro de compilação
- ✅ Execute `flutter clean && flutter pub get`
- ✅ Execute `cd ios && pod install`
- ✅ Verifique se todos os arquivos estão nos targets corretos

## 📱 Interface do Share Extension

O Share Extension mostra uma interface simples com:
- Logo do Gimie
- Título "Compartilhar com Gimie"
- Mensagem de status
- Processamento automático do conteúdo

## 🔐 Segurança e Privacidade

- Dados compartilhados ficam apenas no App Group local
- Conteúdo é limpo após ser processado
- Não há comunicação externa durante o compartilhamento
- Imagens são convertidas para base64 temporariamente

## 📋 Checklist de Implementação

- [x] Criar arquivos Swift do Share Extension
- [x] Configurar Storyboard e Info.plist
- [x] Implementar serviço Flutter de compartilhamento
- [x] Adicionar dependência receive_sharing_intent
- [x] Configurar App Groups e URL schemes
- [x] Integrar com tela de adicionar produto
- [x] Suporte para upload de imagens via bytes
- [ ] Configurar targets no Xcode
- [ ] Testar em dispositivo real
- [ ] Ajustar bundle identifiers
- [ ] Publicar na App Store

## 🎉 Resultado Final

Após a implementação completa, os usuários poderão:

1. **Compartilhar produtos** de qualquer app para o Gimie
2. **Adicionar rapidamente** itens à sua lista de desejos
3. **Processar automaticamente** URLs, textos e imagens
4. **Ter uma experiência fluida** entre apps

O Share Extension torna o Gimie mais integrado ao ecossistema iOS e facilita a adição de produtos de qualquer fonte!