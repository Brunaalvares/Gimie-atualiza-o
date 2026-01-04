## 🚀 Quick Start Guide - Gimie

### 📋 Pré-requisitos Instalados

Antes de começar, certifique-se de ter instalado:

```bash
# Verificar instalações
flutter doctor -v
firebase --version
```

Você deve ter:
- ✅ Flutter SDK 3.0+
- ✅ Dart SDK
- ✅ Android Studio / Xcode
- ✅ Firebase CLI
- ✅ Git

---

### ⚡ Configuração Rápida (5 minutos)

#### 1️⃣ Instalar Dependências
```bash
cd /workspace
flutter pub get
```

#### 2️⃣ Configurar Firebase
```bash
# Login no Firebase
firebase login

# Configurar projeto
flutterfire configure --project=gimie-launch
```

Este comando irá:
- ✅ Criar `firebase_options.dart`
- ✅ Configurar iOS e Android automaticamente

#### 3️⃣ Para iOS (se estiver no Mac)
```bash
cd ios
pod install
cd ..
```

#### 4️⃣ Executar o App
```bash
# Ver dispositivos disponíveis
flutter devices

# Executar
flutter run
```

---

### 🔥 Configuração Manual do Firebase (se necessário)

#### Android
1. Acesse [Firebase Console](https://console.firebase.google.com/project/gimie-launch)
2. Adicione um app Android
3. Package name: `com.gimie.app`
4. Baixe `google-services.json`
5. Coloque em `/workspace/android/app/`

#### iOS
1. No mesmo Firebase Console
2. Adicione um app iOS
3. Bundle ID: `com.gimie.app`
4. Baixe `GoogleService-Info.plist`
5. Coloque em `/workspace/ios/Runner/`

---

### 🛠️ Comandos Úteis

```bash
# Limpar build
flutter clean && flutter pub get

# Verificar problemas
flutter doctor

# Executar em dispositivo específico
flutter run -d <device-id>

# Build de produção Android
flutter build apk --release

# Build de produção iOS
flutter build ios --release

# Analisar código
flutter analyze

# Formatar código
dart format lib/
```

---

### 📱 Testando o App

#### Contas de Teste
Você pode criar contas de teste no app ou usar Firebase Console.

#### Fluxo de Teste
1. ✅ Abrir app → Ver Splash Screen
2. ✅ Clicar Next → Ir para Login
3. ✅ Criar conta nova
4. ✅ Explorar feed de produtos
5. ✅ Adicionar produto (+ no centro)
6. ✅ Buscar produtos
7. ✅ Ver perfil

---

### 🐛 Problemas Comuns

#### "Firebase not configured"
```bash
flutterfire configure --project=gimie-launch
```

#### "Pod install failed" (iOS)
```bash
cd ios
pod deintegrate
pod install
cd ..
```

#### "Gradle build failed" (Android)
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

#### "Unable to load asset"
```bash
flutter clean
flutter pub get
```

---

### 📦 Estrutura de Pastas

```
lib/
├── main.dart                    # 🚀 Início aqui
├── config/
│   ├── api_config.dart         # 🌐 Config da API
│   └── firebase_config.dart    # 🔥 Config Firebase
├── models/
│   ├── user_model.dart         # 👤 Modelo usuário
│   └── product_model.dart      # 🛍️ Modelo produto
├── providers/
│   ├── auth_provider.dart      # 🔐 Estado auth
│   └── product_provider.dart   # 📦 Estado products
├── services/
│   ├── api_service.dart        # 🌐 Chamadas API
│   └── firebase_service.dart   # 🔥 Firebase ops
└── screens/
    ├── splash_screen.dart      # 💫 Splash
    ├── login_screen.dart       # 🔐 Login
    ├── create_account_screen.dart  # ✍️ Cadastro
    ├── main_shell.dart         # 🏠 Navigation
    ├── home_screen.dart        # 📱 Feed
    ├── search_screen.dart      # 🔍 Busca
    ├── add_product_screen.dart # ➕ Adicionar
    └── profile_screen.dart     # 👤 Perfil
```

---

### 🎯 Próximos Passos

1. **Desenvolvimento**
   - Testar todas as funcionalidades
   - Adicionar mais produtos de teste
   - Testar em diferentes dispositivos

2. **Preparar para Deploy**
   - Ler [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
   - Configurar keystore (Android)
   - Configurar signing (iOS)
   - Preparar screenshots

3. **Publicar**
   - Google Play Store
   - Apple App Store

---

### 📞 Ajuda

- 📖 [Documentação Completa](README.md)
- 🚀 [Guia de Deploy](DEPLOYMENT_GUIDE.md)
- 🔥 [Segurança Firebase](FIREBASE_SECURITY.md)
- 📝 [Changelog](CHANGELOG.md)

---

### ✅ Checklist Inicial

- [ ] Flutter instalado e funcionando
- [ ] Firebase configurado
- [ ] Dependências instaladas
- [ ] App rodando em emulador/dispositivo
- [ ] Login/Cadastro funcionando
- [ ] Produtos sendo listados
- [ ] Upload de imagens funcionando

**Pronto! Você está configurado! 🎉**
