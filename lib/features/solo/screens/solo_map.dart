import 'package:flutter/material.dart';

class SoloMap extends StatelessWidget {
  const SoloMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Individual', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF33B5FF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Text('Mapa de aventura solitaria en construcción...', style: TextStyle(fontSize: 18, color: Colors.grey)),
      ),
    );
  }
}