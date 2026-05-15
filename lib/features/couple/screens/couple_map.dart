import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';

class CoupleMap extends StatefulWidget {
  const CoupleMap({super.key});

  @override
  State<CoupleMap> createState() => _CoupleMapState();
}

class _CoupleMapState extends State<CoupleMap> {
  final ScrollController _scrollController = ScrollController();
  final int totalNodes = 50; 
  late double mapHeight;

  List<int> _adventurePath = []; 
  int? activeAdventureNumber; 
  String? _partnerId;

  bool _reviewCompletedUser1 = false;
  bool _reviewCompletedUser2 = false;

  final Map<int, Map<String, dynamic>> _adventuresCache = {};
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    mapHeight = (totalNodes * 100.0) + 300;
    _fetchAdventures();
  }

  // ==========================================
  // LÓGICA DE SCROLL AUTOMÁTICO
  // ==========================================
  void _scrollToCurrentNode() {
    if (!_scrollController.hasClients) return;
    
    // Determinar cuál es el nodo que debe estar en la parte inferior
    int targetIndex = _adventurePath.length - 1; // Por defecto: el último desbloqueado
    
    if (activeAdventureNumber != null) {
      int activeIdx = _adventurePath.indexOf(activeAdventureNumber!);
      if (activeIdx != -1) {
        targetIndex = activeIdx; // Si hay uno en curso, ese es el principal
      }
    }
    
    if (targetIndex < 0) return;
    
    // Calcular la posición Y basada en la lógica de _generatePathPoints
    double targetY = mapHeight - 150 - (100.0 * targetIndex);
    
    // Queremos que este nodo esté a unos 150 píxeles del borde inferior de la pantalla
    double viewportHeight = MediaQuery.of(context).size.height;
    double targetScrollOffset = targetY - viewportHeight + 150; 
    
    // Asegurarnos de no salirnos de los límites del scroll
    double maxScroll = _scrollController.position.maxScrollExtent;
    double minScroll = _scrollController.position.minScrollExtent;
    
    targetScrollOffset = targetScrollOffset.clamp(minScroll, maxScroll);
    
    // Realizar el scroll con una animación suave
    _scrollController.animateTo(
      targetScrollOffset, 
      duration: const Duration(milliseconds: 800), 
      curve: Curves.easeInOut,
    );
  }

  Future<void> _fetchAdventures() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userData = authProvider.userData;
      if (userData == null) return;

      final myUid = authProvider.user!.uid;
      final partnerId = userData['partnerId'] as String;
      _partnerId = partnerId;
      String coupleDocId = myUid.compareTo(partnerId) < 0 ? '${myUid}_$partnerId' : '${partnerId}_$myUid';

      FirebaseFirestore.instance.collection('couples_progress').doc(coupleDocId).snapshots().listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              activeAdventureNumber = data['activeAdventureNumber']; 
              _adventurePath = List<int>.from(data['adventurePath'] ?? []);
              _reviewCompletedUser1 = data['reviewCompletedUser1'] ?? false;
              _reviewCompletedUser2 = data['reviewCompletedUser2'] ?? false;
            });
            
            // Cada vez que los datos cambien, animamos el scroll al nodo correspondiente
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToCurrentNode();
            });
          }
        }
      });

      final snapshot = await FirebaseFirestore.instance.collection('adventures').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('number')) {
          _adventuresCache[data['number']] = data;
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
        if (_adventurePath.isEmpty && _adventuresCache.isNotEmpty) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final myUid = authProvider.user!.uid;
          final partnerId = authProvider.userData!['partnerId'];
          String coupleDocId = myUid.compareTo(partnerId) < 0 ? '${myUid}_$partnerId' : '${partnerId}_$myUid';
          await _generateNextNode(coupleDocId);
        }
      }
    }
  }

  Future<void> _generateNextNode(String coupleDocId) async {
    if (_adventuresCache.isEmpty) return;
    List<int> allIds = _adventuresCache.keys.toList();
    List<int> availableIds = allIds.where((id) => !_adventurePath.contains(id)).toList();
    if (availableIds.isEmpty) return; 
    final random = Random();
    int nextAdventureId = availableIds[random.nextInt(availableIds.length)];
    await FirebaseFirestore.instance.collection('couples_progress').doc(coupleDocId).update({
      'adventurePath': FieldValue.arrayUnion([nextAdventureId])
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Offset> _generatePathPoints(double mapWidth) {
    List<Offset> points = [];
    double y = mapHeight - 150; 
    double stepY = -100.0; 
    for (int i = 0; i < totalNodes; i++) {
      double x;
      if (i % 4 == 0) x = mapWidth * 0.15; 
      else if (i % 4 == 1) x = mapWidth * 0.5;  
      else if (i % 4 == 2) x = mapWidth * 0.85; 
      else x = mapWidth * 0.5;  
      points.add(Offset(x, y));
      y += stepY;
    }
    return points;
  }

  List<Offset> _generateDecorationPoints(List<Offset> pathPoints, double mapWidth) {
    List<Offset> points = [];
    for (int i = 0; i < pathPoints.length; i++) {
      if (i % 2 == 0) {
        Offset p = pathPoints[i];
        double pathXRatio = p.dx / mapWidth;
        double decoX = pathXRatio < 0.35 ? mapWidth * 0.85 : (pathXRatio > 0.65 ? mapWidth * 0.15 : (i % 4 == 0 ? mapWidth * 0.1 : mapWidth * 0.9));
        points.add(Offset(decoX, p.dy + 20));
      }
    }
    return points;
  }

  List<Offset> _generateAmbientDecor(double mapWidth) {
    return List.generate(40, (i) => Offset(mapWidth * (0.05 + (i * 0.23) % 0.9), mapHeight - (i * 187) % mapHeight));
  }

  void _showAdventureDetail(Map<String, dynamic> adventure, int nodeIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: 180, width: double.infinity, color: Colors.grey.shade200,
                            child: Image.asset('assets/images/adventures/${adventure['number']}.png', fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text('Imagen no disponible', style: TextStyle(color: Colors.grey.shade500)),
                              ]),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Center(child: Text(adventure['title'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFC2185B)))),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildInfoChip(Icons.category, adventure['category'] ?? 'General'),
                          const SizedBox(width: 10),
                          _buildInfoChip(Icons.timer, adventure['estimatedTime'] ?? '1 hora'),
                          const SizedBox(width: 10),
                          _buildInfoChip(Icons.attach_money, 'Nivel \$${adventure['costLevel'] ?? 1}'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 5),
                      Text(adventure['description'] ?? '', style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFFFCE4EC), borderRadius: BorderRadius.circular(15)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('🏆 Reto de la Cita', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC2185B))),
                          const SizedBox(height: 5),
                          Text(adventure['challenge'] ?? '', style: const TextStyle(color: Color(0xFF880E4F))),
                        ]),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity, height: 55,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showTipsBeforeStart(adventure, nodeIndex);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC2185B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                          label: const Text('Empezar Aventura', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTipsBeforeStart(Map<String, dynamic> adventure, int nodeIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lightbulb_outline, color: Color(0xFF1565C0), size: 50),
                const SizedBox(height: 15),
                const Text('Consejos antes de salir', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Text(adventure['tips'] ?? 'Disfruten el momento.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                const SizedBox(height: 25),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context); 
                        await _setAdventureStatus(adventure['number'], true);
                        if (mounted) {
                          List<int> availableIds = _adventuresCache.keys.where((id) => !_adventurePath.contains(id)).toList();
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdventureInProgressScreen(adventureData: adventure, availableAdventuresIds: availableIds)));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
                      child: const Text('Iniciar Cita', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ])
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _setAdventureStatus(int adventureNumber, bool isActive) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final myUid = authProvider.user!.uid;
      final partnerId = authProvider.userData!['partnerId'];
      String coupleDocId = myUid.compareTo(partnerId) < 0 ? '${myUid}_$partnerId' : '${partnerId}_$myUid';

      await FirebaseFirestore.instance.collection('couples_progress').doc(coupleDocId).update({
        'activeAdventureNumber': isActive ? adventureNumber : FieldValue.delete(),
        'reviewCompletedUser1': false, 
        'reviewCompletedUser2': false,
      });
    } catch (e) {
      debugPrint('Error guardando estado de cita: $e');
    }
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey.shade600), const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double mapWidth = MediaQuery.of(context).size.width;
    final pathPoints = _generatePathPoints(mapWidth);
    final decoPoints = _generateDecorationPoints(pathPoints, mapWidth); 
    final ambientPoints = _generateAmbientDecor(mapWidth);
    
    double fogBottom;
    if (_adventurePath.isEmpty) {
      fogBottom = 0; 
    } else {
      double fogTopY = pathPoints[_adventurePath.length - 1].dy - 100; 
      fogBottom = mapHeight - (fogTopY + 50);
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF87CEEB), Color(0xFFE0F7FA), Color(0xFFAED581), Color(0xFF66BB6A)], stops: [0.0, 0.3, 0.6, 1.0])),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                width: mapWidth, height: mapHeight,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    ...ambientPoints.map((pos) => _buildFlower(pos.dx, pos.dy)),
                    CustomPaint(size: Size(mapWidth, mapHeight), painter: CandyPathPainter(points: pathPoints)),
                    ...decoPoints.asMap().entries.map((entry) => _buildStaticDecoration(entry.value.dx, entry.value.dy, entry.key)),
                    ...pathPoints.asMap().entries.map((entry) {
                      int nodeIndex = entry.key; 
                      int adventureId = nodeIndex < _adventurePath.length ? _adventurePath[nodeIndex] : -1;
                      Map<String, dynamic>? adventureData = _adventuresCache[adventureId];
                      bool isInProgress = activeAdventureNumber == adventureId;
                      bool isUnlocked = nodeIndex < _adventurePath.length;
                      return _buildGameNode(entry.value.dx, entry.value.dy, nodeIndex + 1, adventureData, isUnlocked, isInProgress);
                    }),
                    if (_adventurePath.length < totalNodes)
                      Positioned(top: 0, left: 0, right: 0, bottom: fogBottom,
                        child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.transparent, Colors.white.withOpacity(0.85), Colors.white.withOpacity(0.98), const Color(0xFFE0E0E0)], stops: const [0.0, 0.15, 0.4, 1.0])))),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10, left: 10,
            child: Material(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(30), child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context))),
          ),
        ],
      ),
    );
  }

  Widget _buildFlower(double x, double y) => Positioned(left: x, top: y, child: Icon(Icons.local_florist, color: Colors.pinkAccent.withOpacity(0.3), size: 30));

  Widget _buildGameNode(double x, double y, int displayNumber, Map<String, dynamic>? adventureData, bool isUnlocked, bool isInProgress) {
    bool isLocked = !isUnlocked; 

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myUid = authProvider.user!.uid;
    bool isUser1 = _partnerId != null && myUid.compareTo(_partnerId!) < 0;
    bool iReviewed = isInProgress && (isUser1 ? _reviewCompletedUser1 : _reviewCompletedUser2);
    bool partnerReviewed = isInProgress && (isUser1 ? _reviewCompletedUser2 : _reviewCompletedUser1);
    bool isWaitingForPartner = isInProgress && iReviewed && !partnerReviewed;

    Color startColor; Color endColor; Widget iconChild;
    
    if (isWaitingForPartner) {
      startColor = const Color(0xFFFFCA28); endColor = const Color(0xFFFFA000); 
      iconChild = const Icon(Icons.hourglass_top, color: Colors.white, size: 28);
    } else if (isInProgress) {
      startColor = const Color(0xFFFFA000); endColor = const Color(0xFFFF6F00); 
      iconChild = const Icon(Icons.adjust, color: Colors.white, size: 28);
    } else if (isLocked) {
      startColor = Colors.grey.shade400; endColor = Colors.grey.shade600; 
      iconChild = const Icon(Icons.lock, color: Colors.white70, size: 24);
    } else if (isUnlocked && displayNumber == _adventurePath.length) { 
      startColor = const Color(0xFFFF4081); endColor = const Color(0xFFC2185B); 
      iconChild = Text(displayNumber.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, shadows: [Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1))]));
    } else { 
      startColor = const Color(0xFF81C784); endColor = const Color(0xFF388E3C); 
      iconChild = Text(displayNumber.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, shadows: [Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1))]));
    }

    return Positioned(
      left: x - 30, top: y - 30, 
      child: GestureDetector(
        onTap: isLocked || adventureData == null ? null : () {
          if (isWaitingForPartner) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya calificaste. ¡Esperando a tu pareja!')));
          } else if (isInProgress) {
            List<int> availableIds = _adventuresCache.keys.where((id) => !_adventurePath.contains(id)).toList();
            Navigator.push(context, MaterialPageRoute(builder: (_) => AdventureInProgressScreen(adventureData: adventureData, availableAdventuresIds: availableIds)));
          } else {
            _showAdventureDetail(adventureData, displayNumber - 1);
          }
        },
        child: Container(
          width: 60, height: 60, 
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [startColor, endColor], center: Alignment.center, radius: 0.5),
            border: Border.all(color: Colors.white, width: isInProgress ? 4 : 3), 
            boxShadow: [BoxShadow(color: startColor.withOpacity(0.6), blurRadius: isInProgress ? 12 : 6, offset: const Offset(2, 4))], 
          ),
          child: Center(
            child: _isLoadingData 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : iconChild,
          ),
        ),
      ),
    );
  }

  Widget _buildStaticDecoration(double x, double y, int index) {
    List<String> placeholderImages = ['https://cdn-icons-png.flaticon.com/128/2909/2909875.png', 'https://cdn-icons-png.flaticon.com/128/2909/2909878.png', 'https://cdn-icons-png.flaticon.com/128/616/616408.png', 'https://cdn-icons-png.flaticon.com/128/201/201614.png', 'https://cdn-icons-png.flaticon.com/128/2909/2909881.png', 'https://cdn-icons-png.flaticon.com/128/3191/3191118.png'];
    return Positioned(left: x - 35, top: y - 35, child: Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.6), border: Border.all(color: Colors.white.withOpacity(0.8), width: 2), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))]), child: ClipOval(child: Padding(padding: const EdgeInsets.all(8.0), child: Image.network(placeholderImages[index % placeholderImages.length], fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.nature, color: Colors.green, size: 30))))));
  }
}

