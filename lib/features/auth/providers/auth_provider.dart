import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // IMPORTANTE: Necesario para la BD
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Instancia de Firestore
  
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _auth.authStateChanges().listen((User? u) {
      _user = u;
      notifyListeners();
    });
  }

  // --- Lógica de INICIO DE SESIÓN ---
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      debugPrint('Error de Auth: $e');
      return false;
    }
  }

  // --- Lógica de REGISTRO CON CREACIÓN DE PERFIL ---
  Future<String?> register(String email, String password, String username) async {
    _setLoading(true);
    try {
      // 1. Crea el correo y contraseña en Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        // 2. Actualiza el nombre
        await credential.user!.updateDisplayName(username.trim());
        
        // 3. CREA EL PERFIL EN LA COLECCIÓN 'users' DE FIRESTORE
        await _firestore.collection('users').doc(credential.user!.uid).set({
          "username": username.trim(),
          "email": email.trim(),
          "nivelJugador": 1,        
          "xpTotal": 0,             
          "rachaDias": 0,           
          "fechaRegistro": FieldValue.serverTimestamp(),
        });
      }

      _setLoading(false);
      return null; // Nulo = Éxito sin errores
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      if (e.code == 'weak-password') return 'La contraseña es muy débil (Mínimo 6 caracteres).';
      if (e.code == 'email-already-in-use') return 'El correo ya está registrado en Daty.';
      return 'Error de registro: ${e.code}';
    } catch (e) {
      _setLoading(false);
      debugPrint('Error en Firestore: $e');
      return 'Ocurrió un error al guardar tu perfil.';
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}