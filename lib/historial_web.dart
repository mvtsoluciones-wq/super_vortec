import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistorialWebModule extends StatefulWidget {
  const HistorialWebModule({super.key});

  @override
  State<HistorialWebModule> createState() => _HistorialWebModuleState();
}

class _HistorialWebModuleState extends State<HistorialWebModule> {
  String _filtroNombre = "";
  String? _clienteId;
  String? _clienteNombre;

  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // --- LÓGICA DE TIEMPOS Y GARANTÍA ---
  Widget _buildGarantiaStatus(Map<String, dynamic> data) {
    if (data['fecha'] == null) return const SizedBox();
    
    DateTime fechaFinalizado = (data['fecha'] as Timestamp).toDate();
    int diasDesdeReparacion = DateTime.now().difference(fechaFinalizado).inDays;
    
    // Extraer número de meses de la garantía (ej: "6 MESES" -> 6)
    int mesesGarantia = int.tryParse(data['garantia']?.toString().split(' ')[0] ?? '0') ?? 0;
    DateTime fechaVencimiento = DateTime(fechaFinalizado.year, fechaFinalizado.month + mesesGarantia, fechaFinalizado.day);
    int diasParaVencer = fechaVencimiento.difference(DateTime.now()).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("REALIZADO HACE: $diasDesdeReparacion DÍAS", 
          style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        if (mesesGarantia > 0)
          Text(
            diasParaVencer < 0 ? "⚠️ GARANTÍA EXPIRADA" : "QUEDAN $diasParaVencer DÍAS DE GARANTÍA",
            style: TextStyle(
              color: diasParaVencer < 0 ? Colors.red : Colors.greenAccent, 
              fontSize: 11, 
              fontWeight: FontWeight.w900
            )
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_clienteId == null ? "HISTORIAL DE TRABAJOS ENTREGADOS" : "CLIENTE: ${_clienteNombre?.toUpperCase()}", 
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const Spacer(),
            if (_clienteId != null)
              OutlinedButton.icon(
                onPressed: () => setState(() { _clienteId = null; }),
                icon: const Icon(Icons.arrow_back, size: 16, color: Colors.black),
                label: const Text("VOLVER", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Colors.black, width: 2)),
              )
          ],
        ),
        const SizedBox(height: 25),
        _clienteId == null ? _buildBuscadorClientes() : _buildListaFinalizados(),
      ],
    );
  }

  Widget _buildBuscadorClientes() {
    return Expanded(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(10)),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() => _filtroNombre = val.toUpperCase()),
              decoration: const InputDecoration(hintText: "BUSCAR CLIENTE POR NOMBRE...", prefixIcon: Icon(Icons.person_search, color: Colors.white54), border: InputBorder.none, contentPadding: EdgeInsets.all(20)),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('clientes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs.where((doc) => doc['nombre'].toString().toUpperCase().contains(_filtroNombre)).toList();
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var c = docs[index];
                    return ListTile(
                      onTap: () => setState(() { _clienteId = c.id; _clienteNombre = c['nombre']; }),
                      leading: CircleAvatar(backgroundColor: brandRed, child: const Icon(Icons.history, color: Colors.white)),
                      title: Text(c['nombre'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text("ID: ${c.id}", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaFinalizados() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('diagnosticos')
            .where('cliente_id', isEqualTo: _clienteId)
            .where('finalizado', isEqualTo: true) // <--- SOLO LOS TERMINADOS
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("Sin trabajos finalizados registrados", style: TextStyle(color: Colors.white24)));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return _buildHistorialCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistorialCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: ExpansionTile(
        iconColor: brandRed,
        title: Row(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data['modelo_vehiculo']?.toString().toUpperCase() ?? "VEHÍCULO", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text("SISTEMA: ${data['sistema_reparar']}", style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ]),
            const Spacer(),
            Text("\$${(data['total_reparacion'] ?? 0).toStringAsFixed(2)}", style: TextStyle(color: brandRed, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        subtitle: _buildGarantiaStatus(data),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black.withValues(alpha: 0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("REPORTE TÉCNICO: ${data['descripcion_falla']}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 15),
                const Text("GARANTÍA ORIGINAL:", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(data['garantia'] ?? "SIN ESPECIFICAR", style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}