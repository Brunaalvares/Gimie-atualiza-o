import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'providers/product_provider.dart';
import 'providers/auth_provider.dart';
import 'config/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: FirebaseConfig.currentPlatform,
    );
  } catch (e) {
    runApp(FirebaseInitErrorApp(error: e.toString()));
    return;
  }
  
  runApp(const GimieApp());
}

class FirebaseInitErrorApp extends StatelessWidget {
  final String error;

  const FirebaseInitErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF8B7FB8),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Erro ao iniciar o Firebase',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFF5F3E8),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Verifique suas chaves do Firebase (google-services.json / GoogleService-Info.plist) '
                    'ou rode `flutterfire configure`.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFF5F3E8)),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFF5F3E8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GimieApp extends StatelessWidget {
  const GimieApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MaterialApp(
        title: 'Gimie',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF8B7FB8),
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B7FB8),
            primary: const Color(0xFF8B7FB8),
            secondary: const Color(0xFF6B2C5C),
          ),
          fontFamily: 'Inter',
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B7FB8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8B7FB8), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
