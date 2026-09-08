// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> copyTextToClipboardWeb(String text) async {
  try {
    await html.window.navigator.clipboard?.writeText(text);
    return true;
  } catch (_) {
    try {
      final area = html.TextAreaElement()
        ..value = text
        ..style.position = 'fixed'
        ..style.left = '-9999px';
      html.document.body?.append(area);
      area.select();
      final ok = html.document.execCommand('copy');
      area.remove();
      return ok;
    } catch (_) {
      return false;
    }
  }
}
