import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/debug_helper.dart';

class ShareService {
  static const String _appGroupId = 'group.com.gimie.shareextension';
  static const String _sharedKey = 'ShareKey';
  
  static ShareService? _instance;
  static ShareService get instance => _instance ??= ShareService._();
  
  ShareService._();
  
  /// Inicializa o serviço de compartilhamento
  Future<void> initialize() async {
    if (Platform.isIOS) {
      // Escuta por conteúdo compartilhado via Share Extension
      _listenForSharedContent();
      
      // Verifica se há conteúdo compartilhado pendente
      await _checkForPendingSharedContent();
    }
    
    // Escuta por arquivos compartilhados diretamente
    _listenForSharedFiles();
  }
  
  /// Escuta por arquivos compartilhados diretamente (Android/iOS)
  void _listenForSharedFiles() {
    try {
      // Texto compartilhado
      ReceiveSharingIntent.getTextStream().listen((String value) {
        _handleSharedText(value);
      }, onError: (error) {
        print('Erro ao escutar texto compartilhado: $error');
      });
      
      // Arquivos de mídia compartilhados
      ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> value) {
        _handleSharedMedia(value);
      }, onError: (error) {
        print('Erro ao escutar mídia compartilhada: $error');
      });
      
      // Verifica conteúdo inicial compartilhado
      ReceiveSharingIntent.getInitialText().then((String? value) {
        if (value != null && value.isNotEmpty) {
          _handleSharedText(value);
        }
      }).catchError((error) {
        print('Erro ao obter texto inicial: $error');
      });
      
      ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          _handleSharedMedia(value);
        }
      }).catchError((error) {
        print('Erro ao obter mídia inicial: $error');
      });
    } catch (e) {
      print('Erro ao configurar listeners de compartilhamento: $e');
    }
  }
  
  /// Escuta por conteúdo compartilhado via Share Extension (iOS)
  void _listenForSharedContent() {
    // Implementa listener para URL scheme
    _listenForURLScheme();
  }
  
  /// Escuta por abertura via URL scheme
  void _listenForURLScheme() {
    // Esta função seria chamada quando o app é aberto via gimie://share
    // Para implementação completa, você pode usar packages como app_links ou uni_links
    print('URL scheme listener configurado');
  }
  
  /// Verifica se há conteúdo compartilhado pendente no App Group
  Future<void> _checkForPendingSharedContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // No iOS, tentamos acessar o App Group UserDefaults
      // Como o SharedPreferences não suporta App Groups diretamente,
      // usamos um método nativo
      final sharedData = await _getSharedDataFromAppGroup();
      
      if (sharedData != null) {
        await _processSharedData(sharedData);
        await _clearSharedData();
      }
    } catch (e) {
      print('Erro ao verificar conteúdo compartilhado: $e');
    }
  }
  
  /// Obtém dados compartilhados do App Group (iOS)
  Future<Map<String, dynamic>?> _getSharedDataFromAppGroup() async {
    if (!Platform.isIOS) return null;
    
    try {
      const platform = MethodChannel('com.gimie.share');
      final result = await platform.invokeMethod('getSharedData');
      
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (e) {
      print('Erro ao obter dados do App Group: $e');
    }
    
    return null;
  }
  
  /// Limpa dados compartilhados do App Group
  Future<void> _clearSharedData() async {
    if (!Platform.isIOS) return;
    
    try {
      const platform = MethodChannel('com.gimie.share');
      await platform.invokeMethod('clearSharedData');
    } catch (e) {
      print('Erro ao limpar dados compartilhados: $e');
    }
  }
  
  /// Processa dados compartilhados
  Future<void> _processSharedData(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    
    switch (type) {
      case 'url':
        final url = data['url'] as String?;
        if (url != null) {
          await _handleSharedURL(url);
        }
        break;
        
      case 'text':
        final text = data['text'] as String?;
        if (text != null) {
          await _handleSharedText(text);
        }
        break;
        
      case 'image':
        final imageBase64 = data['image'] as String?;
        if (imageBase64 != null) {
          await _handleSharedImage(imageBase64);
        }
        break;
    }
  }
  
  /// Manipula texto compartilhado
  Future<void> _handleSharedText(String text) async {
    try {
      print('Texto compartilhado: $text');
      
      if (text.trim().isEmpty) return;
      
      // Verifica se é uma URL
      if (_isURL(text)) {
        await _handleSharedURL(text);
        return;
      }
      
      // Navega para a tela de adicionar produto com o texto
      await _navigateToAddProduct(text: text);
    } catch (e) {
      print('Erro ao processar texto compartilhado: $e');
    }
  }
  
  /// Manipula URL compartilhada
  Future<void> _handleSharedURL(String url) async {
    print('URL compartilhada: $url');
    
    // Navega para a tela de adicionar produto com a URL
    await _navigateToAddProduct(url: url);
  }
  
  /// Manipula imagem compartilhada (base64)
  Future<void> _handleSharedImage(String imageBase64) async {
    print('Imagem compartilhada (base64)');
    
    try {
      final imageBytes = base64Decode(imageBase64);
      await _navigateToAddProduct(imageBytes: imageBytes);
    } catch (e) {
      print('Erro ao processar imagem compartilhada: $e');
    }
  }
  
  /// Manipula arquivos de mídia compartilhados
  Future<void> _handleSharedMedia(List<SharedMediaFile> mediaFiles) async {
    try {
      if (mediaFiles.isEmpty) return;
      
      final mediaFile = mediaFiles.first;
      print('Arquivo compartilhado: ${mediaFile.path}');
      
      if (mediaFile.type == SharedMediaType.IMAGE) {
        final file = File(mediaFile.path);
        if (await file.exists()) {
          final imageBytes = await file.readAsBytes();
          await _navigateToAddProduct(imageBytes: imageBytes);
        } else {
          print('Arquivo de imagem não encontrado: ${mediaFile.path}');
        }
      }
    } catch (e) {
      print('Erro ao processar mídia compartilhada: $e');
    }
  }
  
  /// Navega para a tela de adicionar produto
  Future<void> _navigateToAddProduct({
    String? text,
    String? url,
    Uint8List? imageBytes,
  }) async {
    // Salva os dados compartilhados temporariamente
    final prefs = await SharedPreferences.getInstance();
    
    if (text != null) {
      await prefs.setString('shared_text', text);
    }
    
    if (url != null) {
      await prefs.setString('shared_url', url);
    }
    
    if (imageBytes != null) {
      final base64Image = base64Encode(imageBytes);
      await prefs.setString('shared_image', base64Image);
    }
    
    // Sinaliza que há conteúdo compartilhado
    await prefs.setBool('has_shared_content', true);
    
    // Aqui você pode usar um GlobalKey<NavigatorState> ou um serviço de navegação
    // para navegar para a tela de adicionar produto
    print('Navegando para AddProductScreen com conteúdo compartilhado');
  }
  
  /// Obtém conteúdo compartilhado salvo
  Future<Map<String, dynamic>?> getSharedContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (!(prefs.getBool('has_shared_content') ?? false)) {
        DebugHelper.log('No shared content found', 'SHARE');
        return null;
      }
      
      final result = <String, dynamic>{};
      
      final text = prefs.getString('shared_text');
      if (text != null && text.isNotEmpty) result['text'] = text;
      
      final url = prefs.getString('shared_url');
      if (url != null && url.isNotEmpty) result['url'] = url;
      
      final imageBase64 = prefs.getString('shared_image');
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        try {
          result['imageBytes'] = base64Decode(imageBase64);
        } catch (e) {
          DebugHelper.logError('Failed to decode base64 image', e);
        }
      }
      
      if (result.isNotEmpty) {
        DebugHelper.logShareContent(result);
        return result;
      }
      
      return null;
    } catch (e) {
      DebugHelper.logError('Error getting shared content', e);
      return null;
    }
  }
  
  /// Limpa conteúdo compartilhado salvo
  Future<void> clearSharedContent() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove('shared_text');
    await prefs.remove('shared_url');
    await prefs.remove('shared_image');
    await prefs.setBool('has_shared_content', false);
  }
  
  /// Verifica se uma string é uma URL válida
  bool _isURL(String text) {
    try {
      final uri = Uri.tryParse(text.trim());
      return uri != null && 
             (uri.scheme == 'http' || uri.scheme == 'https') && 
             uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}