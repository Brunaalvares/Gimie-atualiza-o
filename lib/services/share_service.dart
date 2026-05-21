import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/debug_helper.dart';

class ShareService {
  static const MethodChannel _channel = MethodChannel('com.gimie.share');

  static ShareService? _instance;
  static ShareService get instance => _instance ??= ShareService._();

  ShareService._();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      DebugHelper.log('ShareService already initialized', 'SHARE');
      return;
    }

    try {
      DebugHelper.log('Initializing ShareService', 'SHARE');

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        _channel.setMethodCallHandler(_handleNativeCall);
        await Future<void>.delayed(const Duration(milliseconds: 250));
        await _checkForPendingSharedContent();
      }

      _isInitialized = true;
      DebugHelper.log('ShareService initialized successfully', 'SHARE');
    } catch (e) {
      DebugHelper.logError('Failed to initialize ShareService', e);
    }
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    try {
      if (call.method == 'onSharedContent') {
        DebugHelper.log('Received onSharedContent from native', 'SHARE');
        await _checkForPendingSharedContent();
      }
    } catch (e) {
      DebugHelper.logError('Error handling native call', e);
    }
  }

  Future<void> _checkForPendingSharedContent() async {
    try {
      final sharedData = await _getSharedDataFromAppGroup();

      if (sharedData != null) {
        DebugHelper.log('Found pending shared content', 'SHARE');
        await _processSharedData(sharedData);
        await _clearNativeSharedData();
      } else {
        DebugHelper.log('No pending shared content', 'SHARE');
      }
    } catch (e) {
      DebugHelper.logError('Error checking pending shared content', e);
    }
  }

  Future<Map<String, dynamic>?> _getSharedDataFromAppGroup() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return null;

    try {
      final result = await _channel.invokeMethod<Map>('getSharedData');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } on MissingPluginException {
      return null;
    } catch (e) {
      DebugHelper.logError('Error reading App Group data', e);
    }

    return null;
  }

  Future<void> _clearNativeSharedData() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;

    try {
      await _channel.invokeMethod('clearSharedData');
      DebugHelper.log('Native shared data cleared', 'SHARE');
    } on MissingPluginException {
      return;
    } catch (e) {
      DebugHelper.logError('Error clearing native shared data', e);
    }
  }

  Future<void> _processSharedData(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    DebugHelper.log('Processing shared data of type: $type', 'SHARE');

    switch (type) {
      case 'url':
        final url = data['url'] as String?;
        if (url != null && url.isNotEmpty) {
          await _saveSharedContent(url: _stripUtmQueryParameters(url));
        }
        break;

      case 'text':
        final text = data['text'] as String?;
        if (text != null && text.isNotEmpty) {
          if (_isURL(text)) {
            await _saveSharedContent(url: _stripUtmQueryParameters(text));
          } else {
            await _saveSharedContent(text: text);
          }
        }
        break;

      case 'image':
        final imageBase64 = data['image'] as String?;
        if (imageBase64 != null && imageBase64.isNotEmpty) {
          try {
            final imageBytes = base64Decode(imageBase64);
            await _saveSharedContent(imageBytes: imageBytes);
          } catch (e) {
            DebugHelper.logError('Error decoding shared image', e);
          }
        }
        break;

      default:
        DebugHelper.log('Unknown shared data type: $type', 'SHARE');
    }
  }

  Future<void> _saveSharedContent({
    String? text,
    String? url,
    Uint8List? imageBytes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

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
        DebugHelper.log('Saved shared URL: $url', 'SHARE');
      }

      if (imageBytes != null && imageBytes.isNotEmpty) {
        await prefs.setString('shared_image', base64Encode(imageBytes));
        hasContent = true;
        DebugHelper.log('Saved shared image (${imageBytes.length} bytes)', 'SHARE');
      }

      if (hasContent) {
        await prefs.setBool('has_shared_content', true);
        DebugHelper.log('Shared content saved successfully', 'SHARE');
      }
    } catch (e) {
      DebugHelper.logError('Error saving shared content', e);
    }
  }

  Future<Map<String, dynamic>?> getSharedContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!(prefs.getBool('has_shared_content') ?? false)) {
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

  Future<void> clearSharedContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('shared_text');
      await prefs.remove('shared_url');
      await prefs.remove('shared_image');
      await prefs.setBool('has_shared_content', false);
      DebugHelper.log('Shared content cleared', 'SHARE');
    } catch (e) {
      DebugHelper.logError('Error clearing shared content', e);
    }
  }

  bool _isURL(String text) {
    try {
      final uri = Uri.tryParse(text.trim());
      return uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Remove query keys used em campanhas (utm_source, utm_medium, …).
  String _stripUtmQueryParameters(String input) {
    final trimmed = input.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasQuery) return trimmed;

    final qp = Map<String, String>.from(uri.queryParameters);
    qp.removeWhere((k, _) => k.toLowerCase().startsWith('utm_'));
    if (qp.length == uri.queryParameters.length) return trimmed;

    return uri.replace(queryParameters: qp).toString();
  }

  void dispose() {
    DebugHelper.log('Disposing ShareService', 'SHARE');
    _isInitialized = false;
  }
}
