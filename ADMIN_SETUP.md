# Configuração de Administradores Trends

Este documento explica como adicionar usuários como administradores da funcionalidade Trends do aplicativo Gimie.

## O que é um Admin Trends?

Administradores Trends têm acesso à tela de administração onde podem:
- Criar e editar pastas de tendências
- Adicionar imagens mood board (1080×1080px)
- Criar cards de produtos com links
- Gerenciar todo o conteúdo da aba Trends

## Como Adicionar um Admin

### Opção 1: Via Console do Firebase (Recomendado)

1. Acesse o [Console do Firebase](https://console.firebase.google.com/)
2. Selecione o projeto Gimie
3. No menu lateral, clique em **Firestore Database**
4. Clique no botão **+ Iniciar coleção** (se ainda não houver a coleção `admins`)
   - Nome da coleção: `admins`
   - ID do documento: Cole o UID do usuário (ex: `TqQzNUcc4ThA7tuTpSrrkq4yaaz1`)
   - Adicione um campo:
     - Nome do campo: `active`
     - Tipo: `boolean`
     - Valor: `true`
   - Clique em **Salvar**

5. Se a coleção `admins` já existir:
   - Clique na coleção `admins`
   - Clique em **+ Adicionar documento**
   - ID do documento: Cole o UID do usuário
   - Adicione o campo `active: true` (boolean)
   - Clique em **Salvar**

### Opção 2: Via Script (Requer configuração local)

Execute o script auxiliar:

```bash
dart run scripts/add_admin.dart
```

**Nota:** Você precisará editar o script para adicionar diferentes UIDs.

## Admin Atual Configurado

- UID: `TqQzNUcc4ThA7tuTpSrrkq4yaaz1`
- Status: Ativo

## Como Encontrar o UID de um Usuário

1. Acesse o Console do Firebase
2. Vá em **Authentication**
3. Encontre o usuário na lista
4. O UID está na primeira coluna ("Identificador do usuário")

## Removendo um Admin

Para remover privilégios de admin:

1. Acesse Firestore Database no Console do Firebase
2. Navegue até `admins/{uid}`
3. Opção A: Altere o campo `active` para `false`
4. Opção B: Delete o documento completamente

## Verificação de Permissões

O aplicativo verifica as permissões da seguinte forma:

```dart
// No código (lib/services/trends_service.dart)
Future<bool> isCurrentUserAdmin() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final snap = await FirebaseFirestore.instance
      .collection('admins')
      .doc(uid)
      .get();
  return snap.data()?['active'] == true;
}
```

## Segurança

As regras do Firestore devem garantir que:
- Apenas admins podem criar/editar conteúdo na coleção `trend_boards`
- Apenas admins podem fazer upload em `Storage/trends/`
- Usuários comuns podem apenas ler o conteúdo

Certifique-se de que as regras em `firestore.rules` e `storage.rules` estão configuradas corretamente.

## Acessando a Tela de Admin

Uma vez configurado como admin, o usuário pode acessar a tela de administração através do aplicativo. A verificação é feita automaticamente e usuários sem permissão serão redirecionados.
