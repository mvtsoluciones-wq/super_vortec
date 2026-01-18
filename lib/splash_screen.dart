import 'package:flutter/material.dart';
import 'dart:async';
import 'main.dart'; // Para acceder al PlatformGuard

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Inicializar el controlador (2 segundos de duración)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // 2. Definir efecto de desvanecimiento (de invisible a opaco)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // 3. Definir efecto de tamaño con rebote (de 0.5 a 1.0 de tamaño)
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack), // Nombre correcto
    );

    // 4. INICIAR LA ANIMACIÓN
    _controller.forward();

    // 5. Temporizador para cambiar de pantalla
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PlatformGuard()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Importante para liberar memoria
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro sólido
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO
                Image.asset(
                  'assets/weblogo.jpg',
                  width: 250,
                  errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.directions_car, color: Color(0xFFD50000), size: 100),
                ),
                const SizedBox(height: 50),
                // BARRA DE CARGA
                const SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    color: Color(0xFFD50000),
                    backgroundColor: Colors.white10,
                    minHeight: 2,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "POTENCIA Y PRECISIÓN",
                  style: TextStyle(
                    color: Colors.white24,
                    letterSpacing: 4,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}