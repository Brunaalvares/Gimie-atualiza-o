import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/clipboard_web.dart';
import '../utils/web_location.dart';

class SharedFolderParams {
  final String userId;
  final String folderName;

  const SharedFolderParams({
    required this.userId,
    required this.folderName,
  });

  bool get isValid => userId.isNotEmpty && folderName.isNotEmpty;
}

/// Builds, parses and persists shared-folder deep links.
class SharedFolderLinkService {
  SharedFolderLinkService._();
  static final SharedFolderLinkService instance = SharedFolderLinkService._();

  static const String webBaseUrl = 'https://gimie-launch.web.app/';
  static const String _pendingUserKey = 'pending_shared_user';
  static const String _pendingFolderKey = 'pending_shared_folder';

  static const String playStoreUrl =
      'https://play.google.com/apps/test/com.gimie.app/7';
  static const String appStoreUrl =
      'https://apps.apple.com/br/app/gimie/id6768790198';

  String buildLink({
    required String userId,
    required String folderName,
  }) {
    final uri = Uri.parse(webBaseUrl).replace(
      queryParameters: {
        'shared': 'true',
        'user': userId,
        'folder': folderName,
      },
    );
    return uri.toString();
  }

  SharedFolderParams? parseFromUri(Uri uri) {
    final shared = uri.queryParameters['shared']?.toLowerCase();
    if (shared != 'true' && shared != '1') return null;

    final userId = (uri.queryParameters['user'] ?? '').trim();
    final folderName = (uri.queryParameters['folder'] ?? '').trim();
    if (userId.isEmpty || folderName.isEmpty) return null;

    return SharedFolderParams(userId: userId, folderName: folderName);
  }

  SharedFolderParams? parseFromCurrentUrl() {
    return parseFromUri(currentAppUri());
  }

  Future<void> savePending(SharedFolderParams params) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingUserKey, params.userId);
    await prefs.setString(_pendingFolderKey, params.folderName);
  }

  Future<SharedFolderParams?> loadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = (prefs.getString(_pendingUserKey) ?? '').trim();
    final folderName = (prefs.getString(_pendingFolderKey) ?? '').trim();
    if (userId.isEmpty || folderName.isEmpty) return null;
    return SharedFolderParams(userId: userId, folderName: folderName);
  }

  Future<void> clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingUserKey);
    await prefs.remove(_pendingFolderKey);
  }

  Future<bool> _tryCopy(String link) async {
    try {
      await Clipboard.setData(ClipboardData(text: link));
    } catch (_) {
      // continue to web fallback
    }
    if (kIsWeb) {
      return copyTextToClipboardWeb(link);
    }
    return true;
  }

  Future<void> copyFolderLink({
    required BuildContext context,
    required String userId,
    required String folderName,
  }) async {
    final trimmedUser = userId.trim();
    final trimmedFolder = folderName.trim();
    if (trimmedUser.isEmpty || trimmedFolder.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível gerar o link desta pasta'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final link = buildLink(userId: trimmedUser, folderName: trimmedFolder);
    final copied = await _tryCopy(link);
    if (!context.mounted) return;

    // No web o clipboard pode falhar silenciosamente: sempre mostra o link.
    if (kIsWeb || !copied) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(
              'Link da pasta',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B2C5C),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  copied
                      ? 'Link copiado! Você também pode copiar abaixo:'
                      : 'Copie o link abaixo para compartilhar:',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  link,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: Color(0xFF8B7FB8),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final ok = await _tryCopy(link);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok ? 'Link copiado! ✓' : 'Selecione e copie o link',
                      ),
                      backgroundColor: ok ? Colors.green : Colors.orange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('Copiar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copiado! ✓'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
