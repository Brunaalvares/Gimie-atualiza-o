import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

class FirebaseConfig {
  // Firebase Configuration for gimie-launch
  //
  // Prefer: `flutterfire configure` (generates firebase_options.dart).
  // Fallback: platform switch using values from google-services.json / GoogleService-Info.plist.

  // Android Configuration (from android/app/google-services.json)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY_HERE',
    appId: '1:669182239244:android:YOUR_ANDROID_APP_ID',
    messagingSenderId: '669182239244',
    projectId: 'gimie-launch',
    storageBucket: 'gimie-launch.appspot.com',
  );

  // iOS Configuration (from ios/Runner/GoogleService-Info.plist)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY_HERE',
    appId: '1:669182239244:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '669182239244',
    projectId: 'gimie-launch',
    storageBucket: 'gimie-launch.appspot.com',
    iosBundleId: 'com.gimie.app',
  );

  // Get Firebase Options based on platform
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'FirebaseConfig: web options not configured. Run `flutterfire configure`.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'FirebaseConfig: unsupported platform $defaultTargetPlatform. '
          'Run `flutterfire configure` to generate firebase_options.dart.',
        );
    }
  }
}
