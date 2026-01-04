# Gimie - Deployment Guide

## 📱 Aplicativo Gimie
**Connecting people through common wishes**

Projeto ID: `gimie-launch`  
Número do Projeto: `669182239244`  
API Backend: `https://web-production-3495.up.railway.app/`

---

## 🏗️ Estrutura do Projeto

```
/workspace/
├── lib/
│   ├── config/           # Configurações (API, Firebase)
│   ├── models/           # Modelos de dados (Product, User)
│   ├── providers/        # State Management (Auth, Product)
│   ├── screens/          # Telas do aplicativo
│   ├── services/         # Serviços (API, Firebase)
│   ├── widgets/          # Componentes reutilizáveis
│   └── main.dart         # Ponto de entrada
├── android/              # Configuração Android
├── ios/                  # Configuração iOS
├── assets/               # Recursos (imagens, fontes)
└── pubspec.yaml          # Dependências
```

---

## 🔥 Configuração do Firebase

### 1. Instalar Firebase CLI
```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

### 2. Configurar Firebase
```bash
# Login no Firebase
firebase login

# Configurar o projeto
flutterfire configure --project=gimie-launch
```

Isso gerará automaticamente o arquivo `firebase_options.dart` com suas credenciais.

### 3. Atualizar google-services.json (Android)
1. Acesse o [Firebase Console](https://console.firebase.google.com/)
2. Selecione o projeto `gimie-launch`
3. Vá em Project Settings > Your Apps
4. Baixe o `google-services.json` para Android
5. Substitua o arquivo em `/workspace/android/app/google-services.json`

### 4. Atualizar GoogleService-Info.plist (iOS)
1. No mesmo Firebase Console
2. Baixe o `GoogleService-Info.plist` para iOS
3. Substitua o arquivo em `/workspace/ios/Runner/GoogleService-Info.plist`

---

## 🌐 Configuração da API

A API está configurada para usar: `https://web-production-3495.up.railway.app/`

### Endpoints disponíveis:
- **Auth:**
  - `POST /api/auth/login` - Login de usuário
  - `POST /api/auth/register` - Registro de usuário

- **Products:**
  - `GET /api/products` - Listar produtos
  - `GET /api/products/:id` - Obter produto específico
  - `POST /api/products` - Criar produto
  - `DELETE /api/products/:id` - Deletar produto
  - `POST /api/products/:id/like` - Curtir produto
  - `GET /api/products/search?q=query` - Buscar produtos

- **Users:**
  - `GET /api/users/:id` - Obter perfil do usuário
  - `PUT /api/users/:id` - Atualizar perfil

---

## 📦 Instalação de Dependências

```bash
# Instalar dependências do Flutter
flutter pub get

# Para iOS, instalar pods
cd ios
pod install
cd ..
```

---

## 🚀 Build e Execução

### Desenvolvimento

```bash
# Executar em modo debug
flutter run

# Executar em dispositivo específico
flutter run -d <device_id>

# Ver dispositivos disponíveis
flutter devices
```

### Android - Build para Produção

#### 1. Gerar Keystore (primeira vez)
```bash
keytool -genkey -v -keystore ~/gimie-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias gimie
```

#### 2. Configurar key.properties
Crie o arquivo `/workspace/android/key.properties`:
```properties
storePassword=<sua-senha>
keyPassword=<sua-senha>
keyAlias=gimie
storeFile=<caminho-para-gimie-key.jks>
```

#### 3. Atualizar build.gradle
Adicione ao `/workspace/android/app/build.gradle` (antes do android block):
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            ...
        }
    }
}
```

#### 4. Build APK/AAB
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recomendado para Play Store)
flutter build appbundle --release
```

Os arquivos gerados estarão em:
- APK: `/workspace/build/app/outputs/flutter-apk/app-release.apk`
- AAB: `/workspace/build/app/outputs/bundle/release/app-release.aab`

---

## 🍎 iOS - Build para Produção

### 1. Configurar Bundle ID
No Xcode, abra `/workspace/ios/Runner.xcworkspace` e configure:
- Bundle Identifier: `com.gimie.app`
- Team: Sua equipe de desenvolvimento Apple

### 2. Configurar Signing
1. Abra o projeto no Xcode
2. Selecione Runner > Signing & Capabilities
3. Configure seu Team e provisioning profiles

### 3. Build para App Store
```bash
# Build para iOS
flutter build ios --release

# Ou abrir no Xcode
open ios/Runner.xcworkspace
```

No Xcode:
1. Product > Archive
2. Distribute App
3. App Store Connect
4. Upload

---

## 📲 Deploy nas Lojas

### Google Play Store

