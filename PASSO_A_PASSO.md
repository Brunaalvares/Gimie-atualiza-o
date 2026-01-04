# 🇧🇷 Guia de Configuração Passo a Passo - Gimie

## 📌 PASSO A PASSO COMPLETO

Este é um guia detalhado para configurar e publicar o app Gimie nas lojas Apple e Google Play.

---

## ✅ ETAPA 1: VERIFICAR INSTALAÇÕES (5 min)

### O que você precisa ter instalado:

```bash
# 1. Verificar Flutter
flutter --version
# Deve mostrar: Flutter 3.0.0 ou superior

# 2. Verificar Dart
dart --version

# 3. Verificar Android SDK (para Android)
# Abra Android Studio > SDK Manager > Verifique instalação

# 4. Verificar Xcode (para iOS - somente Mac)
xcodebuild -version

# 5. Verificar Firebase CLI
firebase --version
npm install -g firebase-tools  # Se não tiver
```

### Verificação completa:
```bash
flutter doctor -v
```

Certifique-se de que todos os itens estão ✓ (exceto web se não for usar).

---

## 🔥 ETAPA 2: CONFIGURAR FIREBASE (10 min)

### 2.1. Login no Firebase

```bash
firebase login
```

Isso abrirá o navegador para você fazer login com sua conta Google.

### 2.2. Instalar FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 2.3. Configurar Projeto Automaticamente

```bash
cd /workspace
flutterfire configure --project=gimie-launch
```

Este comando vai:
- ✅ Conectar ao projeto Firebase `gimie-launch`
- ✅ Gerar `lib/firebase_options.dart`
- ✅ Configurar Android
- ✅ Configurar iOS

**IMPORTANTE:** Se o comando não funcionar, siga a configuração manual abaixo.

### 2.4. Configuração Manual (se necessário)

#### Para Android:

1. Acesse: https://console.firebase.google.com/project/gimie-launch
2. Clique em "Adicionar app" → Escolha Android
3. Preencha:
   - **Package name:** `com.gimie.app`
   - **App nickname:** Gimie
4. Baixe o arquivo `google-services.json`
5. Coloque em: `/workspace/android/app/google-services.json`

#### Para iOS:

1. No mesmo Firebase Console
2. Clique em "Adicionar app" → Escolha iOS
3. Preencha:
   - **Bundle ID:** `com.gimie.app`
   - **App nickname:** Gimie
4. Baixe o arquivo `GoogleService-Info.plist`
5. Coloque em: `/workspace/ios/Runner/GoogleService-Info.plist`

### 2.5. Habilitar Serviços no Firebase Console

1. **Authentication:**
   - Vá em Authentication → Sign-in method
   - Habilite "Email/Password"

2. **Firestore Database:**
   - Vá em Firestore Database → Create database
   - Escolha "Start in production mode"
   - Selecione localização: southamerica-east1 (São Paulo)

3. **Storage:**
   - Vá em Storage → Get started
   - Use regras padrão (vamos configurar depois)

4. **Regras de Segurança:**
   - Copie as regras de `/workspace/FIREBASE_SECURITY.md`
   - Cole em Firestore Rules e Storage Rules
   - Publique

---

## 📦 ETAPA 3: INSTALAR DEPENDÊNCIAS (5 min)

```bash
cd /workspace

# Limpar cache
flutter clean

# Instalar dependências
flutter pub get

# Para iOS (somente Mac)
cd ios
pod install
cd ..
```

**Possíveis erros:**

- **"Pod install failed":** 
  ```bash
  cd ios
  pod repo update
  pod deintegrate
  pod install
  cd ..
  ```

- **"pub get failed":**
  ```bash
  flutter clean
  rm pubspec.lock
  flutter pub get
  ```

---

## 🧪 ETAPA 4: TESTAR O APP (10 min)

### 4.1. Conectar Dispositivo ou Emulador

**Android:**
```bash
# Listar dispositivos
flutter devices

# Se não aparecer nenhum, abra um emulador no Android Studio
```

**iOS (Mac):**
```bash
# Abrir simulador
open -a Simulator

# Ou use dispositivo físico conectado
flutter devices
```

