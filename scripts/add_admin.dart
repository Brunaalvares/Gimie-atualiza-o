import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

/// Script para adicionar um usuário como admin do Trends.
/// 
/// Uso:
/// ```
/// dart run scripts/add_admin.dart
/// ```
/// 
/// Este script cria um documento em `admins/{uid}` com `{ "active": true }`.
void main() async {
  print('🔧 Configurando Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final db = FirebaseFirestore.instance;
  
  // UID do usuário que terá acesso admin
  const adminUid = 'TqQzNUcc4ThA7tuTpSrrkq4yaaz1';
  
  print('📝 Adicionando usuário como admin...');
  print('   UID: $adminUid');
  
  try {
    await db.collection('admins').doc(adminUid).set({
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    print('✅ Admin configurado com sucesso!');
    print('');
    print('O usuário com UID $adminUid agora tem acesso à página de admin Trends.');
    print('');
    print('Para adicionar mais admins, edite este script ou acesse o Console do Firebase:');
    print('Firestore Database > admins > [Criar documento com UID do usuário]');
    
  } catch (e) {
    print('❌ Erro ao configurar admin: $e');
    print('');
    print('Certifique-se de que:');
    print('1. O Firebase está configurado corretamente');
    print('2. Você tem permissões para escrever no Firestore');
    print('3. As regras do Firestore permitem essa operação');
  }
}
