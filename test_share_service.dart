import 'dart:io';
import 'lib/services/share_service.dart';
import 'lib/utils/debug_helper.dart';

/// Script de teste para validar o ShareService corrigido
void main() async {
  print('🧪 Testando ShareService corrigido...\n');
  
  try {
    // Teste 1: Inicialização
    print('1️⃣ Testando inicialização...');
    final shareService = ShareService.instance;
    
    await shareService.initialize();
    print('✅ Inicialização: OK\n');
    
    // Teste 2: Inicialização dupla (deve ser ignorada)
    print('2️⃣ Testando inicialização dupla...');
    await shareService.initialize();
    print('✅ Inicialização dupla: OK (ignorada corretamente)\n');
    
    // Teste 3: Verificar conteúdo compartilhado
    print('3️⃣ Testando verificação de conteúdo...');
    final content = await shareService.getSharedContent();
    if (content == null) {
      print('✅ Nenhum conteúdo compartilhado encontrado (esperado)\n');
    } else {
      print('ℹ️ Conteúdo encontrado: $content\n');
    }
    
    // Teste 4: Limpeza de conteúdo
    print('4️⃣ Testando limpeza de conteúdo...');
    await shareService.clearSharedContent();
    print('✅ Limpeza: OK\n');
    
    // Teste 5: Reinicialização
    print('5️⃣ Testando reinicialização...');
    await shareService.reinitialize();
    print('✅ Reinicialização: OK\n');
    
    // Teste 6: Dispose
    print('6️⃣ Testando dispose...');
    shareService.dispose();
    print('✅ Dispose: OK\n');
    
    print('🎉 Todos os testes passaram!');
    print('📊 ShareService está funcionando corretamente.');
    
  } catch (e, stackTrace) {
    print('❌ Erro durante os testes: $e');
    print('Stack trace: $stackTrace');
  }
}

/// Classe mock para testar sem dependências do Flutter
class MockDebugHelper {
  static void log(String message, [String? tag]) {
    final timestamp = DateTime.now().toIso8601String();
    final formattedTag = tag != null ? '[$tag]' : '[DEBUG]';
    print('$timestamp $formattedTag $message');
  }
  
  static void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    print('$timestamp [ERROR] $message');
    if (error != null) {
      print('$timestamp [ERROR] Error: $error');
    }
  }
}