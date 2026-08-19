# ❓ Dois Bancos de Dados - Qual Atualizar?

## 🔍 Identificando os Bancos

Quando você acessa o Firebase Console, pode ver dois tipos de banco:

### 1. 🔥 **Firestore Database** ← **ESTE É O CORRETO!**
- **Nome no Console**: "Firestore Database" ou "Cloud Firestore"
- **Ícone**: 📊 Base de dados com ícone de nuvem
- **Tipo**: Banco NoSQL (documentos e coleções)
- **Uso no Gimie**: 
  - ✅ Usuários
  - ✅ Produtos
  - ✅ Notificações
  - ✅ Seguir/Seguidores
  - ✅ Likes

### 2. ⚡ **Realtime Database** ← **NÃO USAR**
- **Nome no Console**: "Realtime Database"
- **Ícone**: 🌳 Árvore de dados
- **Tipo**: Banco JSON em tempo real
- **Uso no Gimie**: ❌ **NÃO É UTILIZADO**

---

## ✅ Passo a Passo Correto

### 1. Acesse o Firebase Console
```
https://console.firebase.google.com
```

### 2. Selecione o Projeto
- **Projeto**: `gimie-launch`
- Clique no nome do projeto no topo da página

### 3. Identifique o Firestore Database
No menu lateral esquerdo, procure por:

```
📊 Firestore Database    ← ESTE AQUI!
   ├── Data
   ├── Regras           ← Clique aqui
   ├── Índices
   └── Uso

⚡ Realtime Database     ← Ignore este
```

### 4. Atualize as Regras
1. Clique em **Firestore Database** (o primeiro da lista)
2. Clique na aba **Regras** (ou **Rules**)
3. Você verá um editor de código
4. Substitua TODO o conteúdo pelo novo `firestore.rules`
5. Clique em **Publicar** (Publish)

---

## 🎯 Como Confirmar que é o Firestore Correto?

### Verificação Visual:

1. **URL do navegador** deve conter:
   ```
   firebase.google.com/project/gimie-launch/firestore
   ```

2. **Estrutura de dados** deve mostrar collections como:
   ```
   📁 users
   📁 products
   📁 admins
   📁 trend_boards
   📁 usernames
   ```

3. **Aba de Regras** deve começar com:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
   ```

---

## ❌ Se Você Vir Isto, PARE!

Se você vir:
- "Realtime Database" no título
- Estrutura em formato de árvore JSON (não collections)
- Regras começando com `"rules": {`
- URL com `/database/` em vez de `/firestore/`

**→ Você está no banco ERRADO!** Volte e encontre o Firestore Database.

---

## 🤔 Por Que Dois Bancos?

O Firebase oferece dois tipos de banco de dados:

| Característica | Firestore Database ✅ | Realtime Database ❌ |
|----------------|----------------------|----------------------|
| **Usado no Gimie** | ✅ SIM | ❌ NÃO |
| **Estrutura** | Collections/Documents | JSON Tree |
| **Regras** | `firestore.rules` | `database.rules.json` |
| **Melhor para** | Apps complexos | Apps simples/legados |

O projeto Gimie usa **exclusivamente o Firestore Database**.

---

## 📸 Screenshots de Referência

### ✅ CORRETO - Firestore Database:
```
┌─────────────────────────────────────────┐
│ Firestore Database                  ⚙️  │
├─────────────────────────────────────────┤
│ 📊 Data  | 📋 Regras | 📊 Índices | 📈  │
├─────────────────────────────────────────┤
│ Collections:                            │
│ ├── 📁 users                            │
│ ├── 📁 products                         │
│ ├── 📁 admins                           │
│ └── 📁 usernames                        │
└─────────────────────────────────────────┘
```

### ❌ ERRADO - Realtime Database:
```
┌─────────────────────────────────────────┐
│ Realtime Database               🌳      │
├─────────────────────────────────────────┤
│ 📄 Dados  | 📋 Regras | ⚙️              │
├─────────────────────────────────────────┤
│ Structure:                              │
│ 🌳 gimie-launch-default-rtdb           │
│    └── (provavelmente vazio)           │
└─────────────────────────────────────────┘
```

---

## 🚀 Resumo Rápido

**ONDE ATUALIZAR:**
```
Firebase Console 
  → Projeto: gimie-launch
    → Firestore Database (📊 não ⚡)
      → Aba "Regras"
        → Colar novo firestore.rules
          → Publicar
```

**NÃO ATUALIZAR:**
- ❌ Realtime Database
- ❌ Nenhum outro banco de dados

---

## 💡 Dica Extra

Se o seu projeto **não tem** Realtime Database configurado, você verá apenas o Firestore Database no menu. Nesse caso, não há confusão possível! Atualize o único banco que aparece.

---

## 📞 Ainda com Dúvida?

Se ainda não tiver certeza, tire um screenshot do menu lateral do Firebase Console e compartilhe. Posso confirmar qual é o correto!
