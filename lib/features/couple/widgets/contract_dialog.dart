import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContractDialog extends StatefulWidget {
  final String myUid;
  final String partnerUid;
  final String coupleDocId;

  const ContractDialog({
    super.key, 
    required this.myUid, 
    required this.partnerUid, 
    required this.coupleDocId,
  });

  @override
  State<ContractDialog> createState() => _ContractDialogState();
}

class _ContractDialogState extends State<ContractDialog> {
  bool _rule1Checked = false;
  bool _rule2Checked = false;
  bool _rule3Checked = false;
  bool _isProcessing = false;

  bool get _allChecked => _rule1Checked && _rule2Checked && _rule3Checked;

  Future<void> _signContract() async {
    setState(() => _isProcessing = true);
    final firestore = FirebaseFirestore.instance;
    
    String fieldToUpdate = widget.myUid.compareTo(widget.partnerUid) < 0 
        ? 'contractSignedUser1' 
        : 'contractSignedUser2';

    try {
      await firestore.collection('couples_progress').doc(widget.coupleDocId).update({
        fieldToUpdate: true,
      });
      
      if (mounted) Navigator.pop(context); 
    } catch (e) {
      debugPrint('Error al firmar contrato: $e');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectAndUnlink() async {
    setState(() => _isProcessing = true);
    final firestore = FirebaseFirestore.instance;

    try {
      await firestore.collection('users').doc(widget.myUid).update({'partnerId': FieldValue.delete()});
      await firestore.collection('users').doc(widget.partnerUid).update({'partnerId': FieldValue.delete()});
      await firestore.collection('couples_progress').doc(widget.coupleDocId).delete();

      if (mounted) Navigator.pop(context); 
    } catch (e) {
      debugPrint('Error al desvincular desde contrato: $e');
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // WillPopScope evita que cierren el diálogo tocando fuera o con el botón atrás
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history_edu, color: Color(0xFF9C27B0), size: 50),
                const SizedBox(height: 15),
                const Text('Contrato de Aventura', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF9C27B0))),
                const SizedBox(height: 5),
                const Text('100 Citas Románticas', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                
                CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _rule1Checked,
                  onChanged: (val) => setState(() => _rule1Checked = val ?? false),
                  title: const Text('📸 Registren cada salida con fotos o videos. ¡Su álbum será un recuerdo eterno!', style: TextStyle(fontSize: 13)),
                ),
                CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _rule2Checked,
                  onChanged: (val) => setState(() => _rule2Checked = val ?? false),
                  title: const Text('📵 El celular solo se usará para capturar momentos, no para distraerse.', style: TextStyle(fontSize: 13)),
                ),
                CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _rule3Checked,
                  onChanged: (val) => setState(() => _rule3Checked = val ?? false),
                  title: const Text('💖 Lo esencial es la complicidad y el disfrute juntos, no que todo salga perfecto.', style: TextStyle(fontSize: 13)),
                ),

                const Divider(height: 30),

                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _allChecked ? const Color(0xFF66BB6A) : Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    onPressed: _allChecked && !_isProcessing ? _signContract : null,
                    icon: _isProcessing 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: const Text('Firmo y Acepto', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                TextButton(
                  onPressed: _isProcessing ? null : _rejectAndUnlink,
                  child: const Text('No estoy de acuerdo (Romper vínculo)', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}