### 4.2. Executar o App

```bash
flutter run
```

### 4.3. Testar Funcionalidades

- [ ] Splash screen aparece
- [ ] Pode ir para login
- [ ] Pode criar conta
- [ ] Login funciona
- [ ] Feed de produtos carrega
- [ ] Pode adicionar produto
- [ ] Upload de imagem funciona
- [ ] Busca funciona
- [ ] Perfil mostra produtos

**Se algo não funcionar:**
- Verifique se Firebase está configurado
- Verifique se a API está acessível
- Veja logs: `flutter logs`

---

## 🎨 ETAPA 5: PREPARAR ASSETS (30 min)

### 5.1. Ícone do App

Crie um ícone 1024x1024 pixels:
- Coloque em: `/workspace/assets/images/icon.png`
- Use ferramentas: Figma, Canva, ou Adobe Illustrator

### 5.2. Gerar Ícones Automáticamente

```bash
# Adicione ao pubspec.yaml (já está)
# flutter pub run flutter_launcher_icons

# Gera ícones para todas as plataformas
```

### 5.3. Screenshots

Tire screenshots do app:
- **Android:** Mínimo 2 screenshots (phone e tablet)
  - Resolução: 1080x1920 ou similar
- **iOS:** Screenshots para diferentes tamanhos
  - iPhone 6.7" (1290x2796)
  - iPhone 6.5" (1242x2688)
  - iPad Pro 12.9" (2048x2732)

**Dica:** Use dispositivos/emuladores para tirar screenshots reais.

---

## 🤖 ETAPA 6: BUILD ANDROID (30 min)

### 6.1. Gerar Keystore (primeira vez)

```bash
keytool -genkey -v -keystore ~/gimie-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias gimie
```

Anote as senhas! Você vai precisar delas.

### 6.2. Criar key.properties

Crie `/workspace/android/key.properties`:

```properties
storePassword=SUA_SENHA_AQUI
keyPassword=SUA_SENHA_AQUI
keyAlias=gimie
storeFile=/Users/seu-usuario/gimie-key.jks
```

**IMPORTANTE:** Não commite este arquivo! (já está no .gitignore)

### 6.3. Build App Bundle (AAB)

```bash
flutter build appbundle --release
```

Arquivo gerado em:
`/workspace/build/app/outputs/bundle/release/app-release.aab`

### 6.4. Build APK (opcional, para testes)

```bash
flutter build apk --release
```

Arquivo gerado em:
`/workspace/build/app/outputs/flutter-apk/app-release.apk`

---

## 🍎 ETAPA 7: BUILD iOS (30 min - somente Mac)

### 7.1. Abrir no Xcode

```bash
open ios/Runner.xcworkspace
```

### 7.2. Configurar Team

1. Selecione "Runner" no navegador de projeto
2. Vá em "Signing & Capabilities"
3. Selecione seu "Team" (Apple Developer Account)
4. Verifique Bundle ID: `com.gimie.app`

### 7.3. Configurar Version

1. Em "General"
2. Version: `1.0.0`
3. Build: `1`

### 7.4. Build via Flutter

```bash
flutter build ios --release
```

### 7.5. Archive no Xcode

1. No Xcode: Product → Scheme → Edit Scheme
2. Archive → Build Configuration → Release
3. Product → Archive
4. Aguarde build completar
5. Aparecerá o Organizer com o archive

---

## 📲 ETAPA 8: PUBLICAR NA GOOGLE PLAY STORE (60 min)

### 8.1. Criar Conta de Desenvolvedor

1. Acesse: https://play.google.com/console
2. Crie conta ($25 USD - pagamento único)
3. Preencha informações da conta

### 8.2. Criar Novo App

1. No Play Console, clique "Criar app"
2. Preencha:
   - **Nome:** Gimie
   - **Idioma padrão:** Português (Brasil)
   - **Tipo:** App
   - **Gratuito/Pago:** Gratuito

### 8.3. Preencher Listagem na Loja

**Informações principais:**
- **Título:** Gimie
- **Descrição curta:**
  ```
  Connecting people through common wishes. 
  Compartilhe e descubra produtos que você deseja.
  ```
