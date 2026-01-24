import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DiagnosticoWebModule extends StatefulWidget {
  const DiagnosticoWebModule({super.key});

  @override
  State<DiagnosticoWebModule> createState() => _DiagnosticoWebModuleState();
}

class _DiagnosticoWebModuleState extends State<DiagnosticoWebModule> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores principales
  final TextEditingController _tituloFallaController = TextEditingController();
  final TextEditingController _garantiaController = TextEditingController();
  final TextEditingController _scannerController = TextEditingController();
  final TextEditingController _videoController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // --- LÓGICA DE PRESUPUESTO DINÁMICO ---
  List<Map<String, dynamic>> _itemsPresupuesto = [
    {
      'item': TextEditingController(),
      'desc': TextEditingController(),
      'cant': TextEditingController(text: "1"),
      'precio': TextEditingController(),
    }
  ];

  String _semaforoSeleccionado = 'Verde'; 
  String? _clienteSeleccionado; 
  String? _vehiculoSeleccionado;

  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  double _calcularTotalFalla() {
    double total = 0;
    for (var item in _itemsPresupuesto) {
      double c = double.tryParse(item['cant'].text) ?? 0;
      double p = double.tryParse(item['precio'].text) ?? 0;
      total += (c * p);
    }
    return total;
  }

  void _agregarFilaPresupuesto() {
    setState(() {
      _itemsPresupuesto.add({
        'item': TextEditingController(),
        'desc': TextEditingController(),
        'cant': TextEditingController(text: "1"),
        'precio': TextEditingController(),
      });
    });
  }

  Future<void> _guardarDiagnostico() async {
    if (_vehiculoSeleccionado == null) {
      _showSnack("⚠️ SELECCIONE UN VEHÍCULO", Colors.orange);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator(color: Color(0xFFD50000))),
    );

    try {
      // Mapear los ítems de la tabla para Firebase
      List<Map<String, dynamic>> presupuestoFinal = _itemsPresupuesto.map((e) {
        double c = double.tryParse(e['cant'].text) ?? 0;
        double p = double.tryParse(e['precio'].text) ?? 0;
        return {
          'item': e['item'].text.toUpperCase(),
          'descripcion': e['desc'].text.toUpperCase(),
          'cantidad': c,
          'precio_unitario': p,
          'subtotal': c * p,
        };
      }).toList();

      await FirebaseFirestore.instance.collection('diagnosticos').add({
        'placa_vehiculo': _vehiculoSeleccionado,
        'cliente_id': _clienteSeleccionado,
        'sistema_reparar': _tituloFallaController.text.trim().toUpperCase(),
        'total_reparacion': _calcularTotalFalla(),
        'garantia': _garantiaController.text.trim().toUpperCase(),
        'link_escanner': _scannerController.text.trim(),
        'link_video': _videoController.text.trim(),
        'descripcion_falla': _descController.text.trim().toUpperCase(),
        'urgencia': _semaforoSeleccionado,
        'presupuesto_items': presupuestoFinal, 
        'aprobado': false,
        'fecha': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);

      _showSnack("✅ DIAGNÓSTICO PUBLICADO EXITOSAMENTE", Colors.green);
      _limpiarFormulario();
      
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack("Error: $e", Colors.red);
    }
  }

  void _limpiarFormulario() {
    _tituloFallaController.clear();
    _garantiaController.clear();
    _descController.clear();
    _videoController.clear();
    _scannerController.clear();
    setState(() {
      _itemsPresupuesto = [
        {'item': TextEditingController(), 'desc': TextEditingController(), 'cant': TextEditingController(text: "1"), 'precio': TextEditingController()}
      ];
      _vehiculoSeleccionado = null;
    });
  }

  void _showSnack(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));

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
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("GENERADOR DE DIAGNÓSTICO Y PRESUPUESTO", 
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 35),
              
              _buildSelectorVehiculo(),
              
              const Divider(color: Colors.white10, height: 60),

              _buildField("Sistema a Reparar (Ej: MODULO ABS)", Icons.settings_applications, controller: _tituloFallaController),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(flex: 2, child: _buildField("Descripción Técnica de la Falla", Icons.description, controller: _descController, maxLines: 3)),
                  const SizedBox(width: 25),
                  Expanded(flex: 1, child: _buildSemaforoSelector()),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: _buildField("Link Informe Escáner", Icons.qr_code_scanner, controller: _scannerController)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildField("Link Video Evidencia", Icons.play_circle_fill, controller: _videoController)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildField("Garantía", Icons.verified, controller: _garantiaController, hint: "Ej: 6 Meses")),
                ],
              ),

              const Divider(color: Colors.white10, height: 60),

              const Text("PRESUPUESTO DESGLOSADO", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildPresupuestoTable(),
              
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "TOTAL: \$${_calcularTotalFalla().toStringAsFixed(2)}", 
                  style: TextStyle(color: brandRed, fontSize: 22, fontWeight: FontWeight.bold)
                ),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: brandRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _guardarDiagnostico,
                  icon: const Icon(Icons.cloud_upload, color: Colors.white),
                  label: const Text("GUARDAR DIAGNÓSTICO EN HISTORIAL", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorVehiculo() {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('clientes').snapshots(),
            builder: (context, snapshot) {
              List<DropdownMenuItem<String>> clientItems = snapshot.hasData ? snapshot.data!.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['nombre'].toString().toUpperCase()))).toList() : [];
              return _buildDropdownCustom("1. Seleccionar Cliente", clientItems, _clienteSeleccionado, (val) {
                setState(() { _clienteSeleccionado = val; _vehiculoSeleccionado = null; });
              });
            },
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _clienteSeleccionado == null 
            ? _buildDisabledDropdown("2. Seleccionar Vehículo", "Primero elija un cliente")
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('vehiculos').where('propietario_id', isEqualTo: _clienteSeleccionado).snapshots(),
                builder: (context, snapshot) {
                  List<DropdownMenuItem<String>> vehicleItems = snapshot.hasData ? snapshot.data!.docs.map((d) => DropdownMenuItem(value: d.id, child: Text("${d.id} - ${d['marca']}"))).toList() : [];
                  return _buildDropdownCustom("2. Seleccionar Vehículo", vehicleItems, _vehiculoSeleccionado, (val) => setState(() => _vehiculoSeleccionado = val));
                },
              ),
        ),
      ],
    );
  }

  Widget _buildPresupuestoTable() {
    return Container(
      decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(flex: 2, child: _headerText("ITEM")),
                const SizedBox(width: 10),
                Expanded(flex: 4, child: _headerText("DESCRIPCIÓN")),
                const SizedBox(width: 10),
                Expanded(flex: 1, child: _headerText("CANT")),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: _headerText("PRECIO \$")),
                const SizedBox(width: 40),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          ..._itemsPresupuesto.asMap().entries.map((entry) {
            int index = entry.key;
            var row = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: Row(
                children: [
                  Expanded(flex: 2, child: _tableInput(row['item'], "Item")),
                  const SizedBox(width: 10),
                  Expanded(flex: 4, child: _tableInput(row['desc'], "Descripción")),
                  const SizedBox(width: 10),
                  Expanded(flex: 1, child: _tableInput(row['cant'], "1", isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: _tableInput(row['precio'], "0.00", isNumber: true)),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                    onPressed: () => setState(() => _itemsPresupuesto.removeAt(index)),
                  )
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: _agregarFilaPresupuesto,
            icon: const Icon(Icons.add_circle, color: Colors.green),
            label: const Text("AGREGAR OTRO ÍTEM AL PRESUPUESTO", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---
  Widget _headerText(String label) => Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold));
  Widget _tableInput(TextEditingController controller, String hint, {bool isNumber = false}) => TextField(controller: controller, keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, onChanged: (v) => setState(() {}), style: const TextStyle(color: Colors.white, fontSize: 13), decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white10), isDense: true, filled: true, fillColor: cardBlack, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)));
  Widget _buildDropdownCustom(String label, List<DropdownMenuItem<String>> items, String? currentVal, Function(String?) onChanged) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(10)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: currentVal, isExpanded: true, dropdownColor: cardBlack, icon: const Icon(Icons.arrow_drop_down, color: Colors.white), style: const TextStyle(color: Colors.white), items: items, onChanged: onChanged)))]);
  Widget _buildDisabledDropdown(String label, String hint) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: inputFill.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)), child: Text(hint, style: const TextStyle(color: Colors.white12, fontSize: 14)))]);
  Widget _buildSemaforoSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("URGENCIA", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
      const SizedBox(height: 15),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_semaforoIcon(Colors.green, 'Verde'), _semaforoIcon(Colors.amber, 'Amarillo'), _semaforoIcon(Colors.red, 'Rojo')]),
      const SizedBox(height: 10),
      Center(child: Text(_semaforoSeleccionado.toUpperCase(), style: TextStyle(color: _getColorSemaforo(), fontWeight: FontWeight.bold, fontSize: 12)))
    ]);
  }
  Widget _semaforoIcon(Color color, String label) {
    bool isSelected = _semaforoSeleccionado == label;
    return GestureDetector(onTap: () => setState(() => _semaforoSeleccionado = label), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent, shape: BoxShape.circle, border: Border.all(color: isSelected ? color : Colors.white10, width: 2)), child: Icon(Icons.traffic, color: isSelected ? color : Colors.white, size: 30)));
  }
  Color _getColorSemaforo() => _semaforoSeleccionado == 'Rojo' ? Colors.red : (_semaforoSeleccionado == 'Amarillo' ? Colors.orange : Colors.green);
  Widget _buildField(String label, IconData icon, {int maxLines = 1, TextEditingController? controller, String? hint}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(height: 10), TextFormField(controller: controller, maxLines: maxLines, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white10), prefixIcon: Icon(icon, color: Colors.white, size: 20), filled: true, fillColor: inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: brandRed, width: 1))))]);
}