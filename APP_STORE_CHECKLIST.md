# App Store Connect - Checklist Completo (Gimie)

Este guia cobre todos os arquivos e informações necessários para publicar o app na App Store.

## 📱 1. Screenshots (Capturas de Tela) - OBRIGATÓRIO

### Requisitos da Apple:

#### iPhone 6.7" (Obrigatório)
- **Resolução**: 1320 × 2868 pixels
- **Dispositivos**: iPhone 16 Pro Max, 15 Pro Max, 14 Pro Max
- **Quantidade**: Mínimo 3, Máximo 10
- **Formato**: PNG ou JPEG

#### iPhone 5.5" (Obrigatório)
- **Resolução**: 1242 × 2208 pixels  
- **Dispositivos**: iPhone 8 Plus, 7 Plus
- **Quantidade**: Mínimo 3, Máximo 10
- **Formato**: PNG ou JPEG

### Como Gerar:

```bash
# Execute o script automático:
bash scripts/setup_e_screenshots.sh
```

Os screenshots serão salvos em: `screenshots/app_store/`

### Recomendações:
- [ ] Capture as principais telas do app:
  - Tela inicial/Splash
  - Tela de login/cadastro
  - Home feed de produtos
  - Tela de perfil
  - Tela de adicionar produto
  - Tela de trends (destaque da funcionalidade)
- [ ] Mantenha a interface em português (Brasil)
- [ ] Mostre conteúdo real (não placeholder)
- [ ] Use modo claro (light mode)

---

## 🎬 2. App Preview (Vídeo) - OPCIONAL

- **Duração**: 15 a 30 segundos
- **Resolução**: Mesma dos screenshots
- **Formato**: .mov ou .mp4
- **Tamanho máximo**: 500 MB
- **Orientação**: Vertical (portrait)

**Dica**: Grave diretamente do simulador com QuickTime Player

---

## 🎨 3. Ícone do App - OBRIGATÓRIO

- **Tamanho**: 1024 × 1024 pixels
- **Formato**: PNG (sem alpha/transparência)
- **Localização no projeto**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`

✅ Seu projeto já tem o ícone configurado!

---

## 📝 4. Informações de Texto - OBRIGATÓRIO

### Nome do App
- [ ] **Nome**: Gimie
- [ ] Máximo: 30 caracteres

### Legenda (Subtitle)
- [ ] **Exemplo**: "Organize seus desejos de compra"
- [ ] Máximo: 30 caracteres

### Descrição
- [ ] Máximo: 4.000 caracteres
- [ ] Inclua:
  - O que o app faz
  - Principais funcionalidades
  - Diferenciais

**Exemplo de descrição**:
```
Gimie é o app perfeito para organizar seus produtos favoritos e descobrir tendências!

🛍️ PRINCIPAIS FUNCIONALIDADES:
• Salve produtos de qualquer loja da internet
• Organize em pastas personalizadas
• Acompanhe preços e variações de moeda
• Descubra tendências curadas pela equipe Gimie
• Siga outros usuários e veja seus produtos favoritos
• Compartilhe suas listas com amigos

✨ RECURSOS ESPECIAIS:
• Scraping automático de informações do produto
• Conversor de moedas integrado
• Interface moderna e intuitiva
• Sincronização em tempo real
• Notificações de curtidas e novos seguidores

📱 ORGANIZE SEUS DESEJOS:
Crie suas próprias pastas ou use as sugestões automáticas. 
Nunca mais perca aquele produto que você viu e adorou!

🔥 DESCUBRA TENDÊNCIAS:
Acesse a aba Trends e veja as curadoras especiais da equipe Gimie 
com produtos selecionados e mood boards inspiradores.

