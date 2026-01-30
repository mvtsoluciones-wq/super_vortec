import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// TUS PANTALLAS DE DESTINO
import 'admin_panel.dart'; // La pantalla del dueño
import 'main.dart'; // La pantalla principal de la App (Cliente)

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

  final Color brandRed = const Color(0xFFD50000);
  final Color bgDark = const Color(0xFF000000);

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      _showSnackBar("Por favor, rellena todos los campos", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // PASO 1: Validar credenciales (Email y Contraseña) en Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passController.text.trim(),
          );

      User? user = userCredential.user;

      if (user != null) {
        // PASO 2: EL PORTERO (Consultar vinculación por correo en Firestore)
        // Buscamos en la colección 'clientes' el documento que tenga ese email
        var userQuery = await FirebaseFirestore.instance
            .collection('clientes')
            .where(
              'email',
              isEqualTo: _emailController.text.trim().toLowerCase(),
            )
            .get();

        if (userQuery.docs.isNotEmpty) {
          // Extraemos los datos del primer documento encontrado
          var userData = userQuery.docs.first.data();
          String rol = userData['rol'] ?? 'cliente';

          if (!mounted) return;

          // PASO 3: REDIRECCIÓN INTELIGENTE
          if (rol == 'admin') {
            debugPrint("Acceso Admin detectado");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminControlPanel(),
              ),
            );
          } else {
            debugPrint("Acceso Cliente detectado");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ClientHomeScreen()),
            );
          }
        } else {
          // CASO: El usuario existe en Auth pero no está registrado/habilitado en la colección 'clientes'
          if (!mounted) return;
          _showSnackBar(
            "Tu cuenta no ha sido habilitada por el Taller.",
            Colors.redAccent,
          );
          await FirebaseAuth.instance
              .signOut(); // Seguridad: cerrar sesión si no está en la DB
        }
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = "Error de acceso";
      if (e.code == 'user-not-found') mensaje = "Usuario no registrado";
      if (e.code == 'wrong-password') mensaje = "Contraseña incorrecta";
      if (e.code == 'network-request-failed')
        mensaje = "Sin conexión a internet";
      if (!mounted) return;
      _showSnackBar(mensaje, brandRed);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Error técnico: $e", Colors.purple);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/weblogo.jpg',
                height: 150,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.bolt, size: 100, color: brandRed),
              ),
              const SizedBox(height: 40),
              const Text(
                "JM PERFORMANCE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Correo",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.email, color: brandRed),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _passController,
                obscureText: _obscureText,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Contraseña",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.lock, color: brandRed),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscureText = !_obscureText),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: brandRed),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "ENTRAR",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
}
