import 'package:flutter/material.dart';

class DiagnosticoWebModule extends StatefulWidget {
  const DiagnosticoWebModule({super.key});

  @override
  State<DiagnosticoWebModule> createState() => _DiagnosticoWebModuleState();
}

class _DiagnosticoWebModuleState extends State<DiagnosticoWebModule> {
  final _formKey = GlobalKey<FormState>();
  
  // Variables de control
  String _semaforoSeleccionado = 'Verde'; 
  String? _clienteSeleccionado;
  String? _presupuestoSeleccionado;
  
  // Listas simuladas
  final List<String> _clientes = ['Juan Pérez', 'Talleres ABC', 'María García'];
  final List<String> _presupuestos = ['Presupuesto #001 - Motor', 'Presupuesto #002 - Frenos'];

  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

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
                  Expanded(child: _buildDropdown("Seleccionar Cliente", _clientes, _clienteSeleccionado, (val) => setState(() => _clienteSeleccionado = val))),
                  const SizedBox(width: 20),
                  Expanded(child: _buildDropdown("Vincular Presupuesto", _presupuestos, _presupuestoSeleccionado, (val) => setState(() => _presupuestoSeleccionado = val))),
                ],
              ),
              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(child: _buildField("Link Informe Escáner", Icons.qr_code_scanner, hint: "URL del PDF o imagen")),
                  const SizedBox(width: 20),
                  Expanded(child: _buildField("Link Video Falla (YouTube)", Icons.play_circle_fill, hint: "URL de video")),
                ],
              ),
              const SizedBox(height: 25),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildField("Descripción del Diagnóstico", Icons.description, maxLines: 4),
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
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white), // Icono Blanco
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
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("DIAGNÓSTICO GUARDADO CORRECTAMENTE"))
                          );
                        }
                      },
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
        child: Icon(Icons.traffic, color: isSelected ? color : Colors.white, size: 30), // Icono Blanco cuando no está seleccionado
      ),
    );
  }

  Color _getColorSemaforo() {
    if (_semaforoSeleccionado == 'Rojo') return Colors.red;
    if (_semaforoSeleccionado == 'Amarillo') return Colors.amber;
    return Colors.green;
  }

  Widget _buildField(String label, IconData icon, {int maxLines = 1, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextFormField(
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white12),
            prefixIcon: Icon(icon, color: Colors.white, size: 20), // Icono Blanco
            filled: true,
            fillColor: inputFill,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: brandRed, width: 1)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? currentVal, Function(String?) onChanged) {
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
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white), // Icono de flecha en Blanco
              style: const TextStyle(color: Colors.white),
              hint: const Text("Seleccionar...", style: TextStyle(color: Colors.white24, fontSize: 14)),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}