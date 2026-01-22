import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _obscureText = true;

  // Colores corporativos
  final Color brandRed = const Color(0xFFD50000);
  final Color bgDark = const Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // Fondo con un gradiente sutil para que no sea negro plano
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
                    Image.asset('assets/weblogo.jpg', height: 180),
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

                    // BOTÓN OLVIDÉ MI CLAVE (Redirige a WhatsApp del taller)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () { /* Abrir WhatsApp de soporte */ },
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
                        onPressed: () {
                          // Aquí irá la lógica de Firebase Auth
                        },
                        child: const Text(
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
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
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