- **Descrição completa:**
  ```
  O Gimie é um aplicativo social para compartilhar seus desejos e descobrir produtos 
  que outras pessoas também querem. Conecte-se com pessoas que têm interesses similares 
  aos seus e descubra novos produtos.
  
  Funcionalidades:
  • Feed de produtos desejados por outros usuários
  • Adicione seus próprios desejos com fotos
  • Sistema de likes e favoritos
  • Busca inteligente de produtos
  • Perfil personalizado
  • Links diretos para comprar produtos
  
  Connecting people through common wishes! 🎁
  ```

**Assets gráficos:**
- Ícone: 512x512 PNG (será solicitado)
- Feature Graphic: 1024x500 PNG
- Screenshots: Pelo menos 2

### 8.4. Categorização

- **Categoria:** Social / Shopping
- **Tags:** wishlist, social, shopping, produtos

### 8.5. Classificação de Conteúdo

1. Complete o questionário
2. Para Gimie, provavelmente será "PEGI 3" ou "Livre"

### 8.6. Público-alvo

- **Idade:** 13+ (ou conforme sua preferência)

### 8.7. Política de Privacidade

Você PRECISA ter uma URL de política de privacidade.

**Opções:**
1. Criar página no GitHub Pages
2. Hospedar em seu site
3. Usar Termly.io (gratuito)

Template básico em `/workspace/DEPLOYMENT_GUIDE.md`

### 8.8. Upload do AAB

1. Vá em "Produção" → "Criar nova versão"
2. Upload do `app-release.aab`
3. Preencha "Notas da versão":
   ```
   Versão 1.0.0
   - Lançamento inicial
   - Feed de produtos
   - Sistema de likes
   - Busca de produtos
   - Perfil de usuário
   ```
4. Salvar

### 8.9. Revisar e Publicar

1. Revise todas as seções
2. Corrija avisos/erros
3. Clique em "Enviar para revisão"
4. Aguarde aprovação (pode levar 1-7 dias)

---

## 🍎 ETAPA 9: PUBLICAR NA APPLE APP STORE (60 min)

### 9.1. Criar Conta de Desenvolvedor

1. Acesse: https://developer.apple.com/
2. Inscreva-se no Apple Developer Program ($99 USD/ano)
3. Aguarde aprovação (pode levar 1-2 dias)

### 9.2. Criar App ID

1. Developer Portal → Certificates, Identifiers & Profiles
2. Identifiers → App IDs → "+"
3. Preencha:
   - **Description:** Gimie
   - **Bundle ID:** `com.gimie.app` (Explicit)
   - **Capabilities:** Sign in with Apple (se for usar)
4. Register

### 9.3. App Store Connect

1. Acesse: https://appstoreconnect.apple.com/
2. My Apps → "+" → New App
3. Preencha:
   - **Platform:** iOS
   - **Nome:** Gimie
   - **Idioma primário:** Portuguese (Brazil)
   - **Bundle ID:** com.gimie.app
   - **SKU:** gimie-001 (único)
   - **User Access:** Full Access

### 9.4. Informações do App

**App Information:**
- **Privacy Policy URL:** (sua URL)
- **Categoria:** Social Networking / Shopping
- **Idade:** 12+

**Pricing and Availability:**
- **Price:** Free
- **Availability:** All countries

### 9.5. Preparar Screenshots

Você precisa de screenshots para:
- iPhone 6.7" (Pro Max)
- iPhone 6.5" 
- iPhone 5.5"
- iPad Pro 12.9"

**Ferramenta útil:** 
- Fastlane Frameit
- App Screenshot Maker online

### 9.6. Descrição da Loja

**Nome:** Gimie

**Subtitle (30 chars):**
```
Wishlist social compartilhada
```

