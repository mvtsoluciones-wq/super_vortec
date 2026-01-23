import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  // Colores corporativos
  final Color brandRed = const Color(0xFFD50000);
  final Color bgDark = const Color(0xFF000000);

  // --- LÓGICA DE INICIO DE SESIÓN ---
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      _showSnackBar("Por favor, rellena todos los campos", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Autenticación con Firebase
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      // 2. Verificación de Rol en Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        String rol = userDoc['rol'] ?? 'cliente';
        if (!mounted) return;
        _showSnackBar("Bienvenido, acceso como $rol concedido", Colors.green);
      }
      
    } on FirebaseAuthException catch (e) {
      String mensaje = "Error de autenticación";
      if (e.code == 'user-not-found') mensaje = "Usuario no registrado";
      if (e.code == 'wrong-password') mensaje = "Contraseña incorrecta";
      if (e.code == 'invalid-email') mensaje = "Formato de correo inválido";
      
      if (!mounted) return;
      _showSnackBar(mensaje, brandRed);
    } catch (e) {
  if (!mounted) return;
  // Esto nos dirá el código de error real (ej: [core/no-app] o [auth/network-request-failed])
  _showSnackBar("ERROR TÉCNICO: $e", Colors.purple); 
  print("DEBUG ERROR: $e"); // Esto saldrá en tu consola de VS Code
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // FONDO CON GRADIENTE (CORREGIDO: withValues en lugar de withOpacity)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [brandRed.withValues(alpha: 0.1), bgDark],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO
                    Image.asset('assets/weblogo.jpg', height: 180, 
                      errorBuilder: (context, error, stackTrace) => 
                      Icon(Icons.bolt, color: brandRed, size: 100)),
                    const SizedBox(height: 50),
                    
                    const Text(
                      "ACCESO EXCLUSIVO",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Ingresa con las credenciales proporcionadas por el taller.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                    const SizedBox(height: 40),

                    // CAMPO CORREO
                    _buildTextField(
                      controller: _emailController,
                      hint: "Correo Electrónico",
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),

                    // CAMPO CONTRASEÑA
                    _buildTextField(
                      controller: _passController,
                      hint: "Contraseña",
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                    ),
                    const SizedBox(height: 10),

                    // BOTÓN OLVIDÉ MI CLAVE
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () { /* Redirigir a soporte */ },
                        child: const Text("¿Olvidaste tu acceso?", 
                          style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // BOTÓN ENTRAR
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandRed,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 10,
                        ),
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "INICIAR SESIÓN",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    const Text("V 1.0.0 - Super Vortec 5.3", 
                      style: TextStyle(color: Colors.white10, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: brandRed),
        suffixIcon: isPassword 
          ? IconButton(
              icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            )
          : null,
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: brandRed, width: 1),
        ),
      ),
    );
  }
}