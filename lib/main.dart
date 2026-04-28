import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/auth/screens/login_screen.dart'; // Importaremos esto luego

void main() async {
  // Aseguramos la inicialización de Flutter antes de llamar a Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializamos Firebase con las opciones generadas por FlutterFire
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const DatyApp());
}

class DatyApp extends StatelessWidget {
  const DatyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daty',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Colores base de la marca Daty (basados en la imagen)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC14BF1), // Púrpura principal
          secondary: const Color(0xFFFFD147), // Amarillo inferior
        ),
        useMaterial3: true,
        fontFamily: 'Serif', 
      ),
      home: const LoginScreen(), // Carga la pantalla de login al iniciar
    );
  }
}