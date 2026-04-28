import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '706926145253-q44b8ofodsf88gua4qegjs16pobfdl2e.apps.googleusercontent.com',
  );
  
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _auth.authStateChanges().listen((User? u) {
      _user = u;
      if (u != null) {
        _listenToUserData(u.uid);
      } else {
        _userData = null;
      }
      notifyListeners();
    });
  }

  void _listenToUserData(String uid) {
    _firestore.collection('users').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        _userData = snapshot.data();
        notifyListeners();
      }
    });
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      debugPrint(e.toString());
      return false;
    }
  }

  Future<String?> register(String email, String password, String username) async {
    _setLoading(true);
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password,
      );
      if (credential.user != null) {
        await credential.user!.updateDisplayName(username.trim());
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
      return null; 
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      if (e.code == 'weak-password') return 'La contraseña es muy debil.';
      if (e.code == 'email-already-in-use') return 'El correo ya esta registrado.';
      return e.code;
    } catch (e) {
      _setLoading(false);
      return 'Ocurrio un error al guardar tu perfil.';
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        _setLoading(false);
        return false; 
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            "username": userCredential.user!.displayName ?? "Aventurero", 
            "email": userCredential.user!.email ?? "",
            "nivelJugador": 1,
            "xpTotal": 0,
            "rachaDias": 0,
            "fechaRegistro": FieldValue.serverTimestamp(),
          });
        }
      }

      _setLoading(false);
      return true; 

    } catch (e) {
      _setLoading(false);
      debugPrint(e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      _user = null;
      _userData = null;
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}