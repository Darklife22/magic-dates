import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String getInitials(String? name) {
    if (name == null || name.isEmpty) return 'AE';
    List<String> parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  void _confirmUnlink(BuildContext context, String myUid, String partnerId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Desvincular pareja'),
          content: const Text('Estas seguro de que deseas terminar esta aventura de dos? Todo el progreso compartido se perdera y ambos volveran al modo individual.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _unlinkPartner(context, myUid, partnerId);
              },
              child: const Text('Desvincular', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _unlinkPartner(BuildContext context, String myUid, String partnerId) async {
    final firestore = FirebaseFirestore.instance;
    
    String coupleDocId = myUid.compareTo(partnerId) < 0 
        ? '${myUid}_$partnerId' 
        : '${partnerId}_$myUid';

    try {
      await firestore.collection('users').doc(myUid).update({'partnerId': FieldValue.delete()});
      await firestore.collection('users').doc(partnerId).update({'partnerId': FieldValue.delete()});
      await firestore.collection('couples_progress').doc(coupleDocId).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vinculo eliminado. Has vuelto al modo individual.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al desvincular'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleSignOut(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    final userName = userData?['username'] ?? authProvider.user?.displayName ?? 'Aventurero';
    final userEmail = userData?['email'] ?? authProvider.user?.email ?? '';
    final hasPartner = userData != null && userData.containsKey('partnerId') && userData['partnerId'] != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF1E5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9C27B0),
        elevation: 0,
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF81D4FA),
              child: Text(
                getInitials(userName),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 40),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              userName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF9C27B0)),
            ),
            const SizedBox(height: 5),
            Text(
              userEmail,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            if (hasPartner)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: const BorderSide(color: Colors.red, width: 1),
                    ),
                  ),
                  icon: const Icon(Icons.broken_image),
                  label: const Text('Desvincular Pareja', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    if (authProvider.user != null) {
                      _confirmUnlink(context, authProvider.user!.uid, userData['partnerId']);
                    }
                  },
                ),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4B12),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Cerrar Sesion', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => _handleSignOut(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}