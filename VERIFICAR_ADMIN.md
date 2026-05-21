# Verificação Manual da Configuração de Admin

## UID a Verificar
```
TqQzNUcc4ThA7tuTpSrrkq4yaaz1
```

## Método 1: Verificar no Console do Firebase (Mais Simples)

1. Acesse https://console.firebase.google.com/
2. Selecione o projeto Gimie
3. No menu lateral, clique em **Firestore Database**
4. Procure pela coleção `admins`
5. Dentro dela, procure pelo documento `TqQzNUcc4ThA7tuTpSrrkq4yaaz1`
6. Verifique se tem o campo `active: true`

### ✅ Se o documento existe com `active: true`:
- A configuração está correta!
- O usuário pode fazer login no app e acessar a área admin

### ❌ Se o documento NÃO existe ou está diferente:
- Siga as instruções em INSTRUCOES_ADMIN.md para criar o documento

## Método 2: Verificar no App

1. Faça login no app com a conta que tem o UID `TqQzNUcc4ThA7tuTpSrrkq4yaaz1`
2. Vá até a aba **Trends** (ícone de foguete ou trends na navegação)
3. Olhe no canto superior direito da tela

### ✅ Se aparecer um ícone de edição (✏️):
- A configuração está funcionando!
- Clique no ícone para acessar a tela de admin

### ❌ Se NÃO aparecer o ícone de edição:
- O documento admin não foi criado corretamente
- Siga as instruções para criar no Console do Firebase

## Estrutura Esperada no Firestore

```
📁 Firestore Database
  └── 📂 admins (coleção)
      └── 📄 TqQzNUcc4ThA7tuTpSrrkq4yaaz1 (documento)
          └── active: true (campo boolean)
```

## Como Criar o Documento (se ainda não existe)

### Via Console Firebase:

1. **Se a coleção `admins` NÃO existe:**
   - Clique em "+ Iniciar coleção"
   - Nome da coleção: `admins`
   - ID do primeiro documento: `TqQzNUcc4ThA7tuTpSrrkq4yaaz1`
   - Adicione campo: `active` (boolean) = `true`
   - Clique em "Salvar"

2. **Se a coleção `admins` já existe:**
   - Clique na coleção `admins`
   - Clique em "+ Adicionar documento"
   - ID do documento: `TqQzNUcc4ThA7tuTpSrrkq4yaaz1`
   - Adicione campo: `active` (boolean) = `true`
   - Clique em "Salvar"

## Verificação de Permissões

O aplicativo faz a verificação assim:

```dart
// Verifica se existe: admins/{uid}.active == true
final isAdmin = await FirebaseFirestore.instance
    .collection('admins')
    .doc(uid)
    .get()
    .then((doc) => doc.data()?['active'] == true);
```

## Troubleshooting

### Problema: Criei o documento mas o botão não aparece
**Solução:**
1. Faça logout e login novamente no app
2. Force o fechamento do app e abra novamente
3. Verifique se o UID da conta logada é exatamente: `TqQzNUcc4ThA7tuTpSrrkq4yaaz1`

### Problema: Como descobrir o UID de um usuário?
**Solução:**
1. Console Firebase → Authentication
2. Procure o usuário na lista
3. O UID está na primeira coluna

### Problema: O botão aparece mas dá erro ao clicar
**Solução:**
1. Verifique as regras do Firestore em firestore.rules
2. Certifique-se de que as regras para `trend_boards` estão corretas
3. Verifique se o Storage também tem as regras corretas em storage.rules

## Contato de Suporte

Se precisar de ajuda adicional, verifique:
- `INSTRUCOES_ADMIN.md` - Instruções rápidas
- `ADMIN_SETUP.md` - Documentação completa
- `firestore.rules` - Regras de segurança do Firestore
