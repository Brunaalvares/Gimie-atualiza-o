import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
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
  
  // Stream subscriptions para gerenciar memory leaks
  StreamSubscription<String>? _textStreamSubscription;
  StreamSubscription<List<SharedMediaFile>>? _mediaStreamSubscription;
  bool _isInitialized = false;
  
  /// Inicializa o serviço de compartilhamento
  Future<void> initialize() async {
    if (_isInitialized) {
      DebugHelper.log('ShareService already initialized', 'SHARE');
      return;
    }
    
    try {
      DebugHelper.log('Initializing ShareService', 'SHARE');
      
      // Escuta por arquivos compartilhados diretamente (Android/iOS)
      _listenForSharedFiles();
      
      if (Platform.isIOS) {
        // Escuta por conteúdo compartilhado via Share Extension
        _listenForSharedContent();
        
        // Verifica se há conteúdo compartilhado pendente
        await _checkForPendingSharedContent();
      }
      
      _isInitialized = true;
      DebugHelper.log('ShareService initialized successfully', 'SHARE');
    } catch (e) {
      DebugHelper.logError('Failed to initialize ShareService', e);
      rethrow;
    }
  }
  
  /// Escuta por arquivos compartilhados diretamente (Android/iOS)
  void _listenForSharedFiles() {
    try {
      DebugHelper.log('Setting up shared files listeners', 'SHARE');
      
      // Cancela listeners anteriores se existirem
      _textStreamSubscription?.cancel();
      _mediaStreamSubscription?.cancel();
      
      // Texto compartilhado (stream contínuo)
      _textStreamSubscription = ReceiveSharingIntent.getTextStream().listen(
        (String value) {
          if (value.isNotEmpty) {
            DebugHelper.log('Received shared text via stream: $value', 'SHARE');
            _handleSharedText(value);
          }
        },
        onError: (error) {
          DebugHelper.logError('Error listening to shared text stream', error);
        },
      );
      
      // Arquivos de mídia compartilhados (stream contínuo)
      _mediaStreamSubscription = ReceiveSharingIntent.getMediaStream().listen(
        (List<SharedMediaFile> value) {
          if (value.isNotEmpty) {
            DebugHelper.log('Received shared media via stream: ${value.length} files', 'SHARE');
            _handleSharedMedia(value);
          }
        },
        onError: (error) {
          DebugHelper.logError('Error listening to shared media stream', error);
        },
      );
      
      // Verifica conteúdo inicial compartilhado (apenas uma vez)
      _checkInitialSharedContent();
      
    } catch (e) {
      DebugHelper.logError('Error setting up shared files listeners', e);
    }
  }
  
  /// Verifica conteúdo inicial compartilhado (executado apenas uma vez)
  Future<void> _checkInitialSharedContent() async {
    try {
      DebugHelper.log('Checking initial shared content', 'SHARE');
      
      // Texto inicial
      final initialText = await ReceiveSharingIntent.getInitialText();
      if (initialText != null && initialText.isNotEmpty) {
        DebugHelper.log('Found initial shared text: $initialText', 'SHARE');
        await _handleSharedText(initialText);
        // Limpa o texto inicial após processar
        ReceiveSharingIntent.reset();
      }
      
      // Mídia inicial
      final initialMedia = await ReceiveSharingIntent.getInitialMedia();
      if (initialMedia.isNotEmpty) {
        DebugHelper.log('Found initial shared media: ${initialMedia.length} files', 'SHARE');
        await _handleSharedMedia(initialMedia);
        // Limpa a mídia inicial após processar
        ReceiveSharingIntent.reset();
      }
      
    } catch (e) {
      DebugHelper.logError('Error checking initial shared content', e);
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
      DebugHelper.log('Processing shared text: $text', 'SHARE');
      
      if (text.trim().isEmpty) {
        DebugHelper.log('Empty text, skipping', 'SHARE');
        return;
      }
      
      // Verifica se é uma URL
      if (_isURL(text)) {
        DebugHelper.log('Text is URL, processing as URL', 'SHARE');
        await _handleSharedURL(text);
        return;
      }
      
      // Navega para a tela de adicionar produto com o texto
      DebugHelper.log('Processing as regular text', 'SHARE');
      await _navigateToAddProduct(text: text);
    } catch (e) {
      DebugHelper.logError('Error processing shared text', e);
    }
  }
  
  /// Manipula URL compartilhada
  Future<void> _handleSharedURL(String url) async {
    try {
      DebugHelper.log('Processing shared URL: $url', 'SHARE');
      
      // Navega para a tela de adicionar produto com a URL
      await _navigateToAddProduct(url: url);
    } catch (e) {
      DebugHelper.logError('Error processing shared URL', e);
    }
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
      if (mediaFiles.isEmpty) {
        DebugHelper.log('No media files to process', 'SHARE');
        return;
      }
      
      final mediaFile = mediaFiles.first;
      DebugHelper.log('Processing shared media file: ${mediaFile.path}', 'SHARE');
      
      if (mediaFile.type == SharedMediaType.IMAGE) {
        final file = File(mediaFile.path);
        if (await file.exists()) {
          DebugHelper.log('Reading image file: ${mediaFile.path}', 'SHARE');
          final imageBytes = await file.readAsBytes();
          
          if (imageBytes.isNotEmpty) {
            await _navigateToAddProduct(imageBytes: imageBytes);
          } else {
            DebugHelper.log('Image file is empty: ${mediaFile.path}', 'SHARE');
          }
        } else {
          DebugHelper.log('Image file not found: ${mediaFile.path}', 'SHARE');
        }
      } else {
        DebugHelper.log('Unsupported media type: ${mediaFile.type}', 'SHARE');
      }
    } catch (e) {
      DebugHelper.logError('Error processing shared media', e);
    }
  }
  
  /// Navega para a tela de adicionar produto
  Future<void> _navigateToAddProduct({
    String? text,
    String? url,
    Uint8List? imageBytes,
  }) async {
    try {
      DebugHelper.log('Saving shared content for navigation', 'SHARE');
      
      // Salva os dados compartilhados temporariamente
      final prefs = await SharedPreferences.getInstance();
      
      // Limpa dados anteriores
      await clearSharedContent();
      
      bool hasContent = false;
      
      if (text != null && text.trim().isNotEmpty) {
        await prefs.setString('shared_text', text.trim());
        hasContent = true;
        DebugHelper.log('Saved shared text', 'SHARE');
      }
      
      if (url != null && url.trim().isNotEmpty) {
        await prefs.setString('shared_url', url.trim());
        hasContent = true;
        DebugHelper.log('Saved shared URL', 'SHARE');
      }
      
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final base64Image = base64Encode(imageBytes);
        await prefs.setString('shared_image', base64Image);
        hasContent = true;
        DebugHelper.log('Saved shared image (${imageBytes.length} bytes)', 'SHARE');
      }
      
      if (hasContent) {
        // Sinaliza que há conteúdo compartilhado
        await prefs.setBool('has_shared_content', true);
        DebugHelper.log('Shared content saved successfully', 'SHARE');
      } else {
        DebugHelper.log('No content to save', 'SHARE');
      }
      
    } catch (e) {
      DebugHelper.logError('Error saving shared content', e);
    }
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
  
  /// Limpa recursos e cancela listeners
  void dispose() {
    DebugHelper.log('Disposing ShareService', 'SHARE');
    
    _textStreamSubscription?.cancel();
    _mediaStreamSubscription?.cancel();
    
    _textStreamSubscription = null;
    _mediaStreamSubscription = null;
    _isInitialized = false;
  }
  
  /// Reinicializa o serviço (útil para testes ou reset)
  Future<void> reinitialize() async {
    DebugHelper.log('Reinitializing ShareService', 'SHARE');
    
    dispose();
    await initialize();
  }
}