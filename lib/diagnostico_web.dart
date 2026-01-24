import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DiagnosticoWebModule extends StatefulWidget {
  const DiagnosticoWebModule({super.key});

  @override
  State<DiagnosticoWebModule> createState() => _DiagnosticoWebModuleState();
}

class _DiagnosticoWebModuleState extends State<DiagnosticoWebModule> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _scannerController = TextEditingController();
  final TextEditingController _videoController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // Variables de control
  String _semaforoSeleccionado = 'Verde'; 
  String? _clienteSeleccionado; 
  String? _vehiculoSeleccionado;

  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  Future<void> _guardarDiagnostico() async {
    if (_vehiculoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ DEBE SELECCIONE UN VEHÍCULO"), backgroundColor: Colors.orange),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator(color: Color(0xFFD50000))),
    );

    try {
      await FirebaseFirestore.instance.collection('diagnosticos').add({
        'placa_vehiculo': _vehiculoSeleccionado,
        'cliente_id': _clienteSeleccionado,
        'link_escanner': _scannerController.text.trim(),
        'link_video': _videoController.text.trim(),
        'descripcion': _descController.text.trim().toUpperCase(),
        'urgencia': _semaforoSeleccionado,
        'fecha': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ DIAGNÓSTICO PUBLICADO"), backgroundColor: Colors.green),
      );

      _formKey.currentState!.reset();
      _scannerController.clear();
      _videoController.clear();
      _descController.clear();
      setState(() {
        _vehiculoSeleccionado = null;
        _clienteSeleccionado = null;
      });

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: cardBlack,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 15))],
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("PANEL DE DIAGNÓSTICO AVANZADO", 
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 35),
              
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('clientes').snapshots(),
                      builder: (context, snapshot) {
                        List<DropdownMenuItem<String>> clientItems = [];
                        if (snapshot.hasData) {
                          for (var doc in snapshot.data!.docs) {
                            clientItems.add(DropdownMenuItem(
                              value: doc.id,
                              child: Text(doc['nombre'].toString().toUpperCase()),
                            ));
                          }
                        }
                        return _buildDropdownCustom("1. Buscar Cliente", clientItems, _clienteSeleccionado, (val) {
                          setState(() {
                            _clienteSeleccionado = val;
                            _vehiculoSeleccionado = null;
                          });
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _clienteSeleccionado == null 
                      ? _buildDisabledDropdown("2. Seleccionar Vehículo", "Primero elija un cliente")
                      : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('vehiculos')
                              .where('propietario_id', isEqualTo: _clienteSeleccionado)
                              .snapshots(),
                          builder: (context, snapshot) {
                            List<DropdownMenuItem<String>> vehicleItems = [];
                            if (snapshot.hasData) {
                              for (var doc in snapshot.data!.docs) {
                                vehicleItems.add(DropdownMenuItem(
                                  value: doc.id,
                                  child: Text("${doc.id} - ${doc['marca']} ${doc['modelo']}"),
                                ));
                              }
                            }
                            return _buildDropdownCustom("2. Seleccionar Vehículo", vehicleItems, _vehiculoSeleccionado, (val) {
                              setState(() => _vehiculoSeleccionado = val);
                            });
                          },
                        ),
                  ),
                ],
              ),
              
              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(child: _buildField("Link Informe Escáner", Icons.qr_code_scanner, controller: _scannerController, hint: "URL del informe")),
                  const SizedBox(width: 20),
                  Expanded(child: _buildField("Link Video Falla (YouTube)", Icons.play_circle_fill, controller: _videoController, hint: "URL de video")),
                ],
              ),
              const SizedBox(height: 25),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildField("Descripción del Diagnóstico", Icons.description, controller: _descController, maxLines: 4),
                  ),
                  const SizedBox(width: 25),
                  Expanded(
                    flex: 1,
                    child: _buildSemaforoSelector(),
                  ),
                ],
              ),

              const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Divider(color: Colors.white10)),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: brandRed),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("AGREGAR FALLA AL LISTADO"),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandRed,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      onPressed: _guardarDiagnostico,
                      child: const Text("GUARDAR DIAGNÓSTICO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownCustom(String label, List<DropdownMenuItem<String>> items, String? currentVal, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentVal,
              isExpanded: true,
              dropdownColor: cardBlack,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(color: Colors.white),
              hint: const Text("Seleccionar...", style: TextStyle(color: Colors.white24, fontSize: 14)),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisabledDropdown(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: inputFill.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
          child: Text(hint, style: const TextStyle(color: Colors.white12, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildSemaforoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("NIVEL DE URGENCIA", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _semaforoIcon(Colors.green, 'Verde'),
            _semaforoIcon(Colors.amber, 'Amarillo'),
            _semaforoIcon(Colors.red, 'Rojo'),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(_semaforoSeleccionado.toUpperCase(), 
            style: TextStyle(color: _getColorSemaforo(), fontWeight: FontWeight.bold, fontSize: 12)),
        )
      ],
    );
  }

  Widget _semaforoIcon(Color color, String label) {
    bool isSelected = _semaforoSeleccionado == label;
    return GestureDetector(
      onTap: () => setState(() => _semaforoSeleccionado = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? color : Colors.white10, width: 2),
        ),
        child: Icon(Icons.traffic, color: isSelected ? color : Colors.white, size: 30),
      ),
    );
  }

  Color _getColorSemaforo() {
    if (_semaforoSeleccionado == 'Rojo') return Colors.red;
    if (_semaforoSeleccionado == 'Amarillo') return Colors.amber;
    return Colors.green;
  }

  Widget _buildField(String label, IconData icon, {int maxLines = 1, String? hint, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          validator: (val) => (val == null || val.isEmpty) ? "Campo obligatorio" : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white12),
            prefixIcon: Icon(icon, color: Colors.white, size: 20),
            filled: true,
            fillColor: inputFill,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: brandRed, width: 1)),
          ),
        ),
      ],
    );
  }
}