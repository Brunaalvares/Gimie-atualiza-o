import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

/// Script para verificar se um usuário está configurado como admin.
/// 
/// Uso:
/// ```
/// dart run scripts/verify_admin.dart
/// ```
void main() async {
  print('🔍 Verificando configuração de admin...\n');
  
  try {
    print('📱 Inicializando Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado\n');

    final db = FirebaseFirestore.instance;
    
    // UID do usuário que deve ter acesso admin
    const adminUid = 'TqQzNUcc4ThA7tuTpSrrkq4yaaz1';
    
    print('🔎 Buscando documento: admins/$adminUid');
    
    final docSnapshot = await db.collection('admins').doc(adminUid).get();
    
    print('─────────────────────────────────────────────');
    
    if (!docSnapshot.exists) {
      print('❌ DOCUMENTO NÃO ENCONTRADO\n');
      print('O documento admins/$adminUid não existe no Firestore.');
      print('\n📋 Para criar o documento:');
      print('1. Acesse o Console do Firebase');
      print('2. Vá em Firestore Database');
      print('3. Crie a coleção "admins" (se não existir)');
      print('4. Adicione um documento com ID: $adminUid');
      print('5. Adicione o campo: active = true (boolean)');
      return;
    }
    
    print('✅ DOCUMENTO ENCONTRADO\n');
    
    final data = docSnapshot.data();
    
    if (data == null || data.isEmpty) {
      print('⚠️  DOCUMENTO VAZIO');
      print('O documento existe mas não tem dados.\n');
      print('Adicione o campo: active = true (boolean)');
      return;
    }
    
    print('📄 Dados do documento:');
    data.forEach((key, value) {
      print('   $key: $value (${value.runtimeType})');
    });
    print('');
    
    final isActive = data['active'];
    
    if (isActive == true) {
      print('✅ ADMIN CONFIGURADO CORRETAMENTE!\n');
      print('O usuário $adminUid tem permissões de admin.');
      print('');
      print('🎉 Próximos passos:');
      print('1. Faça login no app com essa conta');
      print('2. Vá até a aba "Trends"');
      print('3. Você verá um ícone de edição (✏️) no canto superior direito');
      print('4. Clique para acessar a tela de admin');
    } else if (isActive == false) {
      print('⚠️  ADMIN DESATIVADO\n');
      print('O documento existe, mas active = false');
      print('Altere o campo "active" para true no Console do Firebase');
    } else if (isActive == null) {
      print('⚠️  CAMPO "active" NÃO ENCONTRADO\n');
      print('O documento existe, mas não tem o campo "active"');
      print('Adicione o campo: active = true (boolean)');
    } else {
      print('⚠️  VALOR INVÁLIDO\n');
      print('O campo "active" deve ser boolean (true/false)');
      print('Valor atual: $isActive (${isActive.runtimeType})');
    }
    
    print('\n─────────────────────────────────────────────');
    
  } catch (e) {
    print('\n❌ ERRO: $e\n');
    print('Certifique-se de que:');
    print('1. O Firebase está configurado corretamente');
    print('2. Você tem permissões para ler o Firestore');
    print('3. As dependências estão instaladas (flutter pub get)');
  }
}
