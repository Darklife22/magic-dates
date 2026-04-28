import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Extraer las iniciales del nombre de usuario
  String getInitials(String? name) {
    if (name == null || name.isEmpty) return 'AE';
    List<String> parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos al usuario actual desde el Provider
    final authProvider = Provider.of<AuthProvider>(context);
    final String userName = authProvider.user?.displayName ?? 'Aventurero';
    final String initials = getInitials(userName);

    return Scaffold(
      backgroundColor: const Color(0xFFF1E5F5), // Color lila suave del fondo
      body: Column(
        children: [
          // -----------------------------------------------------------
          // HEADER (Degradado superior con mascota y avatar)
          // -----------------------------------------------------------
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF9C27B0), // Púrpura oscuro
                  Color(0xFFCE93D8), // Transición lila
                  Color(0xFFF1E5F5), // Fonde base (se funde)
                ],
                stops: [0.0, 0.7, 1.0],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Mascota Tuki
                Image.asset(
                  'assets/images/mascot.png',
                  height: 60,
                  errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.pets, color: Colors.white, size: 50),
                ),
                // Avatar del Usuario
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFF81D4FA), // Cyan
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // -----------------------------------------------------------
          // CONTENIDO DESLIZABLE
          // -----------------------------------------------------------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                children: [
                  // Textos de Bienvenida
                  const Text(
                    'Bienvenido!',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF729BFF), // Azul claro
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    'Elige tu modo de aventura',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // -----------------------------------------------------------
                  // TARJETAS DE MODO DE JUEGO
                  // -----------------------------------------------------------
                  _buildAdventureCard(
                    title: 'Aventura solo',
                    subtitle: 'Explora por tu cuenta',
                    color: const Color(0xFF33B5FF), // Celeste
                    icon: Icons.backpack_rounded,
                    iconColor: const Color(0xFFD84315), // Naranja para contrastar
                    onTap: () {},
                  ),
                  _buildAdventureCard(
                    title: 'Aventura en pareja',
                    subtitle: 'Aventura de dos',
                    color: const Color(0xFFFF4B12), // Naranja vibrante
                    icon: Icons.favorite_rounded,
                    iconColor: const Color(0xFFF48FB1), // Rosado
                    onTap: () {},
                  ),
                  _buildAdventureCard(
                    title: 'Aventura Grupal',
                    subtitle: 'Expedición en grupo',
                    color: const Color(0xFF9D72FF), // Morado
                    icon: Icons.groups_rounded,
                    iconColor: const Color(0xFFFFD54F), // Amarillo
                    onTap: () {},
                  ),

                  const SizedBox(height: 30),

                  // -----------------------------------------------------------
                  // GALERÍA INFERIOR TIPO POLAROID
                  // -----------------------------------------------------------
                  SizedBox(
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Foto Izquierda (Rotada hacia la izquierda)
                        Positioned(
                          left: 20,
                          child: Transform.rotate(
                            angle: -0.2, // Rotación en radianes
                            child: _buildPolaroidPhoto('https://images.unsplash.com/photo-1511895426328-dc8714191300?q=80&w=200&auto=format&fit=crop'),
                          ),
                        ),
                        // Foto Derecha (Rotada hacia la derecha)
                        Positioned(
                          right: 20,
                          child: Transform.rotate(
                            angle: 0.2,
                            child: _buildPolaroidPhoto('https://images.unsplash.com/photo-1533682805518-48d1f5e8cd3e?q=80&w=200&auto=format&fit=crop'),
                          ),
                        ),
                        // Foto Central (Recta, encima de las demás)
                        Positioned(
                          child: _buildPolaroidPhoto('https://images.unsplash.com/photo-1475924156734-496f6cac6ec1?q=80&w=200&auto=format&fit=crop'),
                        ),
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
      
      // -----------------------------------------------------------
      // BARRA DE NAVEGACIÓN INFERIOR
      // -----------------------------------------------------------
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black12, spreadRadius: 0, blurRadius: 10),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black87,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 30),
                activeIcon: Icon(Icons.home_rounded, size: 30),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.photo_library_outlined, size: 30),
                activeIcon: Icon(Icons.photo_library_rounded, size: 30),
                label: 'Album',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.tune_rounded, size: 30),
                label: 'Ajustes',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget para construir cada tarjeta de modo ---
  Widget _buildAdventureCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            // Icono simulando las ilustraciones originales
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 40, color: iconColor),
            ),
            const SizedBox(width: 20),
            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget para construir las fotos tipo Polaroid ---
  Widget _buildPolaroidPhoto(String imageUrl) {
    return Container(
      width: 100,
      height: 120,
      padding: const EdgeInsets.all(5), // Borde blanco
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}