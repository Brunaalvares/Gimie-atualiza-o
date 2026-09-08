// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web: reads the real browser URL (query params for shared folders).
Uri currentAppUri() {
  final href = html.window.location.href;
  return Uri.tryParse(href) ?? Uri.base;
}