// ==========================================
// PANTALLA DE AVENTURA EN CURSO
// ==========================================
class AdventureInProgressScreen extends StatefulWidget {
  final Map<String, dynamic> adventureData; 
  final List<int> availableAdventuresIds; 

  const AdventureInProgressScreen({super.key, required this.adventureData, required this.availableAdventuresIds});

  @override
  State<AdventureInProgressScreen> createState() => _AdventureInProgressScreenState();
}

class _AdventureInProgressScreenState extends State<AdventureInProgressScreen> {
  final List<String> _dateTips = [
    "Deja el celular boca abajo, disfruta el momento.",
    "Considera dividir las cuentas, es un gesto de igualdad.",
    "Hazle una pregunta abierta y escucha con atención la respuesta.",
    "Camina a su ritmo, no te adelantes.",
    "Si hace frío, ofrécele tu chaqueta.",
    "No temas al silencio, a veces una mirada dice más que mil palabras.",
    "Sonríele, la positividad es contagiosa.",
    "Sé tú mismo, la autenticidad es el mejor encanto.",
    "Evita mirar a otras personas, enfócate en tu cita.",
    "Paga un detalle inesperado: un chocolate, una flor.",
  ];

  int _currentTipIndex = 0;
  Timer? _tipTimer;
  StreamSubscription? _partnerReviewListener;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startTipTimer();
    _listenForPartnerReview();
  }

  void _startTipTimer() {
    _tipTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _dateTips.length;
        });
      }
    });
  }

  void _listenForPartnerReview() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myUid = authProvider.user!.uid;
    final partnerId = authProvider.userData!['partnerId'];
    String coupleDocId = myUid.compareTo(partnerId) < 0 ? '${myUid}_$partnerId' : '${partnerId}_$myUid';
    bool isUser1 = myUid.compareTo(partnerId) < 0;
    String partnerReviewField = isUser1 ? 'reviewCompletedUser2' : 'reviewCompletedUser1';

    _partnerReviewListener = FirebaseFirestore.instance.collection('couples_progress').doc(coupleDocId).snapshots().listen((snapshot) {
      if (snapshot.exists && mounted && !_hasNavigated) {
        final data = snapshot.data() as Map<String, dynamic>;
        bool partnerReviewed = data[partnerReviewField] ?? false;

        if (partnerReviewed) {
          _hasNavigated = true;
          _tipTimer?.cancel();
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => AdventureReviewScreen(adventureData: widget.adventureData, availableAdventuresIds: widget.availableAdventuresIds))
          );
        }
      }
    });
  }

  void _goToReviewScreen() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _tipTimer?.cancel();
    _partnerReviewListener?.cancel(); 
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (_) => AdventureReviewScreen(adventureData: widget.adventureData, availableAdventuresIds: widget.availableAdventuresIds))
    );
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _partnerReviewListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String adventureTitle = (widget.adventureData['title'] ?? 'CITA').toUpperCase();
    final String adventureEmoji = widget.adventureData['emoji'] ?? '📍';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: FittedBox(fit: BoxFit.scaleDown, child: Text(adventureTitle, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.close, color: Colors.white38), onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(adventureEmoji, style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 40),
            
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Container(
                key: ValueKey<int>(_currentTipIndex),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white12)),
                child: Column(
                  children: [
                    const Icon(Icons.priority_high, color: Colors.amber, size: 30),
                    const SizedBox(height: 15),
                    Text(_dateTips[_currentTipIndex], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            
            const Spacer(),

            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton.icon(
                onPressed: _goToReviewScreen,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC2185B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: const Text('Finalizar Cita', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PANTALLA DE RESEÑA
// ==========================================
class AdventureReviewScreen extends StatefulWidget {
  final Map<String, dynamic> adventureData; 
  final List<int> availableAdventuresIds; 

  const AdventureReviewScreen({super.key, required this.adventureData, required this.availableAdventuresIds});

  @override
  State<AdventureReviewScreen> createState() => _AdventureReviewScreenState();
}

class _AdventureReviewScreenState extends State<AdventureReviewScreen> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  bool get _isValid {
    if (_rating == 0) return false;
    List<String> words = _reviewController.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length < 3) return false;
    return true;
  }

  Future<void> _submitReview() async {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La calificación y la descripción (mínimo 3 palabras) son obligatorias.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final myUid = authProvider.user!.uid;
      final partnerId = authProvider.userData!['partnerId'];
      
      String coupleDocId = myUid.compareTo(partnerId) < 0 ? '${myUid}_$partnerId' : '${partnerId}_$myUid';
      int adventureId = widget.adventureData['number'];
      String memoryDocId = '${coupleDocId}_$adventureId'; 
      
      bool isUser1 = myUid.compareTo(partnerId) < 0;
      String userPrefix = isUser1 ? 'user1' : 'user2';
      String myReviewField = isUser1 ? 'reviewCompletedUser1' : 'reviewCompletedUser2';
      String partnerReviewField = isUser1 ? 'reviewCompletedUser2' : 'reviewCompletedUser1';

      Map<String, dynamic> memoryData = {
        'adventure_title': widget.adventureData['title'],
        'id_adventure': adventureId.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        '$userPrefix\_rating': _rating,
        '$userPrefix\_review': _reviewController.text.trim(),
      };

      await FirebaseFirestore.instance.collection('memories').doc(memoryDocId).set(memoryData, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('couples_progress').doc(coupleDocId).update({
        myReviewField: true,
      });

      DocumentSnapshot coupleSnap = await FirebaseFirestore.instance.collection('couples_progress').doc(coupleDocId).get();
      bool partnerReviewed = coupleSnap.exists ? (coupleSnap.data() as Map<String, dynamic>)[partnerReviewField] ?? false : false;

      if (partnerReviewed) {
        debugPrint('🟢 Ambos calificaron. Subiendo de nivel...');
        
        int expEarned = widget.adventureData['xpBase'] ?? 50; 
        
        WriteBatch batch = FirebaseFirestore.instance.batch();
        DocumentReference myUserRef = FirebaseFirestore.instance.collection('users').doc(myUid);
        DocumentReference partnerUserRef = FirebaseFirestore.instance.collection('users').doc(partnerId);
        
        batch.update(myUserRef, {'exp': FieldValue.increment(expEarned)});
        batch.update(partnerUserRef, {'exp': FieldValue.increment(expEarned)});
        await batch.commit();

        Map<String, dynamic> updateData = {
          'activeAdventureNumber': FieldValue.delete(), 
          'reviewCompletedUser1': FieldValue.delete(), 
          'reviewCompletedUser2': FieldValue.delete(),
        };
        if (widget.availableAdventuresIds.isNotEmpty) {
          final random = Random();
          int nextAdventureId = widget.availableAdventuresIds[random.nextInt(widget.availableAdventuresIds.length)];
          updateData['adventurePath'] = FieldValue.arrayUnion([nextAdventureId]);
        }
        await FirebaseFirestore.instance.collection('couples_progress').doc(coupleDocId).update(updateData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.green,
            content: Text('¡Ambos calificaron! +$expEarned EXP'),
            duration: const Duration(seconds: 2),
          ));
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const CoupleMap()), (route) => false);
        }

      } else {
        debugPrint('🟡 Solo yo califiqué. Esperando a la pareja...');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('¡Calificación guardada! Esperando a tu pareja...'),
            duration: const Duration(seconds: 3),
          ));
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const CoupleMap()), (route) => false);
        }
      }

    } catch (e) {
      debugPrint('Error al guardar reseña: $e');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('¿Cómo estuvo la cita?', style: TextStyle(color: Color(0xFFC2185B), fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(widget.adventureData['emoji'] ?? '📍', style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 10),
            Text(widget.adventureData['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFFC2185B)), textAlign: TextAlign.center,),
            const SizedBox(height: 25),
            
            const Text('Califica tu experiencia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 20),

            const Align(alignment: Alignment.centerLeft, child: Text('Describe en 3 o más palabras:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            TextField(
              controller: _reviewController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej: Divertida, romántica, inolvidable...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.pinkAccent)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFC2185B), width: 2)),
              ),
              onChanged: (_) => setState(() {}), 
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isValid && !_isSubmitting ? _submitReview : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isValid ? const Color(0xFFC2185B) : Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                ),
                icon: _isSubmitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle, color: Colors.white),
                label: Text(_isSubmitting ? 'Guardando...' : 'Enviar Calificación', style: TextStyle(color: _isValid ? Colors.white : Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// PINTOR DEL CAMINO
class CandyPathPainter extends CustomPainter {
  final List<Offset> points;
  CandyPathPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i]; final next = points[i + 1];
      path.cubicTo(current.dx, current.dy + (next.dy - current.dy) * 0.8, next.dx, next.dy - (next.dy - current.dy) * 0.8, next.dx, next.dy);
    }
    
    canvas.drawPath(path.shift(const Offset(2, 4)), Paint()..color = Colors.brown.withOpacity(0.15)..strokeWidth = 20..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
    canvas.drawPath(path, Paint()..color = const Color.fromARGB(255, 255, 199, 77)..strokeWidth = 16..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}