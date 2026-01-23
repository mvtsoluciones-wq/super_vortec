import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // FUNCIÓN PARA LOGUEARSE
  Future<UserCredential?> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(), 
        password: password.trim()
      );
    } catch (e) {
      // Reemplazamos print por un log básico o simplemente devolvemos null
      return null;
    }
  }

  // NUEVA FUNCIÓN: Obtener el rol del usuario (Aquí usamos _db)
  Future<String> obtenerRol(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        return doc['rol'] ?? 'cliente';
      }
      return 'cliente';
    } catch (e) {
      return 'cliente';
    }
  }

  // FUNCIÓN PARA CERRAR SESIÓN
  Future<void> logout() async => await _auth.signOut();
}