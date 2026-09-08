import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> copyFolderLink({
    required BuildContext context,
    required String userId,
    required String folderName,
  }) async {
    final link = buildLink(userId: userId, folderName: folderName);
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copiado! ✓'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
