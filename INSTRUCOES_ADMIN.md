# Como Configurar Admin Trends - Instruções Rápidas

## UID do Admin
```
TqQzNUcc4ThA7tuTpSrrkq4yaaz1
```

## Passos para Configurar

### 1. Acesse o Console do Firebase
1. Vá em https://console.firebase.google.com/
2. Selecione o projeto Gimie

### 2. Configure o Firestore
1. No menu lateral, clique em **Firestore Database**
2. Clique no botão **+ Iniciar coleção** (se não houver coleção `admins`)
   - Nome da coleção: `admins`
   - Clique em **Próxima**
3. Configure o primeiro documento:
   - **ID do documento**: `TqQzNUcc4ThA7tuTpSrrkq4yaaz1`
   - Adicione um campo:
     - Campo: `active`
     - Tipo: `boolean`
     - Valor: ✓ (marcado/true)
   - Clique em **Salvar**

### 3. Teste no App
1. Faça login no app com a conta que tem o UID `TqQzNUcc4ThA7tuTpSrrkq4yaaz1`
2. Vá até a aba **Trends**
3. No canto superior direito deve aparecer um ícone de edição ✏️
4. Clique nele para acessar a tela de admin

## Estrutura no Firestore

```
admins/
  └── TqQzNUcc4ThA7tuTpSrrkq4yaaz1/
      └── active: true
```

## Como Funciona

O aplicativo verifica automaticamente se o usuário logado possui um documento na coleção `admins` com o campo `active: true`. Se sim:

- O botão de editar aparece na aba Trends
- O usuário pode criar e editar pastas de tendências
- O usuário pode adicionar imagens mood board
- O usuário pode criar cards de produtos com links

## Segurança

As regras do Firestore garantem que:
- Apenas o próprio usuário pode ler seu documento admin
- A criação do documento admin só pode ser feita via Console Firebase (não pelo app)
- Apenas usuários com `admins/{uid}.active = true` podem editar conteúdo Trends

## Para Adicionar Mais Admins

Repita o processo acima criando novos documentos na coleção `admins`:
1. Obtenha o UID do usuário em Authentication
2. Crie documento `admins/{novo-uid}`
3. Adicione campo `active: true`

## Para Remover Admin

1. Vá até `admins/{uid}` no Firestore
2. Altere `active` para `false` OU delete o documento