**Descrição:**
```
O Gimie conecta pessoas através de desejos em comum. Compartilhe produtos que você quer, 
descubra o que outras pessoas desejam e conecte-se por interesses similares.

FUNCIONALIDADES PRINCIPAIS:
• 📱 Feed social de produtos desejados
• ➕ Adicione seus desejos com fotos
• ❤️ Curta produtos de outros usuários
• 🔍 Busca inteligente
• 👤 Perfil personalizado
• 🛍️ Links diretos para compras

CONECTE-SE:
O Gimie é mais que uma wishlist. É uma rede social onde você descobre pessoas com 
gostos similares aos seus. Veja o que outros querem, compartilhe seus desejos e 
encontre conexões inesperadas.

PRIVACIDADE:
Seus dados são protegidos com segurança Firebase. Você controla o que compartilha.

Connecting people through common wishes! 🎁
```

**Keywords (100 chars):**
```
wishlist,social,shopping,desejos,produtos,compras,gift,presente
```

**Support URL:** (seu site/email)

### 9.7. Build Information

1. No Xcode, Archive o app (já fizemos)
2. No Organizer, clique "Distribute App"
3. Escolha "App Store Connect"
4. Upload
5. Aguarde processamento (10-30 min)

### 9.8. App Store Connect - Build

1. Volte ao App Store Connect
2. Vá em "1.0 Prepare for Submission"
3. Em "Build", selecione o build que você uploadou
4. Preencha:
   - **Copyright:** 2024 Gimie
   - **Age Rating:** Complete o questionário
   - **App Review Information:**
     - Primeiro nome, Sobrenome
     - Telefone, Email
     - **Demo Account:** (crie uma conta de teste)
       - Email: test@gimie.com
       - Senha: Test@123
   - **Notes:** (opcional)

### 9.9. Submeter para Revisão

1. Revise tudo
2. Clique "Submit for Review"
3. Aguarde resposta (geralmente 24-48h, pode levar até 7 dias)

**Status possíveis:**
- Waiting for Review
- In Review
- Pending Developer Release
- Ready for Sale

---

## 🎯 CHECKLIST FINAL

### Antes de Publicar:

- [ ] Firebase 100% configurado e testado
- [ ] API funcionando corretamente
- [ ] App testado em dispositivos reais
- [ ] Sem crashes ou bugs críticos
- [ ] Screenshots de qualidade
- [ ] Ícone do app criado
- [ ] Descrições escritas
- [ ] Política de privacidade publicada
- [ ] Termos de uso publicados (se aplicável)
- [ ] Conta Play Store criada
- [ ] Conta Apple Developer ativa
- [ ] Keystore Android seguro (backup!)
- [ ] Certificados iOS configurados

### Android:

- [ ] AAB gerado sem erros
- [ ] Listagem completa
- [ ] Screenshots enviados
- [ ] Classificação de conteúdo preenchida
- [ ] Política de privacidade URL adicionada
- [ ] Submetido para revisão

### iOS:

- [ ] Build arquivado no Xcode
- [ ] Upload para App Store Connect completo
- [ ] Screenshots de todos os tamanhos
- [ ] Descrições e keywords preenchidos
- [ ] Conta de teste criada
- [ ] Submetido para revisão

---

## 📞 AJUDA E SUPORTE

### Problemas Comuns:

**"Firebase not configured"**
```bash
flutterfire configure --project=gimie-launch
```

**"Build failed"**
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

**"Permission denied"**
```bash
chmod +x build.sh
./build.sh
```

### Recursos:

- 📚 Documentação: `/workspace/README.md`
- 🚀 Deploy Guide: `/workspace/DEPLOYMENT_GUIDE.md`
- ⚡ Quick Start: `/workspace/QUICKSTART.md`
- 🔒 Firebase Security: `/workspace/FIREBASE_SECURITY.md`

### Links Úteis:

- Firebase: https://console.firebase.google.com/
- Play Console: https://play.google.com/console
- App Store Connect: https://appstoreconnect.apple.com/
- Flutter Docs: https://flutter.dev/docs

---

## 🎉 PARABÉNS!

Se você chegou até aqui, seu app Gimie está pronto e publicado! 🚀

**Próximos passos:**
1. Monitorar reviews de usuários
2. Responder feedback
3. Planejar próximas features
4. Atualizar regularmente

**Boa sorte com o Gimie! 💜**