#### 1. Criar conta de desenvolvedor
- Acesse [Google Play Console](https://play.google.com/console)
- Pague a taxa única de $25 USD

#### 2. Criar novo aplicativo
1. Clique em "Criar app"
2. Preencha informações básicas:
   - Nome: Gimie
   - Idioma padrão: Português (Brasil)
   - Tipo: App
   - Categoria: Social / Shopping

#### 3. Preparar listagem na loja
**Informações necessárias:**
- Título: Gimie
- Descrição curta: Connecting people through common wishes
- Descrição completa: [Descreva o app]
- Screenshots: Mínimo 2 por dispositivo
- Ícone: 512x512 PNG
- Feature Graphic: 1024x500 PNG

#### 4. Upload do App Bundle
1. Vá em "Produção" > "Criar nova versão"
2. Upload do arquivo `app-release.aab`
3. Preencha notas da versão
4. Revisar e publicar

#### 5. Formulários e Políticas
- Classificação de conteúdo
- Público-alvo
- Política de privacidade (URL necessária)
- Declarações sobre coleta de dados

---

### Apple App Store

#### 1. Criar conta de desenvolvedor
- Acesse [Apple Developer](https://developer.apple.com/)
- Pague $99 USD/ano

#### 2. Criar App ID
1. Certificates, Identifiers & Profiles
2. Identifiers > App IDs
3. Register a New Identifier
4. Bundle ID: `com.gimie.app`

#### 3. App Store Connect
1. Acesse [App Store Connect](https://appstoreconnect.apple.com/)
2. My Apps > + > New App
3. Preencha:
   - Nome: Gimie
   - Idioma primário: Português (Brasil)
   - Bundle ID: com.gimie.app
   - SKU: gimie-001

#### 4. Preparar informações
**Necessário:**
- App Preview e Screenshots (vários tamanhos)
- Ícone do app: 1024x1024 PNG
- Descrição
- Palavras-chave
- URL de suporte
- URL de política de privacidade
- Categoria: Social Networking / Shopping

#### 5. Upload via Xcode
1. Archive o app no Xcode
2. Distribute App > App Store Connect
3. Upload
4. Aguarde processamento

#### 6. Submeter para revisão
1. Preencha todas as informações
2. Adicione notas para revisão
3. Submit for Review

---

## 🔧 Checklist Pré-Deploy

### Firebase
- [ ] Projeto Firebase configurado (`gimie-launch`)
- [ ] Authentication habilitado (Email/Password)
- [ ] Firestore habilitado
- [ ] Storage habilitado
- [ ] `google-services.json` atualizado
- [ ] `GoogleService-Info.plist` atualizado
- [ ] Regras de segurança configuradas

### API
- [ ] API acessível em `https://web-production-3495.up.railway.app/`
- [ ] Endpoints testados
- [ ] Autenticação funcionando

### Android
- [ ] Keystore gerado e configurado
- [ ] Bundle ID: `com.gimie.app`
- [ ] Versão e versionCode atualizados
- [ ] Ícone do app configurado
- [ ] Permissões declaradas no AndroidManifest

### iOS
- [ ] Bundle ID configurado: `com.gimie.app`
- [ ] Provisioning profiles configurados
- [ ] Signing configurado
- [ ] Ícone do app configurado
- [ ] Info.plist com permissões

### Geral
- [ ] Screenshots preparados
- [ ] Descrições escritas
- [ ] Política de privacidade publicada
- [ ] Termos de uso publicados
- [ ] Testado em dispositivos reais
- [ ] Performance otimizada

---

## 🧪 Testes

```bash
# Executar testes
flutter test

# Análise de código
flutter analyze

# Verificar problemas
flutter doctor -v
```

---

## 📝 Política de Privacidade (Template)

Você precisará criar e hospedar uma política de privacidade. Template básico:

```
POLÍTICA DE PRIVACIDADE - GIMIE

Última atualização: [DATA]

1. INFORMAÇÕES COLETADAS
- Email e senha (para autenticação)
- Nome e username
- Produtos adicionados
- Imagens de produtos

2. USO DAS INFORMAÇÕES
- Autenticação de usuários
- Exibição de produtos
- Conexão entre usuários

3. COMPARTILHAMENTO
- Não compartilhamos dados com terceiros
- Dados armazenados no Firebase

4. SEGURANÇA
- Dados criptografados
- Firebase Authentication

5. CONTATO
[Seu email de contato]
```

Hospede em um site acessível publicamente.

---

## 🆘 Troubleshooting

### Erro de Firebase
```bash
# Reconfigurar Firebase
flutterfire configure --project=gimie-launch
```

### Erro de dependências
```bash
flutter clean
flutter pub get
```

### Erro de build Android
```bash
cd android
./gradlew clean
cd ..
flutter build apk
```

### Erro de build iOS
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter build ios
```

---

## 📞 Suporte

Para dúvidas sobre:
- **Firebase**: [Firebase Documentation](https://firebase.google.com/docs)
- **Flutter**: [Flutter Documentation](https://flutter.dev/docs)
- **Play Store**: [Play Console Help](https://support.google.com/googleplay/android-developer)
- **App Store**: [App Store Connect Help](https://developer.apple.com/support/app-store-connect/)

---

## 📄 Licença

Copyright © 2024 Gimie. Todos os direitos reservados.

---

**Boa sorte com o deploy! 🚀**
