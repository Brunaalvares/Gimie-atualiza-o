# Correção: Impossibilidade de Seguir Usuários no App

## 🐛 Problema Identificado

Usuários não conseguiam seguir outros usuários no aplicativo Gimie. Quando tentavam clicar no botão "Seguir", a operação falhava silenciosamente ou mostrava um erro genérico.

## 🔍 Causa Raiz

O problema estava nas regras de segurança do Firestore (`firestore.rules`). As regras exigiam que qualquer atualização em um documento de usuário contivesse **todos os campos obrigatórios** (`email`, `name`, `username`, `createdAt`, `followingIds`).

Quando um usuário tenta seguir outro, o código faz uma atualização **parcial** do documento usando `FieldValue.arrayUnion`:

```dart
batch.update(
  _firestore.collection('users').doc(currentUserId),
  {
    'followingIds': FieldValue.arrayUnion([targetUserId])
  },
);
```

Como essa é uma atualização parcial (contendo apenas o campo `followingIds`), a validação `validUserDocument()` falhava porque não encontrava todos os campos obrigatórios no objeto `request.resource.data`.

## ✅ Solução Implementada

Adicionamos uma nova função auxiliar nas regras de segurança do Firestore:

```javascript
/// Atualização só de followingIds (seguir/deixar de seguir) — não exige revalidar o doc inteiro.
function onlyFollowingIdsChanged() {
  return request.resource.data.diff(resource.data).affectedKeys().hasOnly(['followingIds'])
    && request.resource.data.followingIds is list
    && request.resource.data.followingIds.size() <= 10000;
}
```

E modificamos a regra de atualização de usuários para permitir essa exceção:

```javascript
allow update: if isSelf(userId)
  && (
    onlyEmptyFoldersChanged()
    || onlyFollowingIdsChanged()  // ← Nova regra adicionada
    || (
      (!resource.data.keys().hasAll(['createdAt'])
          || request.resource.data.createdAt == resource.data.createdAt)
      && validUserDocument(request.resource.data, false)
    )
  );
```

## 🚀 Como Aplicar a Correção

### 1. Deploy das Novas Regras de Segurança

```bash
firebase deploy --only firestore:rules
```

### 2. Verificar no Console do Firebase

1. Acesse o [Firebase Console](https://console.firebase.google.com)
2. Selecione seu projeto
3. Vá em **Firestore Database** > **Regras**
4. Verifique se as novas regras foram aplicadas corretamente

### 3. Testar a Funcionalidade

Após aplicar as novas regras, teste a funcionalidade de seguir usuários:

1. Faça login no app
2. Vá para a tela "Seguir usuários" (ícone de pessoas no menu)
3. Busque um usuário
4. Clique em "Seguir"
5. Verifique se o botão muda para "Seguindo"
6. Verifique se o contador de "Seguindo" aumenta

## 📝 Arquivos Modificados

- **`firestore.rules`**: Adicionada função `onlyFollowingIdsChanged()` e atualizada regra de `users/{userId}` update

## 🔒 Segurança

A correção mantém todas as validações de segurança:

- ✅ Apenas o próprio usuário pode atualizar seus `followingIds`
- ✅ Validação de tipo (deve ser uma lista)
- ✅ Limite de tamanho (máximo 10.000 usuários seguidos)
- ✅ Apenas o campo `followingIds` pode ser modificado nesta operação

## 🧪 Impacto

Esta correção afeta **apenas** a funcionalidade de seguir/deixar de seguir usuários. Todas as outras operações de atualização de perfil continuam funcionando normalmente com suas validações completas.

## 📚 Funcionalidades Relacionadas

As seguintes telas e funcionalidades agora funcionarão corretamente:

- **`lib/screens/follow_users_screen.dart`**: Tela de buscar e seguir usuários
- **`lib/screens/user_profile_screen.dart`**: Botão "Seguir" no perfil de outros usuários
- **`lib/screens/follow_list_screen.dart`**: Lista de seguidores e seguindo
- **`lib/providers/auth_provider.dart`**: Método `toggleFollowUser()`
- **`lib/services/firebase_service.dart`**: Métodos `followUser()` e `unfollowUser()`

## 🎉 Resultado

Usuários agora podem:
- ✅ Seguir outros usuários
- ✅ Deixar de seguir usuários
- ✅ Ver lista de seguidores e seguindo
- ✅ Receber notificações quando alguém os segue
- ✅ Ver o feed social de produtos dos usuários que seguem

## 📞 Suporte

Se o problema persistir após aplicar esta correção:

1. Verifique se as regras foram realmente aplicadas no Firebase Console
2. Limpe o cache do app (logout + login)
3. Verifique os logs do Firebase Console para erros de permissão
4. Consulte a documentação em `FIREBASE_SECURITY.md`
