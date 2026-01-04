# Gimie

**Connecting people through common wishes**

Um aplicativo mobile para compartilhar e descobrir produtos que você deseja, conectando pessoas através de interesses comuns.

## 🚀 Características

- ✨ Feed de produtos com desejos de outros usuários
- 🔍 Busca de produtos
- ➕ Adicionar produtos com imagens
- ❤️ Sistema de likes
- 👤 Perfil de usuário personalizado
- 🔐 Autenticação segura com Firebase
- 🌐 Integração com API REST

## 🏗️ Tecnologias

- **Flutter** - Framework multiplataforma
- **Firebase** - Backend (Auth, Firestore, Storage)
- **Provider** - Gerenciamento de estado
- **Railway API** - Backend REST

## 📦 Instalação

### Pré-requisitos

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / Xcode
- Firebase CLI
- Node.js (para Firebase CLI)

### Passos

1. Clone o repositório:
```bash
git clone <seu-repositorio>
cd gimie
```

2. Instale as dependências:
```bash
flutter pub get
```

3. Configure o Firebase:
```bash
flutterfire configure --project=gimie-launch
```

4. Para iOS, instale os pods:
```bash
cd ios
pod install
cd ..
```

5. Execute o aplicativo:
```bash
flutter run
```

## 🔧 Configuração

### Firebase

1. Crie um projeto no [Firebase Console](https://console.firebase.google.com/)
2. Habilite Authentication (Email/Password)
3. Habilite Firestore Database
4. Habilite Firebase Storage
5. Baixe os arquivos de configuração:
   - `google-services.json` para Android
   - `GoogleService-Info.plist` para iOS

### API

A API está configurada em `lib/config/api_config.dart`:
```dart
static const String baseUrl = 'https://web-production-3495.up.railway.app';
```

## 📱 Estrutura do Projeto

```
lib/
├── config/              # Configurações (API, Firebase)
├── models/              # Modelos de dados
├── providers/           # State management
├── screens/             # Telas do app
├── services/            # Serviços (API, Firebase)
├── widgets/             # Componentes reutilizáveis
└── main.dart            # Ponto de entrada
```

## 🎨 Design

- **Cores principais:**
  - Primary: `#8B7FB8` (Roxo)
  - Secondary: `#6B2C5C` (Vinho)
  - Background: `#F5F3E8` (Bege claro)

## 📲 Deploy

Veja o guia completo de deploy em [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

### Quick Start

**Android:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## 🧪 Testes

```bash
# Executar todos os testes
flutter test

# Análise de código
flutter analyze

# Verificar configuração
flutter doctor
```

## 📄 Licença

Copyright © 2024 Gimie. Todos os direitos reservados.

## 🤝 Contribuindo

Este é um projeto privado. Para contribuir, entre em contato com a equipe de desenvolvimento.

## 📞 Suporte

Para dúvidas e suporte, entre em contato através de:
- Email: [seu-email]
- Website: [seu-website]

---

Desenvolvido com ❤️ usando Flutter
