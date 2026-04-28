import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Habilitar cuando se configure Google

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
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

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      _setLoading(false);
      return true; // Éxito
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      debugPrint('Error de Firebase Auth: ${e.code}');
      return false; 
    } catch (e) {
      _setLoading(false);
      debugPrint('Error desconocido: $e');
      return false;
    }
  }

  Future<bool> register(String email, String password, String username) async {
    _setLoading(true);
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(username.trim());
      }

      _setLoading(false);
      return true; 
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      debugPrint('Error de Registro: ${e.code}');
      return false;
    } catch (e) {
      _setLoading(false);
      debugPrint('Error en Registro: $e');
      return false;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      debugPrint('Error al enviar: $e');
    }
  }

  // --- Cerrar Sesión ---
  Future<void> signOut() async {
    await _auth.signOut();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}