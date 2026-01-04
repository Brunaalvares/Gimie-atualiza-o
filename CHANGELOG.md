# 🔄 Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

## [1.0.0] - 2024-01-04

### ✨ Adicionado
- Splash screen com animação
- Autenticação com Firebase (Login/Cadastro)
- Feed de produtos com grid layout
- Sistema de busca de produtos
- Tela para adicionar produtos com upload de imagens
- Perfil de usuário com produtos criados
- Sistema de likes/favoritos
- Integração com API REST (Railway)
- Integração com Firebase (Auth, Firestore, Storage)
- Bottom navigation com FAB central
- Validação de formulários
- Gerenciamento de estado com Provider
- Suporte a imagens da galeria

### 🎨 Design
- Tema customizado com cores roxo (#8B7FB8) e vinho (#6B2C5C)
- UI/UX moderno e responsivo
- Cards de produtos com sombras e bordas arredondadas
- Animações e transições suaves

### 🔧 Técnico
- Arquitetura limpa com separação de camadas
- Models para Product e User
- Services para API e Firebase
- Providers para Auth e Product
- Configuração completa para Android e iOS
- Regras de segurança do Firebase
- Otimização de build para produção

### 📱 Plataformas
- Android (SDK 23+)
- iOS (12.0+)

### 🔐 Segurança
- Autenticação segura com Firebase Auth
- Validação de senha (maiúscula + caractere especial)
- Regras de segurança do Firestore
- ProGuard configurado para Android

### 🌐 API
- Integração com https://web-production-3495.up.railway.app/
- Endpoints para auth, products e users
- Fallback para Firebase quando API não disponível

## [Próximas versões]

### 📋 Planejado
- [ ] Notificações push
- [ ] Chat entre usuários
- [ ] Compartilhamento social
- [ ] Filtros avançados de busca
- [ ] Dark mode
- [ ] Internacionalização (i18n)
- [ ] Analytics e crashlytics
- [ ] Deep linking
- [ ] Wishlist compartilhada
- [ ] Comentários em produtos

---

Para mais detalhes sobre cada versão, consulte os commits do git.
