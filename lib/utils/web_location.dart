import 'web_location_stub.dart'
    if (dart.library.html) 'web_location_web.dart' as impl;

/// Current app URL. On web uses `dart:html` location; elsewhere [Uri.base].
Uri currentAppUri() => impl.currentAppUri();