Baixe agora e comece a organizar seus desejos de compra!
```

### Palavras-chave (Keywords)
- [ ] Máximo: 100 caracteres (separados por vírgula)
- [ ] **Exemplos**: compras,lista,wishlist,produtos,tendencias,moda,organizacao,desejos

### URL de Suporte
- [ ] URL onde usuários podem obter suporte
- [ ] Exemplo: https://gimie.com/suporte ou email

### URL de Marketing (Opcional)
- [ ] Site do app
- [ ] Exemplo: https://gimie.com

### Política de Privacidade
- [ ] **URL pública obrigatória**
- [ ] Deve estar hospedada e acessível
- [ ] Exemplo: https://gimie.com/privacy

---

## 🏷️ 5. Categoria e Classificação

### Categoria Principal
- [ ] **Recomendado**: Shopping ou Lifestyle

### Categoria Secundária (Opcional)
- [ ] Escolher uma segunda categoria

### Classificação Etária
- [ ] Preencher questionário da Apple
- [ ] Provável resultado: 4+ ou 9+

---

## 📋 6. Informações de Copyright e Contato

- [ ] **Copyright**: © 2026 Gimie
- [ ] **Nome de contato**: Seu nome
- [ ] **Email de contato**: seuemail@exemplo.com
- [ ] **Telefone de contato**: Seu telefone

---

## 🚀 7. Build e Upload

### Preparar o Build:

```bash
# 1. Limpar builds anteriores
flutter clean

# 2. Obter dependências
flutter pub get

# 3. Aumentar versão no pubspec.yaml
# version: 1.0.0+1 (formato: versionName+buildNumber)

# 4. Build para App Store
flutter build ios --release

# 5. Abrir no Xcode para archive
open ios/Runner.xcworkspace
```

### No Xcode:
1. Selecione "Any iOS Device (arm64)"
2. Menu: **Product** → **Archive**
3. Após concluir, clique em **Distribute App**
4. Escolha **App Store Connect**
5. Siga o assistente para upload

### Ou use o script:
```bash
bash scripts/prepare_app_store.sh
```

---

## ✅ 8. Checklist Final Antes de Enviar

### Técnico:
- [ ] App compila sem erros
- [ ] Todos os testes passam
- [ ] Firebase configurado corretamente
- [ ] API de produção está funcionando
- [ ] Testado em dispositivo físico
- [ ] Não há crashes na abertura

### Visual:
- [ ] Screenshots capturados (6.7" e 5.5")
- [ ] Ícone 1024×1024 correto
- [ ] Todas as telas importantes foram capturadas

### Documentação:
- [ ] Descrição completa e atraente
- [ ] Palavras-chave relevantes
- [ ] URL de privacidade ativa
- [ ] URL de suporte configurada

### Legal:
- [ ] Copyright definido
- [ ] Contatos preenchidos
- [ ] Classificação etária apropriada

---

## 📤 9. Processo de Submissão

1. Acesse [App Store Connect](https://appstoreconnect.apple.com/)
2. Clique em **"+ Novo App"** ou selecione app existente
3. Preencha todas as informações acima
4. Faça upload dos screenshots
5. Selecione o build que você enviou via Xcode
6. Preencha "O que há de novo nesta versão"
7. Clique em **"Enviar para Revisão"**

### Tempo de Revisão:
- Geralmente: 1-3 dias úteis
- Pode levar até 1 semana em períodos de alto volume

---

## 🎯 10. Após a Publicação

- [ ] Monitorar reviews e responder
- [ ] Acompanhar Analytics no App Store Connect
- [ ] Verificar crashes no Firebase Crashlytics
- [ ] Preparar próximas atualizações

---

## 📞 Suporte

Se tiver dúvidas sobre algum passo:
- Documentação Apple: https://developer.apple.com/app-store/submitting/
- Guidelines: https://developer.apple.com/app-store/review/guidelines/

---

## 🔄 Para Próximas Versões

1. Aumentar o build number no `pubspec.yaml`
2. Gerar novo build
3. Upload via Xcode
4. Atualizar "O que há de novo"
5. Enviar para revisão
