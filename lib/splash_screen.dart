import 'package:flutter/material.dart';
import 'dart:async';
import 'main.dart'; // Importante para conectar con el PlatformGuard

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

    // Duración total de la animación de los elementos
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Configuración del desvanecimiento
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Configuración del tamaño con el rebote corregido (easeOutBack)
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // Arranca la animación apenas carga el widget
    _controller.forward();

    // Espera 4 segundos en total antes de cambiar de pantalla
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Asegúrate de que la ruta del logo sea correcta en tu pubspec.yaml
                Image.asset(
                  'assets/weblogo.jpg',
                  width: 250,
                  errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.directions_car, color: Color(0xFFD50000), size: 100),
                ),
                const SizedBox(height: 50),
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