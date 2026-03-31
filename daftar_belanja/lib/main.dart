import 'package:flutter/material.dart';
// Import package firebase_core untuk inisialisasi Firebase
import 'package:firebase_core/firebase_core.dart';
// Import konfigurasi Firebase yang di-generate otomatis oleh FlutterFire CLI
import 'firebase_options.dart';
// Import halaman ShoppingListScreen yang akan ditampilkan
import 'package:daftar_belanja/screens/shopping_list_screen.dart';
void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Hello World!'),
        ),
      ),
    );
  }
}
