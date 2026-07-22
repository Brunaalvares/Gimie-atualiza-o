// Script de teste para verificar se Trends e Badges estão funcionando
// Execute: dart run test_trends_fix.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  print('🔍 Iniciando diagnóstico...\n');
  
  try {
    // Inicializar Firebase
    // await Firebase.initializeApp();
    
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    
    print('✅ Firebase inicializado');
    print('Usuario atual: ${auth.currentUser?.uid ?? "NÃO AUTENTICADO"}\n');
    
    // Teste 1: Verificar trend_boards
    print('📊 Teste 1: Verificando trend_boards...');
    try {
      final trendsSnap = await firestore
          .collection('trend_boards')
          .orderBy('sortOrder')
          .get();
      
      print('   ✓ Boards encontrados: ${trendsSnap.docs.length}');
      
      for (final doc in trendsSnap.docs) {
        final data = doc.data();
        print('   - Board: ${data['title']} (sortOrder: ${data['sortOrder']})');
        
        // Verificar subcollections
        final moods = await doc.reference.collection('mood_images').get();
        final products = await doc.reference.collection('trend_products').get();
        print('     → Moods: ${moods.docs.length}, Products: ${products.docs.length}');
      }
    } catch (e) {
      print('   ❌ Erro ao buscar trends: $e');
    }
    
    print('');
    
    // Teste 2: Verificar products (para popular products)
    print('📦 Teste 2: Verificando products...');
    try {
      final productsSnap = await firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      
      print('   ✓ Produtos encontrados: ${productsSnap.docs.length}');
      
      int withImages = 0;
      int withLikes = 0;
      
      for (final doc in productsSnap.docs) {
        final data = doc.data();
        if ((data['imageUrl'] as String?)?.isNotEmpty == true) withImages++;
        if ((data['likes'] as int?) ?? 0 > 0) withLikes++;
      }
      
      print('   - Com imagens: $withImages');
      print('   - Com likes: $withLikes');
    } catch (e) {
      print('   ❌ Erro ao buscar products: $e');
    }
    
    print('');
    
    // Teste 3: Verificar badges do usuário atual
    if (auth.currentUser != null) {
      print('🏆 Teste 3: Verificando badges...');
      try {
        final badgesSnap = await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .collection('badge_progress')
            .get();
        
        print('   ✓ Badges encontrados: ${badgesSnap.docs.length}');
        
        for (final doc in badgesSnap.docs) {
          final data = doc.data();
          final earned = data['earned'] == true;
          final current = data['current'] ?? 0;
          final target = data['target'] ?? 0;
          print('   - ${data['title']}: ${earned ? "✓ CONQUISTADO" : "$current/$target"}');
        }
      } catch (e) {
        print('   ❌ Erro ao buscar badges: $e');
      }
    } else {
      print('⚠️  Teste 3: Pulado (usuário não autenticado)');
    }
    
    print('');
    print('✅ Diagnóstico completo!');
    
  } catch (e) {
    print('❌ Erro fatal: $e');
  }
}
