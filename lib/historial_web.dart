import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistorialWebModule extends StatefulWidget {
  const HistorialWebModule({super.key});

  @override
  State<HistorialWebModule> createState() => _HistorialWebModuleState();
}

class _HistorialWebModuleState extends State<HistorialWebModule> {
  String _busquedaPlaca = "";
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("HISTORIAL GLOBAL DE REPARACIONES", 
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 25),
        
        // --- BUSCADOR POR PLACA CORREGIDO ---
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: inputFill, 
            borderRadius: BorderRadius.circular(10)
          ),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            onChanged: (val) => setState(() => _busquedaPlaca = val.toUpperCase()),
            decoration: InputDecoration(
              hintText: "BUSCAR POR PLACA...",
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              // Uso de OutlineInputBorder para evitar el error de asignación
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), 
                borderSide: BorderSide.none
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), 
                borderSide: const BorderSide(color: Colors.white10)
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), 
                borderSide: BorderSide(color: brandRed)
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
        
        const SizedBox(height: 30),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _busquedaPlaca.isEmpty 
              ? FirebaseFirestore.instance.collection('diagnosticos').orderBy('fecha', descending: true).snapshots()
              : FirebaseFirestore.instance.collection('diagnosticos')
                  .where('placa_vehiculo', isEqualTo: _busquedaPlaca)
                  .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFD50000)));

              var docs = snapshot.data!.docs;

              if (docs.isEmpty) return const Center(child: Text("No se encontraron registros", style: TextStyle(color: Colors.white24)));

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  return _buildHistorialItem(data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistorialItem(Map<String, dynamic> data) {
    String fechaFormateada = "Sin fecha";
    if (data['fecha'] != null) {
      DateTime fecha = (data['fecha'] as Timestamp).toDate();
      fechaFormateada = DateFormat('dd/MM/yyyy - HH:mm').format(fecha);
    }
    
    bool aprobado = data['aprobado'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ExpansionTile(
        iconColor: brandRed,
        collapsedIconColor: Colors.white54,
        title: Row(
          children: [
            _urgenciaBadge(data['urgencia']),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['placa_vehiculo'] ?? "S/P", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(data['sistema_reparar'] ?? "General", style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("\$${(data['total_reparacion'] ?? 0).toStringAsFixed(2)}", style: TextStyle(color: brandRed, fontWeight: FontWeight.bold, fontSize: 18)),
                Text(aprobado ? "APROBADO" : "PENDIENTE", style: TextStyle(color: aprobado ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text("Registro: $fechaFormateada", style: const TextStyle(color: Colors.white24, fontSize: 10)),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black.withValues(alpha: 0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("DESCRIPCIÓN TÉCNICA:", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(data['descripcion_falla'] ?? "Sin descripción", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 20),
                const Text("DETALLE DE PRESUPUESTO:", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildTablePresupuesto(data['presupuesto_items'] ?? []),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTablePresupuesto(List items) {
    return Table(
      border: TableBorder.all(color: Colors.white10),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(4),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1.5),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Colors.white10),
          children: [
            _cellHeader("ITEM"), _cellHeader("DESCRIPCIÓN"), _cellHeader("CANT"), _cellHeader("TOTAL"),
          ]
        ),
        ...items.map((item) => TableRow(
          children: [
            _cellItem(item['item'] ?? ""),
            _cellItem(item['descripcion'] ?? ""),
            _cellItem(item['cantidad']?.toString() ?? "0"),
            _cellItem("\$${(item['subtotal'] ?? 0).toStringAsFixed(2)}"),
          ]
        )),
      ],
    );
  }

  Widget _cellHeader(String text) => Padding(padding: const EdgeInsets.all(8), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)));
  Widget _cellItem(String text) => Padding(padding: const EdgeInsets.all(8), child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)));

  Widget _urgenciaBadge(String? urgencia) {
    Color color = urgencia == 'Rojo' ? Colors.red : (urgencia == 'Amarillo' ? Colors.amber : Colors.green);
    return Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}