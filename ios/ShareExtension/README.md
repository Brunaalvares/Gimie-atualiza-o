# Share Extension - Gimie iOS

Este diretório contém a implementação do Share Extension para o app Gimie no iOS, permitindo que os usuários compartilhem conteúdo de outros apps diretamente para o Gimie.

## Configuração no Xcode

Para que o Share Extension funcione corretamente, você precisa configurar alguns itens no Xcode:

### 1. Adicionar o Target do Share Extension

1. Abra o projeto no Xcode (`ios/Runner.xcworkspace`)
2. Clique no projeto na navegação à esquerda
3. Clique no botão "+" na seção "TARGETS"
4. Selecione "Share Extension" em "Application Extension"
5. Configure:
   - **Product Name**: `ShareExtension`
   - **Bundle Identifier**: `com.gimie.app.ShareExtension` (substitua por seu bundle ID + .ShareExtension)
   - **Language**: Swift
   - **Use Core Data**: Não

### 2. Configurar App Groups

1. Selecione o target principal "Runner"
2. Vá para "Signing & Capabilities"
3. Clique em "+ Capability" e adicione "App Groups"
4. Adicione o grupo: `group.com.gimie.shareextension`

5. Repita o processo para o target "ShareExtension"
6. Adicione o mesmo grupo: `group.com.gimie.shareextension`

### 3. Configurar Bundle Identifiers

Certifique-se de que os Bundle Identifiers estejam corretos:

- **Runner**: `com.gimie.app` (ou seu bundle ID)
- **ShareExtension**: `com.gimie.app.ShareExtension`

### 4. Adicionar os Arquivos

Certifique-se de que os seguintes arquivos estejam adicionados ao target ShareExtension:

- `ShareViewController.swift`
- `MainInterface.storyboard`
- `Info.plist`

### 5. Configurar Deployment Target

Certifique-se de que ambos os targets tenham o mesmo Deployment Target (iOS 12.0 ou superior).

## Como Funciona

1. **Compartilhamento**: Usuário compartilha conteúdo de outro app
2. **Processamento**: Share Extension processa o conteúdo (texto, URL, imagem)
3. **Armazenamento**: Dados são salvos no App Group UserDefaults
4. **Abertura**: App principal é aberto via URL scheme (`gimie://share`)
5. **Integração**: Flutter carrega o conteúdo compartilhado na tela de adicionar produto

## Tipos de Conteúdo Suportados

- **Texto**: Descrições, comentários
- **URLs**: Links de produtos
- **Imagens**: Fotos de produtos (até 10 imagens)
- **Vídeos**: Vídeos curtos (1 vídeo)

## Troubleshooting

### Share Extension não aparece
- Verifique se o target está sendo compilado
- Confirme as configurações de App Groups
- Verifique o Info.plist do Share Extension

### App não abre após compartilhar
- Confirme o URL scheme no Info.plist do app principal
- Verifique a implementação do AppDelegate

### Conteúdo não é carregado
- Verifique os App Groups
- Confirme a implementação do método nativo no AppDelegate
- Verifique os logs do console

## Testando

1. Compile e instale o app no dispositivo
2. Abra outro app (Safari, Fotos, etc.)
3. Toque em "Compartilhar"
4. Procure por "Gimie Share" na lista
5. Toque para compartilhar
6. O app Gimie deve abrir com o conteúdo pré-preenchido