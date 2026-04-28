import 'package:flutter/material.dart';
import 'screens/perfil_screen.dart';

void main() {
  runApp(const MagicDatesApp());
}

class MagicDatesApp extends StatelessWidget {
  const MagicDatesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Magic Dates',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9B6AF3),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void abrirPerfil(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PerfilScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8ECFF),
      appBar: AppBar(
        title: const Text('Magic Dates'),
        backgroundColor: const Color(0xFFB388FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => abrirPerfil(context),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Pantalla de inicio\nPresiona el icono de perfil arriba',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
