import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../screens/couple_map.dart';
import '../widgets/pairing_dialog.dart';
import '../widgets/contract_dialog.dart';

class CoupleAdventureCard extends StatefulWidget {
  const CoupleAdventureCard({super.key});

  @override
  State<CoupleAdventureCard> createState() => _CoupleAdventureCardState();
}

class _CoupleAdventureCardState extends State<CoupleAdventureCard> {
  bool _hasShownContractDialog = false;

  Stream<DocumentSnapshot> _getCoupleDocStream(String myUid, String partnerId) {
    String coupleDocId = myUid.compareTo(partnerId) < 0 ? '${myUid}_$partnerId' : '${partnerId}_$myUid';
    return FirebaseFirestore.instance.collection('couples_progress').doc(coupleDocId).snapshots();
  }

  void _showContractDialog(String myUid, String partnerUid, String coupleDocId) {
    if (_hasShownContractDialog) return;
    _hasShownContractDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ContractDialog(
        myUid: myUid,
        partnerUid: partnerUid,
        coupleDocId: coupleDocId,
      ),
    ).then((_) {
      _hasShownContractDialog = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    final bool hasPartner = userData != null && userData.containsKey('partnerId') && userData['partnerId'] != null;

    if (!hasPartner) {
      return _buildPremiumCard(
        title: 'Aventura en pareja', 
        subtitle: 'Vincúlate con alguien', 
        gradientColors: const [Color(0xFFF48FB1), Color(0xFFD81B60)], 
        icon: Icons.favorite_border_rounded, 
        onTap: () {
          if (authProvider.user != null) {
            showDialog(context: context, builder: (context) => PairingDialog(myUid: authProvider.user!.uid));
          }
        }
      );
    }

    final String partnerId = userData!['partnerId'];
    
    return StreamBuilder<DocumentSnapshot>(
      stream: _getCoupleDocStream(authProvider.user!.uid, partnerId),
      builder: (context, coupleSnapshot) {
        if (!coupleSnapshot.hasData || !coupleSnapshot.data!.exists) {
          return _buildPremiumCard(title: 'Cargando...', subtitle: '', gradientColors: [Colors.grey, Colors.grey.shade700], icon: Icons.hourglass_empty, onTap: () {});
        }

        final coupleData = coupleSnapshot.data!.data() as Map<String, dynamic>;
        final String coupleDocId = coupleSnapshot.data!.id;
        
        bool isUser1 = authProvider.user!.uid.compareTo(partnerId) < 0;
        bool iSigned = isUser1 ? (coupleData['contractSignedUser1'] ?? false) : (coupleData['contractSignedUser2'] ?? false);
        bool partnerSigned = isUser1 ? (coupleData['contractSignedUser2'] ?? false) : (coupleData['contractSignedUser1'] ?? false);

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(partnerId).snapshots(),
          builder: (context, partnerSnapshot) {
            if (partnerSnapshot.hasError) {
              debugPrint('Error al leer datos de la pareja: ${partnerSnapshot.error}');
            }
            String partnerName = 'tu pareja';
            if (partnerSnapshot.hasData && partnerSnapshot.data!.exists) {
              final partnerData = partnerSnapshot.data!.data() as Map<String, dynamic>;
              partnerName = partnerData['username'] ?? 'tu pareja';
            }

            if (!iSigned) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showContractDialog(authProvider.user!.uid, partnerId, coupleDocId);
              });

              return _buildPremiumCard(
                title: 'Aventura en pareja', 
                subtitle: 'Firma el contrato con $partnerName', 
                gradientColors: const [Color(0xFFFFB74D), Color(0xFFF57C00)], 
                icon: Icons.history_edu, 
                onTap: () => _showContractDialog(authProvider.user!.uid, partnerId, coupleDocId),
              );
            }

            // ESTADO 2: Esperando a la pareja
            if (iSigned && !partnerSigned) {
              return _buildPremiumCard(
                title: 'Aventura en pareja', 
                subtitle: 'Esperando firma de $partnerName', 
                gradientColors: const [Color(0xFF90A4AE), Color(0xFF546E7A)], 
                icon: Icons.hourglass_top, 
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Esperando que $partnerName firme el contrato...')),
                  );
                },
              );
            }

            // ESTADO 3: ¡Vinculados y listos! (TEXTO ACTUALIZADO AQUÍ)
            return _buildPremiumCard(
              title: 'Aventura en pareja', 
              subtitle: 'Nuestra aventura junto a $partnerName', 
              gradientColors: const [Color(0xFFF06292), Color(0xFFC2185B)], 
              icon: Icons.favorite, 
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoupleMap()))
            );
          },
        );
      },
    );
  }

  Widget _buildPremiumCard({
    required String title, 
    required String subtitle, 
    required List<Color> gradientColors, 
    required IconData icon, 
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20), 
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withOpacity(0.4), 
              blurRadius: 15, 
              offset: const Offset(0, 8),
              spreadRadius: 2
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14), 
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25), 
                shape: BoxShape.circle,
              ), 
              child: Icon(icon, size: 40, color: Colors.white)
            ),
            const SizedBox(width: 25),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2))])), 
                  const SizedBox(height: 6), 
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 15, fontWeight: FontWeight.w600))
                ]
              )
            ),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 28)
          ],
        ),
      ),
    );
  }
}