import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TecnicosWebModule extends StatefulWidget {
  const TecnicosWebModule({super.key});

  @override
  State<TecnicosWebModule> createState() => _TecnicosWebModuleState();
}

class _TecnicosWebModuleState extends State<TecnicosWebModule> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _especialidadController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  Future<void> _registrarTecnico() async {
    if (_nombreController.text.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('mecanicos').add({
        'nombre': _nombreController.text.trim().toUpperCase(),
        'especialidad': _especialidadController.text.trim().toUpperCase(),
        'telefono': _telefonoController.text.trim(),
        'fecha_registro': FieldValue.serverTimestamp(),
        'disponible': true,
      });

      _nombreController.clear();
      _especialidadController.clear();
      _telefonoController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ TÉCNICO REGISTRADO EXITOSAMENTE"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ ERROR: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // --- FUNCIÓN ELIMINAR CORREGIDA (Sin Async Gaps) ---
  void _eliminarTecnico(String id) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: cardBlack,
        title: const Text("¿ELIMINAR TÉCNICO?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Esta acción eliminará al técnico de la base de datos.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandRed),
            onPressed: () async {
              // Capturamos las referencias necesarias antes del await
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(c);

              try {
                await FirebaseFirestore.instance.collection('mecanicos').doc(id).delete();
                
                if (!mounted) return;
                navigator.pop(); // Cerramos el diálogo usando la referencia segura
                messenger.showSnackBar(
                  const SnackBar(content: Text("🗑️ TÉCNICO ELIMINADO"), backgroundColor: Colors.orange)
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text("❌ ERROR AL ELIMINAR: $e"), backgroundColor: Colors.red)
                );
              }
            },
            child: const Text("ELIMINAR"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("GESTIÓN DE PERSONAL TÉCNICO", 
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 30),
          
          Row(
            children: [
              Expanded(child: _buildInput("Nombre Completo", _nombreController, Icons.person)),
              const SizedBox(width: 15),
              Expanded(child: _buildInput("Especialidad", _especialidadController, Icons.build)),
              const SizedBox(width: 15),
              Expanded(child: _buildInput("Teléfono", _telefonoController, Icons.phone)),
              const SizedBox(width: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandRed, 
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                onPressed: _registrarTecnico,
                icon: const Icon(Icons.add_circle, color: Colors.white),
                label: const Text("REGISTRAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),

          const SizedBox(height: 40),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('mecanicos').orderBy('nombre').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD50000)));
                
                var docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text("No hay técnicos registrados", style: TextStyle(color: Colors.white24)));

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, 
                    crossAxisSpacing: 15, 
                    mainAxisSpacing: 15, 
                    childAspectRatio: 2.8
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var t = docs[index].data() as Map<String, dynamic>;
                    return _buildTecnicoCard(docs[index].id, t);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTecnicoCard(String id, Map<String, dynamic> t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBlack, 
        borderRadius: BorderRadius.circular(10), 
        border: Border.all(color: Colors.white.withValues(alpha: 0.05))
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: brandRed.withValues(alpha: 0.1), 
            child: Icon(Icons.engineering, color: brandRed, size: 20)
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['nombre'] ?? "S/N", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis),
                Text(t['especialidad'] ?? "GENERAL", 
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18), 
            onPressed: () => _eliminarTecnico(id)
          )
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        prefixIcon: Icon(icon, color: brandRed, size: 18),
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: brandRed, width: 1)),
      ),
    );
  }
}