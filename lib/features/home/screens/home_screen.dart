import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';

import '../../auth/providers/auth_provider.dart';
import '../../profile/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  String getInitials(String? name) {
    if (name == null || name.isEmpty) return 'AE';
    List<String> parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  void _showPairingDialog(BuildContext context, String myUid) async {
    final firestore = FirebaseFirestore.instance;
    final TextEditingController codeController = TextEditingController();
    bool isLinking = false;

    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    math.Random rnd = math.Random();
    String myCode = String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));

    await firestore.collection('users').doc(myUid).update({'pairingCode': myCode});

    if (!context.mounted) return;

    StreamSubscription<DocumentSnapshot>? subscription;
    subscription = firestore.collection('users').doc(myUid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('partnerId') && data['partnerId'] != null) {
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vinculo exitoso. Tu aventura de dos ha comenzado.'), backgroundColor: Colors.green),
            );
          }
        }
      }
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, color: Color(0xFFFF4B12), size: 60),
                    const SizedBox(height: 15),
                    const Text(
                      'Una aventura de dos\nesta por comenzar',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF9C27B0)),
                    ),
                    const SizedBox(height: 20),
                    
                    const Text('Comparte tu codigo:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1E5F5),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFFCE93D8), width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(myCode, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 3)),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Color(0xFF9C27B0)),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: myCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Codigo copiado al portapapeles'), duration: Duration(seconds: 2)),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('O', style: TextStyle(color: Colors.grey))),
                          Expanded(child: Divider()),
                        ],
                      ),
                    ),

                    const Text('Tienes el codigo de tu pareja?', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                      decoration: InputDecoration(
                        hintText: 'CODIGO',
                        counterText: "",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4B12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        onPressed: isLinking ? null : () async {
                          if (codeController.text.length < 6) return;
                          
                          setStateDialog(() => isLinking = true);
                          
                          final matchQuery = await firestore.collection('users')
                              .where('pairingCode', isEqualTo: codeController.text.toUpperCase())
                              .limit(1).get();

                          if (matchQuery.docs.isNotEmpty) {
                            String partnerUid = matchQuery.docs.first.id;
                            
                            if (partnerUid == myUid) {
                              setStateDialog(() => isLinking = false);
                              return;
                            }

                            String coupleDocId = myUid.compareTo(partnerUid) < 0 
                                ? '${myUid}_$partnerUid' 
                                : '${partnerUid}_$myUid';

                            await firestore.collection('couples_progress').doc(coupleDocId).set({
                              'user1': myUid,
                              'user2': partnerUid,
                              'fechaVinculacion': FieldValue.serverTimestamp(),
                              'xpPareja': 0,
                              'nivelPareja': 1,
                            });

                            await firestore.collection('users').doc(myUid).update({'partnerId': partnerUid, 'pairingCode': FieldValue.delete()});
                            await firestore.collection('users').doc(partnerUid).update({'partnerId': myUid, 'pairingCode': FieldValue.delete()});

                          } else {
                            setStateDialog(() => isLinking = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Codigo no encontrado'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: isLinking 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Vincular y Comenzar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    ).then((_) {
      subscription?.cancel();
      firestore.collection('users').doc(myUid).update({'pairingCode': FieldValue.delete()});
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final String userName = authProvider.user?.displayName ?? 'Aventurero';
    final String initials = getInitials(userName);

    return Scaffold(
      backgroundColor: const Color(0xFFF1E5F5),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF9C27B0), Color(0xFFCE93D8), Color(0xFFF1E5F5)],
                stops: [0.0, 0.7, 1.0],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset('assets/images/mascot.png', height: 60, errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, color: Colors.white, size: 50)),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                  child: CircleAvatar(
                    radius: 25, backgroundColor: const Color(0xFF81D4FA),
                    child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                children: [
                  const Text('Bienvenido!', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFF729BFF), letterSpacing: 1.2)),
                  const Text('Elige tu modo de aventura', style: TextStyle(fontSize: 18, color: Colors.white, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 30),

                  _buildAdventureCard(
                    title: 'Aventura solo', subtitle: 'Explora por tu cuenta',
                    color: const Color(0xFF33B5FF), icon: Icons.backpack_rounded, iconColor: const Color(0xFFD84315),
                    onTap: () {},
                  ),
                  
                  Builder(
                    builder: (context) {
                      final userData = authProvider.userData;
                      final bool hasPartner = userData != null && userData.containsKey('partnerId') && userData['partnerId'] != null;
                      
                      if (hasPartner) {
                        final String partnerId = userData['partnerId'];
                        
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(partnerId).get(),
                          builder: (context, snapshot) {
                            String partnerName = 'Cargando...';
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final partnerData = snapshot.data!.data() as Map<String, dynamic>;
                              partnerName = partnerData['username'] ?? 'tu pareja';
                            }

                            return _buildAdventureCard(
                              title: 'Aventura Activa',
                              subtitle: 'Explorando con $partnerName',
                              color: const Color(0xFF4CAF50), 
                              icon: Icons.favorite,
                              iconColor: Colors.white,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Pronto cargara el mapa de pareja')),
                                );
                              },
                            );
                          },
                        );
                      } else {
                        return _buildAdventureCard(
                          title: 'Aventura en pareja',
                          subtitle: 'Vinculate con alguien',
                          color: const Color(0xFFFF4B12),
                          icon: Icons.favorite_border_rounded,
                          iconColor: const Color(0xFFF48FB1),
                          onTap: () {
                            if (authProvider.user != null) {
                              _showPairingDialog(context, authProvider.user!.uid);
                            }
                          },
                        );
                      }
                    }
                  ),
                  
                  _buildAdventureCard(
                    title: 'Aventura Grupal', subtitle: 'Expedicion en grupo',
                    color: const Color(0xFF9D72FF), icon: Icons.groups_rounded, iconColor: const Color(0xFFFFD54F),
                    onTap: () {},
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(left: 20, child: Transform.rotate(angle: -0.2, child: _buildPolaroidPhoto('https://images.unsplash.com/photo-1511895426328-dc8714191300?q=80&w=200&auto=format&fit=crop'))),
                        Positioned(right: 20, child: Transform.rotate(angle: 0.2, child: _buildPolaroidPhoto('https://images.unsplash.com/photo-1533682805518-48d1f5e8cd3e?q=80&w=200&auto=format&fit=crop'))),
                        Positioned(child: _buildPolaroidPhoto('https://images.unsplash.com/photo-1475924156734-496f6cac6ec1?q=80&w=200&auto=format&fit=crop')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
      
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black12, spreadRadius: 0, blurRadius: 10)],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black87,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 30), activeIcon: Icon(Icons.home_rounded, size: 30), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.photo_library_outlined, size: 30), activeIcon: Icon(Icons.photo_library_rounded, size: 30), label: 'Album'),
              BottomNavigationBarItem(icon: Icon(Icons.tune_rounded, size: 30), label: 'Ajustes'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdventureCard({required String title, required String subtitle, required Color color, required IconData icon, required Color iconColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, size: 40, color: iconColor),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolaroidPhoto(String imageUrl) {
    return Container(
      width: 100, height: 120, padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 3))],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(5), child: Image.network(imageUrl, fit: BoxFit.cover)),
    );
  }
}