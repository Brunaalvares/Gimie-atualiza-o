# 🎯 Gimie - Connecting People Through Common Wishes

<div align="center">

![Gimie Logo](assets/images/icon.png)

**Descubra, compartilhe e realize seus desejos com a comunidade Gimie!**

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/Brunaalvares/Gimie-atualiza-o/releases/tag/v2.0.0)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B.svg?logo=flutter)](https://flutter.dev)
[![iOS](https://img.shields.io/badge/iOS-12.0+-000000.svg?logo=apple)](https://developer.apple.com/ios/)
[![API](https://img.shields.io/badge/API-Gimie%202.0-green.svg)](https://api2gimie.vercel.app)

</div>

## ✨ Principais Recursos

### 🎯 **Core Features**
- 📱 **Lista de Desejos Social**: Compartilhe seus produtos desejados
- 🔗 **Share Extension**: Adicione produtos de qualquer app iOS
- 🤖 **Scraping Automático**: Extração inteligente de dados de produtos
- 💱 **Conversão de Moedas**: Suporte para 8+ moedas em tempo real
- 🎨 **Interface Moderna**: Design intuitivo e responsivo
- 🔍 **Sugestões Inteligentes**: Descubra produtos por categoria

### 🚀 **Funcionalidades Avançadas**
- **iOS Share Extension**: Compartilhe de Safari, Chrome, lojas online
- **Multi-Currency**: BRL, USD, EUR, GBP, JPY, CAD, AUD, MXN
- **Real-time Scraping**: Extração automática de título, preço, imagem
- **Smart Categories**: Categorização automática de produtos
- **Social Features**: Sistema de likes e interações
- **Offline Support**: Cache inteligente para uso offline

## 📱 Screenshots

<div align="center">
<img src="screenshots/home.png" width="200" alt="Home Screen">
<img src="screenshots/add_product.png" width="200" alt="Add Product">
<img src="screenshots/share_extension.png" width="200" alt="Share Extension">
<img src="screenshots/currency_converter.png" width="200" alt="Currency Converter">
</div>

## 🛠️ Tecnologias

### **Frontend (Flutter)**
- **Flutter 3.0+** - Framework multiplataforma
- **Provider** - Gerenciamento de estado
- **HTTP/Dio** - Requisições de rede
- **Cached Network Image** - Cache de imagens
- **Image Picker** - Seleção de imagens
- **Shared Preferences** - Armazenamento local

### **Backend (API)**
- **Gimie API 2.0** - API de scraping e produtos
- **Node.js + Express** - Servidor backend
- **SQLite** - Banco de dados
- **Microlink API** - Scraping avançado
- **Exchange Rates API** - Conversão de moedas

### **iOS Native**
- **Swift** - Share Extension nativo
- **App Groups** - Compartilhamento entre apps
- **URL Schemes** - Deep linking

### **Firebase**
- **Authentication** - Sistema de login
- **Firestore** - Banco NoSQL
- **Storage** - Armazenamento de arquivos
- **Analytics** - Métricas de uso

## 🚀 Instalação e Setup

### **Pré-requisitos**
- Flutter 3.0+
- Xcode 14+ (para iOS)
- Apple Developer Account
- Firebase Project

### **1. Clone o Repositório**
```bash
git clone https://github.com/Brunaalvares/Gimie-atualiza-o.git
cd Gimie-atualiza-o
```

### **2. Instalar Dependências**
```bash
flutter pub get
cd ios && pod install && cd ..
```

### **3. Configurar Firebase**
```bash
# Configure o Firebase seguindo a documentação oficial
# Adicione os arquivos de configuração:
# - android/app/google-services.json
# - ios/Runner/GoogleService-Info.plist
```

### **4. Configurar Bundle IDs**
Edite os seguintes arquivos com seus Bundle IDs únicos:
- `ios/Runner.xcodeproj` - Target Runner
- `ios/ShareExtension` - Target ShareExtension
- Arquivos Swift e Dart conforme documentação

### **5. Executar o App**
```bash
flutter run
```

## 📋 Configuração Detalhada

### **iOS Share Extension**
1. Abra `ios/Runner.xcworkspace` no Xcode
2. Configure Bundle IDs únicos
3. Configure App Groups
4. Configure certificados de desenvolvimento
5. Consulte `SHARE_EXTENSION_SETUP.md` para detalhes

### **API Configuration**
```dart
// lib/config/api_config.dart
static const String baseUrl = 'https://api2gimie.vercel.app';
```

### **Bundle IDs (Exemplo)**
```
Main App: com.seudominio.gimie
Share Extension: com.seudominio.gimie.ShareExtension
App Group: group.com.seudominio.gimie.shareextension
```

## 🎯 Como Usar

### **1. Adicionar Produtos**
- **Via App**: Tela de adicionar produto com formulário completo
- **Via Share Extension**: Compartilhe de qualquer app iOS
- **Via URL**: Cole link e use extração automática

### **2. Share Extension**
1. Abra Safari, Chrome ou loja online
2. Toque no botão "Compartilhar"
3. Selecione "Gimie Share"
4. Dados são extraídos automaticamente
5. App abre com formulário pré-preenchido

### **3. Conversão de Moedas**
- Preços são detectados automaticamente
- Widget de conversão em tempo real
- Suporte para 8+ moedas principais
- Formatação correta por região

## 📚 Documentação

### **Guias Completos**
- 📱 [`SHARE_EXTENSION_SETUP.md`](SHARE_EXTENSION_SETUP.md) - Setup do Share Extension
- 🚀 [`APP_STORE_EXPORT_GUIDE.md`](APP_STORE_EXPORT_GUIDE.md) - Deploy na App Store
- 🔧 [`BUGFIXES_APPLIED.md`](BUGFIXES_APPLIED.md) - Correções implementadas
- 🌐 [`GIMIE_API_2_INTEGRATION.md`](GIMIE_API_2_INTEGRATION.md) - Integração com API 2.0
- 📖 [`SCRAPING_API_IMPLEMENTATION.md`](SCRAPING_API_IMPLEMENTATION.md) - API de Scraping

### **Scripts Úteis**
```bash
# Preparar para App Store
./scripts/prepare_app_store.sh

# Build e export automatizado
./scripts/build_and_export.sh

# Testar conexão com API
dart test_api_connection.dart
```

## 🔧 Desenvolvimento

### **Estrutura do Projeto**
```
lib/
├── config/          # Configurações da API
├── models/          # Modelos de dados
├── providers/       # Gerenciamento de estado
├── screens/         # Telas do app
├── services/        # Serviços (API, Firebase, etc.)
├── utils/           # Utilitários e helpers
└── widgets/         # Widgets reutilizáveis

ios/
├── Runner/          # App principal iOS
└── ShareExtension/  # Share Extension nativo

scripts/             # Scripts de automação
```

### **Comandos de Desenvolvimento**
```bash
# Executar em modo debug
flutter run

# Build para produção
flutter build ios --release

# Executar testes
flutter test

# Analisar código
flutter analyze

# Limpar projeto
flutter clean
```

## 🌟 Funcionalidades por Versão

### **v2.0.0 (Atual)**
- ✅ iOS Share Extension completo
- ✅ Gimie API 2.0 integrada
- ✅ Conversão de moedas em tempo real
- ✅ Scraping automático melhorado
- ✅ Sistema de debug avançado
- ✅ Pronto para App Store

### **v1.0.0**
- ✅ App Flutter básico
- ✅ Firebase integrado
- ✅ Sistema de autenticação
- ✅ CRUD de produtos
- ✅ Interface responsiva

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para detalhes.

## 👥 Equipe

- **Bruna Alvares** - Desenvolvimento Principal - [@Brunaalvares](https://github.com/Brunaalvares)

## 🙏 Agradecimentos

- [Flutter Team](https://flutter.dev) - Framework incrível
- [Firebase](https://firebase.google.com) - Backend as a Service
- [Gimie API 2.0](https://github.com/Giulia3112/Gimie-API-2.0) - API de scraping
- Comunidade Flutter Brasil

## 📞 Suporte

- 📧 Email: suporte@gimie.app
- 🐛 Issues: [GitHub Issues](https://github.com/Brunaalvares/Gimie-atualiza-o/issues)
- 📖 Docs: [Documentação Completa](https://github.com/Brunaalvares/Gimie-atualiza-o/wiki)

---

<div align="center">

**Feito com ❤️ por [Bruna Alvares](https://github.com/Brunaalvares)**

[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Brunaalvares)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/brunaalvares)

</div>