# 🔍 Diagnóstico: Trends e Badges não aparecem

## Checklist de Verificação

### 1️⃣ Verificar Deploy dos Índices Firestore

**No Firebase Console:**
- Acesse: https://console.firebase.google.com/project/gimie-launch/firestore/indexes
- Verifique se os índices estão **"Enabled"** (verde):
  - `mood_images` (Collection group) → sortOrder ASC
  - `trend_products` (Collection group) → sortOrder ASC
  
⚠️ Se aparecerem como "Building" (amarelo), aguarde até ficarem verdes.

### 2️⃣ Verificar se há Dados no Firestore

**No Firebase Console → Firestore Database:**

#### Para Trends:
```
✓ Existe a collection `trend_boards`?
✓ Há documentos dentro de `trend_boards`?
✓ Cada board tem subcollections `mood_images` ou `trend_products`?
✓ Os campos têm `sortOrder` definido?
```

#### Para Badges:
```
✓ Existe `users/{userId}/badge_progress`?
✓ O usuário logado tem documentos de badges?
```

### 3️⃣ Verificar App Atualizado

**No dispositivo/emulador:**
```bash
# Certifique-se de que o app está usando o código mais recente:
1. Feche o app completamente
2. Rode: flutter clean
3. Rode: flutter pub get
4. Rode: flutter run --release (ou reconstrua o app)
```

### 4️⃣ Verificar Logs de Erro

**Adicione logs temporários no código:**

No arquivo `lib/screens/trends_screen.dart`, após a linha 32, verifique se você vê logs assim:

```dart
debugPrint('=== TRENDS DEBUG ===');
debugPrint('Boards count: ${boards.length}');
debugPrint('Products count: ${allProducts.length}');
debugPrint('Filtered products: ${products.length}');
```

### 5️⃣ Verificar Autenticação

**O usuário está autenticado?**
```dart
// Adicione temporariamente no initState de TrendsScreen:
debugPrint('Current User: ${_firebaseService.currentUser?.uid}');
debugPrint('Is Authenticated: ${_firebaseService.currentUser != null}');
```

## 🚨 Problemas Comuns e Soluções

### Problema 1: "Nenhum dado aparece no Trends"
**Possível causa:** Não há trend_boards criados no Firestore
**Solução:** 
1. Faça login como admin
2. Crie um board de teste na tela de admin do Trends

### Problema 2: "Badges não carregam"
**Possível causa:** Usuário não tem badge_progress inicializado
**Solução:** 
```dart
// O sistema deveria criar automaticamente, mas force uma sincronização:
await BadgesService.instance.evaluateAndSync(userId);
```

### Problema 3: "App crasha ao abrir Trends"
**Possível causa:** Erro não capturado
**Solução:** Verifique os logs do Flutter:
```bash
flutter logs
# ou
adb logcat | grep flutter
```

### Problema 4: "Índices ainda em Building"
**Solução:** Aguarde. Índices podem levar 5-15 minutos para ficarem prontos.

## 🔧 Script de Teste Rápido

Execute este comando para verificar se o deploy foi feito:
```bash
cd /caminho/para/Gimie-atualiza-o
git status
git log -1 --oneline
```

Deve mostrar:
```
7dab0f3 fix: add error handling and null safety for trends and badges
```

## 📱 Teste Manual

1. **Abra o app**
2. **Vá até a aba Trends**
3. **Observe o que acontece:**
   - ⭕ Tela em branco?
   - ⭕ Loading infinito?
   - ⭕ Mensagem de erro?
   - ⭕ "Em breve: curadoria Gimie"?

4. **Vá até Profile → Badges**
5. **Observe:**
   - ⭕ Loading infinito?
   - ⭕ Lista vazia?
   - ⭕ Erro vermelho?

## 📞 Me informe:

Responda estas perguntas para eu ajudar melhor:

1. **O que aparece exatamente?**
   - Trends: [ tela em branco / loading / erro / "em breve" ]
   - Badges: [ loading / vazio / erro ]

2. **Os índices Firestore estão "Enabled"?** [ sim / não / ainda building ]

3. **Há dados em trend_boards no Firestore?** [ sim / não / não sei verificar ]

4. **O app foi reconstruído após o pull?** [ sim / não ]

5. **Qual plataforma está testando?** [ iOS / Android / Ambos ]
