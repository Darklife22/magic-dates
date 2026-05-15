import 'package:flutter/material.dart';

class GroupLobby extends StatelessWidget {
  const GroupLobby({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lobby Grupal', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9D72FF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Text('Lobby de expedición en construcción...', style: TextStyle(fontSize: 18, color: Colors.grey)),
      ),
    );
  }
}