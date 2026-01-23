import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientesWebModule extends StatefulWidget {
  const ClientesWebModule({super.key});

  @override
  State<ClientesWebModule> createState() => _ClientesWebModuleState();
}

class _ClientesWebModuleState extends State<ClientesWebModule> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Colores corporativos
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // Controladores
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _cedulaCtrl = TextEditingController();
  final TextEditingController _telCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _dirCtrl = TextEditingController();
  final TextEditingController _vehiculoCtrl = TextEditingController();

  // --- FUNCIÓN PARA GUARDAR EN FIRESTORE ---
  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Usamos la cédula como ID del documento para que sea único
      String docId = _cedulaCtrl.text.trim().toUpperCase();

      await _db.collection('usuarios').doc(docId).set({
        'nombre': _nombreCtrl.text.trim().toUpperCase(),
        'cedula': docId,
        'telefono': _telCtrl.text.trim(),
        'email': _emailCtrl.text.trim().toLowerCase(),
        'direccion': _dirCtrl.text.trim().toUpperCase(),
        'vehiculo_inicial': _vehiculoCtrl.text.trim().toUpperCase(),
        'rol': 'cliente',
        'acceso_app': false, // Por defecto no tiene acceso hasta que tú lo crees
        'fecha_registro': FieldValue.serverTimestamp(),
      });

      _limpiarFormulario();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("CLIENTE GUARDADO EN LA NUBE"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ERROR AL GUARDAR: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // --- FUNCIÓN PARA CREAR ACCESO A LA APP (FIREBASE AUTH) ---
  Future<void> _habilitarAccesoApp(Map<String, dynamic> datosCliente) async {
    // Aquí podrías abrir un diálogo para pedir una contraseña temporal
    String tempPassword = "Vortec${datosCliente['cedula'].replaceAll(RegExp(r'[^0-9]'), '')}";

    try {
      // 1. Crear usuario en Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: datosCliente['email'],
        password: tempPassword,
      );

      // 2. Actualizar el documento en Firestore con el UID de Auth
      await _db.collection('usuarios').doc(datosCliente['cedula']).update({
        'uid': userCredential.user!.uid,
        'acceso_app': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ACCESO CREADO. CLAVE: $tempPassword"), backgroundColor: Colors.blue),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ERROR: El usuario ya existe o datos inválidos"), backgroundColor: Colors.red),
      );
    }
  }

  void _limpiarFormulario() {
    _nombreCtrl.clear(); _cedulaCtrl.clear(); _telCtrl.clear();
    _emailCtrl.clear(); _dirCtrl.clear(); _vehiculoCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- FORMULARIO IZQUIERDO ---
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: cardBlack,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("REGISTRO DE CLIENTE", style: TextStyle(color: brandRed, fontWeight: FontWeight.w900, fontSize: 18)),
                      const SizedBox(height: 25),
                      _buildField("Nombre Completo", _nombreCtrl, Icons.person),
                      const SizedBox(height: 15),
                      _buildField("Cédula / RIF", _cedulaCtrl, Icons.badge),
                      const SizedBox(height: 15),
                      _buildField("Teléfono", _telCtrl, Icons.phone),
                      const SizedBox(height: 15),
                      _buildField("Email", _emailCtrl, Icons.alternate_email),
                      const SizedBox(height: 15),
                      _buildField("Dirección", _dirCtrl, Icons.location_on),
                      const SizedBox(height: 15),
                      _buildField("Vehículo", _vehiculoCtrl, Icons.directions_car),
                      const SizedBox(height: 30),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),

          // --- TABLA DERECHA CON STREAM (TIEMPO REAL) ---
          Expanded(
            flex: 2,
            child: _buildRealTimeTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white),
        onPressed: _guardarCliente,
        icon: const Icon(Icons.cloud_upload),
        label: const Text("GUARDAR EN BASE DE DATOS", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRealTimeTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('usuarios').where('rol', isEqualTo: 'cliente').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
          child: DataTable(
            columns: const [
              DataColumn(label: Text("CLIENTE")),
              DataColumn(label: Text("CÉDULA")),
              DataColumn(label: Text("ACCESO APP")),
              DataColumn(label: Text("ACCIONES")),
            ],
            rows: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              bool tieneAcceso = data['acceso_app'] ?? false;

              return DataRow(cells: [
                DataCell(Text(data['nombre'], style: const TextStyle(color: Colors.white, fontSize: 13))),
                DataCell(Text(data['cedula'], style: const TextStyle(color: Colors.white70))),
                DataCell(_buildStatusBadge(tieneAcceso)),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.vpn_key, color: tieneAcceso ? Colors.green : Colors.blue),
                      tooltip: tieneAcceso ? "Acceso Activo" : "Habilitar Acceso App",
                      onPressed: tieneAcceso ? null : () => _habilitarAccesoApp(data),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        );
      }
    );
  }

  Widget _buildStatusBadge(bool status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status ? "ACTIVO" : "PENDIENTE", 
        style: TextStyle(color: status ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white70, size: 20),
            filled: true, fillColor: inputFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}