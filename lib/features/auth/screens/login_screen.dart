import 'package:flutter/material.dart';
import 'dart:ui'; // Para el efecto Glassmorphism (Blur)

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para capturar el texto
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Removemos el resize para que el teclado no mueva el fondo
      resizeToAvoidBottomInset: false, 
      body: Stack(
        children: [
          // ------------------------------------------------------------------
          // 1. Fondo: Degradado Púrpura a Amarillo/Naranja (Como en imagen)
          // ------------------------------------------------------------------
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFC14BF1), // Púrpura intenso arriba
                  Color(0xFFE27C9D), // Transición rosada middle
                  Color(0xFFFFD147), // Amarillo/Naranja brillante abajo
                ],
                stops: [0.0, 0.5, 1.0], // Controlar la transición
              ),
            ),
          ),
          
          // Iconos de fondo sutiles (opcional, para realismo absoluto)
          _buildBackgroundDecorations(),

          // ------------------------------------------------------------------
          // 2. Contenido Principal: Mascota, Título y Caja de Login
          // ------------------------------------------------------------------
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                children: [
                  const SizedBox(height: 10), // Espacio superior
                  
                  // Mascota Tuki (Asumiendo asset en assets/images/mascot.png)
                  // Si no lo tienes, mostrará un placeholder gris.
                  Image.asset(
                    'assets/images/mascot.png', // Reemplazar con tu asset real
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.sentiment_very_satisfied, size: 100, color: Colors.white),
                  ),

                  // Título elegant SERIF
                  const Text(
                    'Daty',
                    style: TextStyle(
                      fontFamily: 'Serif', // O usar GoogleFonts si tienes
                      fontSize: 60,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  // Subtítulo Serif Italic
                  const Text(
                    'Tu Compañero De Aventuras',
                    style: TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 16,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 35), // Espacio antes de la caja

                  // ------------------------------------------------------------
                  // Caja de Login: Glassmorphism Effect
                  // ------------------------------------------------------------
                  _buildGlassmorphismCard(),

                  const SizedBox(height: 25), // Espacio después de la caja

                  // ------------------------------------------------------------
                  // Parte inferior: "¿No tienes cuenta? ¡Regístrate!"
                  // ------------------------------------------------------------
                  TextButton(
                    onPressed: () {
                      // Navegar a la pantalla de Registro (por crear)
                      debugPrint('Navegar a Registro');
                    },
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        children: [
                          TextSpan(text: '¿No tienes cuenta? '),
                          TextSpan(
                            text: '¡Regístrate!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Icono Google (Símbolo de login social)
                  GestureDetector(
                    onTap: () {
                      debugPrint('Login con Google');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png',
                        height: 30,
                        width: 30,
                      ),
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
  }

  // --- Constructor de la Tarjeta Glassmorphism (UI Exacta) ---
  Widget _buildGlassmorphismCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Efecto borroso
        child: Container(
          padding: const EdgeInsets.all(30.0),
          decoration: BoxDecoration(
            // Fondo semi-transparente (Súper suave como en imagen)
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.3)), // Borde sutil
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campo "Usuario:"
              _buildInputLabel('Usuario:'),
              const SizedBox(height: 5),
              _buildCustomTextField(
                controller: _usernameController,
                hintText: 'Ingrese su nombre de usuario',
              ),

              const SizedBox(height: 20),

              // Campo "Contraseña:"
              _buildInputLabel('Contraseña:'),
              const SizedBox(height: 5),
              _buildCustomTextField(
                controller: _passwordController,
                hintText: 'Ingrese su contraseña de usuario',
                isPassword: true,
                obscureText: !_isPasswordVisible,
                onVisibilityToggle: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),

              const SizedBox(height: 30),

              // Botón "Entrar" (UI Exacta: Degradado azul suave)
              SizedBox(
                width: double.infinity,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF81D4FA), // Azul claro suave
                        Color(0xFF4FC3F7), // Azul un poco más intenso
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4FC3F7).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      // Lógica de Login (Usando el AuthProvider puro)
                      debugPrint('Login: ${_usernameController.text}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, // Transparente para degradado
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Entrar',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // "¿Olvidaste tu contraseña?" Italic Italic Italic
              const SizedBox(height: 15),
              Center(
                child: TextButton(
                  onPressed: () {
                    debugPrint('Olvido contraseña');
                  },
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets de ayuda para UI ---
  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onVisibilityToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9), // Casi opaco como en imagen
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
      ),
    );
  }

  // Decoraciones sutiles detrás (como en la imagen original)
  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        Positioned(top: 100, left: 30, child: Icon(Icons.calendar_month_outlined, color: Colors.white.withOpacity(0.1), size: 40)),
        Positioned(top: 250, right: 30, child: Icon(Icons.location_on_outlined, color: Colors.white.withOpacity(0.1), size: 50)),
        Positioned(bottom: 150, left: 50, child: Icon(Icons.people_outline, color: Colors.white.withOpacity(0.1), size: 60)),
      ],
    );
  }
}