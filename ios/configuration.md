# 📱 Configuração iOS - Gimie

## 🎯 Bundle Identifiers

**IMPORTANTE:** Substitua `com.seudominio` pelo seu domínio real.

### Bundle IDs Necessários:
- **App Principal**: `com.seudominio.gimie`
- **Share Extension**: `com.seudominio.gimie.ShareExtension`
- **App Group**: `group.com.seudominio.gimie.shareextension`

## 📋 Checklist de Configuração

### 1. No Xcode - Target Runner:
- [ ] Bundle Identifier: `com.seudominio.gimie`
- [ ] Version: `1.0.0`
- [ ] Build: `1`
- [ ] Team: Seu Apple Developer Team
- [ ] Signing: Apple Distribution
- [ ] App Groups: `group.com.seudominio.gimie.shareextension`

### 2. No Xcode - Target ShareExtension:
- [ ] Bundle Identifier: `com.seudominio.gimie.ShareExtension`
- [ ] Version: `1.0.0`
- [ ] Build: `1`
- [ ] Team: Mesmo do Runner
- [ ] Signing: Apple Distribution
- [ ] App Groups: `group.com.seudominio.gimie.shareextension`

### 3. Arquivos para Atualizar:

#### `ios/ShareExtension/ShareViewController.swift`:
```swift
private let appGroupId = "group.com.seudominio.gimie.shareextension"
```

#### `ios/Runner/AppDelegate.swift`:
```swift
private let appGroupId = "group.com.seudominio.gimie.shareextension"
```

#### `lib/services/share_service.dart`:
```dart
static const String _appGroupId = 'group.com.seudominio.gimie.shareextension';
```

## 🔧 Comandos Úteis

### Verificar certificados:
```bash
security find-identity -v -p codesigning
```

### Limpar e rebuild:
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release
```

### Abrir Xcode:
```bash
open ios/Runner.xcworkspace
```

## ⚠️ Problemas Comuns

### "No such module 'ShareExtension'":
- Verifique se o target ShareExtension está sendo compilado
- Confirme que todos os arquivos estão no target correto

### "App Groups not found":
- Verifique se o App Group está configurado em ambos os targets
- Confirme que o ID do App Group está correto

### "Invalid Bundle":
- Verifique se version e build são iguais em ambos os targets
- Confirme que Bundle IDs estão corretos

## 📞 Suporte

Se encontrar problemas, verifique:
1. Apple Developer Portal
2. Xcode Organizer
3. App Store Connect
4. Console logs do dispositivo