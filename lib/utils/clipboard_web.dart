import 'clipboard_web_stub.dart'
    if (dart.library.html) 'clipboard_web_impl.dart' as impl;

Future<bool> copyTextToClipboardWeb(String text) =>
    impl.copyTextToClipboardWeb(text);
