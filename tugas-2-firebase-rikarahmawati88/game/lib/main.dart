import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_core/firebase_core.dart';
// Import konfigurasi Firebase yang di-generate otomatis oleh FlutterFire CLI
import 'firebase_options.dart';
// Import SplashScreen sebagai halaman awal
import 'package:game/screens/splash_screen.dart';

// Custom ScrollBehavior agar bisa scroll dengan mouse di Chrome/Web
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

void main() async {
  // Memastikan binding Flutter sudah siap sebelum menjalankan kode async
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi Firebase dengan konfigurasi sesuai platform
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Menjalankan aplikasi Flutter
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameVault - Game Favorite',
      // Custom scroll behavior agar bisa scroll di Chrome
      scrollBehavior: AppScrollBehavior(),
      // Menghilangkan banner "DEBUG" di pojok kanan atas
      debugShowCheckedModeBanner: false,
      // Tema gelap untuk nuansa gaming
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFe94560),
        scaffoldBackgroundColor: const Color(0xFF1a1a2e),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFe94560),
          secondary: Color(0xFF533483),
          surface: Color(0xFF16213e),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}