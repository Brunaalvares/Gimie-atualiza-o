import 'dart:async';

import 'package:flutter/material.dart';

import '../navigation/app_navigator.dart';
import '../screens/share_product_preview_screen.dart';
import '../utils/debug_helper.dart';
import 'share_service.dart';

/// Coordena a abertura da pré-visualização após "Compartilhar com a Gimie".
/// Evita condições de corrida entre resume, deep link e stream do ShareService.
class ShareFlowCoordinator {
  ShareFlowCoordinator._();
  static final ShareFlowCoordinator instance = ShareFlowCoordinator._();

  bool _isOpening = false;
  StreamSubscription<void>? _subscription;
  Timer? _pollTimer;

  void start() {
    _subscription?.cancel();
    _subscription =
        ShareService.instance.onSharedContentAvailable.listen((_) {
      unawaited(openPreviewIfNeeded(reason: 'stream'));
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Chamado no resume / become active. Faz polling curto porque a Share
  /// Extension pode gravar o App Group alguns ms depois do app acordar.
  Future<void> onAppResumed() async {
    await openPreviewIfNeeded(reason: 'resume');
    _pollTimer?.cancel();
    var attempt = 0;
    _pollTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      attempt++;
      unawaited(openPreviewIfNeeded(reason: 'poll-$attempt'));
      if (attempt >= 8) {
        timer.cancel();
      }
    });
  }

  Future<bool> openPreviewIfNeeded({String reason = 'manual'}) async {
    if (_isOpening) {
      DebugHelper.log(
        'Share preview already opening (skip $reason)',
        'SHARE_FLOW',
      );
      return true;
    }

    try {
      await ShareService.instance.refreshPendingSharedContent();
    } catch (e) {
      DebugHelper.logError('refreshPendingSharedContent failed', e);
    }

    final sharedContent = await ShareService.instance.getSharedContent();
    if (sharedContent == null) return false;

    final initialUrl = _extractSharedUrl(sharedContent);
    if (initialUrl == null || initialUrl.isEmpty) {
      DebugHelper.log('Shared content without URL (skip $reason)', 'SHARE_FLOW');
      return false;
    }

    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      DebugHelper.log(
        'Navigator not ready yet — keeping shared content ($reason)',
        'SHARE_FLOW',
      );
      return false;
    }

    _isOpening = true;
    DebugHelper.log(
      'Opening share preview ($reason): $initialUrl',
      'SHARE_FLOW',
    );

    // Só limpa depois de confirmar que conseguimos navegar.
    await ShareService.instance.clearSharedContent();

    try {
      // Pequeno atraso: no resume o navigator ainda pode estar a estabilizar.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final nav = appNavigatorKey.currentState;
      if (nav == null) {
        DebugHelper.log(
          'Navigator lost before push — restoring URL',
          'SHARE_FLOW',
        );
        await ShareService.instance.savePendingSharedUrl(initialUrl);
        return false;
      }

      await nav.push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => ShareProductPreviewScreen(initialUrl: initialUrl),
        ),
      );
      DebugHelper.log('Share preview closed', 'SHARE_FLOW');
      return true;
    } catch (e) {
      DebugHelper.logError('Failed to open share preview', e);
      await ShareService.instance.savePendingSharedUrl(initialUrl);
      return false;
    } finally {
      _isOpening = false;
    }
  }

  String? _extractSharedUrl(Map<String, dynamic> sharedContent) {
    final url = (sharedContent['url'] as String?)?.trim();
    if (url != null && url.isNotEmpty) return url;

    final text = (sharedContent['text'] as String?)?.trim();
    if (text == null || text.isEmpty) return null;

    final match = RegExp(
      r'https?:\/\/[^\s]+',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(0);
  }
}
