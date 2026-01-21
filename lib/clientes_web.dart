import 'package:flutter/material.dart';

class ClientesWebModule extends StatefulWidget {
  const ClientesWebModule({super.key});

  @override
  State<ClientesWebModule> createState() => _ClientesWebModuleState();
}

class _ClientesWebModuleState extends State<ClientesWebModule> {
  final _formKey = GlobalKey<FormState>();

  // Colores corporativos Super Vortec
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // Lista simulada de clientes
  final List<Map<String, String>> _clientesRegistrados = [
    {"nombre": "Juan Pérez", "id": "V-12.345.678", "tel": "0414-1234567", "vehiculo": "Chevrolet Tahoe"},
    {"nombre": "Talleres ABC", "id": "J-30987654-2", "tel": "0212-5554433", "vehiculo": "Flota Mixta"},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- LADO IZQUIERDO: FORMULARIO DE REGISTRO ---
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: cardBlack,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("NUEVO CLIENTE", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 25),
                    _buildField("Nombre Completo / Razón Social", Icons.person),
                    const SizedBox(height: 15),
                    _buildField("ID / RIF", Icons.badge),
                    const SizedBox(height: 15),
                    _buildField("Teléfono de Contacto", Icons.phone),
                    const SizedBox(height: 15),
                    _buildField("Vehículo (Marca/Modelo/Año)", Icons.directions_car),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandRed, 
                          foregroundColor: Colors.white
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Lógica para guardar
                          }
                        },
                        child: const Text("REGISTRAR CLIENTE", 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),

          // --- LADO DERECHO: DIRECTORIO DE CLIENTES ---
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 20),
                _buildClientesTable(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, IconData icon) {
    return TextFormField(
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white, size: 20), // Icono Blanco
        filled: true,
        fillColor: inputFill,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), 
          borderSide: const BorderSide(color: Colors.white10)
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), 
          borderSide: BorderSide(color: brandRed)
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Buscar por nombre o ID...",
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: const Icon(Icons.search, color: Colors.white), // Icono Blanco
        filled: true,
        fillColor: cardBlack,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: const BorderSide(color: Colors.white10)
        ),
      ),
    );
  }

  Widget _buildClientesTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.02)),
        columns: const [
          DataColumn(label: Text("CLIENTE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          DataColumn(label: Text("IDENTIFICACIÓN", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          DataColumn(label: Text("VEHÍCULO", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          DataColumn(label: Text("ACCIONES", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
        ],
        rows: _clientesRegistrados.map((cliente) {
          return DataRow(cells: [
            DataCell(Text(cliente['nombre']!, style: const TextStyle(color: Colors.white, fontSize: 12))),
            DataCell(Text(cliente['id']!, style: const TextStyle(color: Colors.white70, fontSize: 12))),
            DataCell(Text(cliente['vehiculo']!, style: const TextStyle(color: Colors.white70, fontSize: 12))),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.white70), 
                  onPressed: () {}
                ),
                IconButton(
                  icon: const Icon(Icons.history, size: 18, color: Colors.white70), 
                  onPressed: () {}
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }
}