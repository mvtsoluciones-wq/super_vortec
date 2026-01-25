import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistorialWebModule extends StatefulWidget {
  const HistorialWebModule({super.key});

  @override
  State<HistorialWebModule> createState() => _HistorialWebModuleState();
}

class _HistorialWebModuleState extends State<HistorialWebModule> {
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  String _filtroTexto = "";
  String? _tecnicoSeleccionado; // Ahora sí lo usaremos en la Query
  DateTime? _fechaFiltro;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      color: const Color(0xFF0A0A0A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          _buildFiltros(),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),
          _buildTablaHistorialClientes(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("REPORTE DE SERVICIOS - VISTA CLIENTE", 
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        Text("Estos datos se sincronizan directamente con la App móvil de Super Vortec", 
          style: TextStyle(color: Colors.white38, fontSize: 13)),
      ],
    );
  }

  Widget _buildFiltros() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            onChanged: (val) => setState(() => _filtroTexto = val.toUpperCase()),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: "BUSCAR PLACA O MODELO...",
              prefixIcon: const Icon(Icons.directions_car, color: Colors.white54),
              filled: true,
              fillColor: inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 15),
        
        // FILTRO POR TÉCNICO (Soluciona el error de unused_field)
        Expanded(
          flex: 2,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('mecanicos').orderBy('nombre').snapshots(),
            builder: (context, snapshot) {
              List<String> lista = ["TODOS LOS TÉCNICOS"];
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  lista.add(doc['nombre']);
                }
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(10)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _tecnicoSeleccionado ?? "TODOS LOS TÉCNICOS",
                    dropdownColor: cardBlack,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: lista.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setState(() => _tecnicoSeleccionado = (val == "TODOS LOS TÉCNICOS") ? null : val),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 15),
        
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _fechaFiltro == null ? inputFill : brandRed,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
          ),
          onPressed: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2024),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _fechaFiltro = picked);
          },
          icon: const Icon(Icons.event, color: Colors.white, size: 18),
          label: Text(_fechaFiltro == null ? "FECHA" : DateFormat('dd/MM/yyyy').format(_fechaFiltro!)),
        ),
      ],
    );
  }

  Widget _buildTablaHistorialClientes() {
    // Aplicamos el filtro de técnico en la consulta de Firestore
    Query query = FirebaseFirestore.instance.collection('historial_web').orderBy('fecha_finalizacion', descending: true);
    
    if (_tecnicoSeleccionado != null) {
      query = query.where('tecnico', isEqualTo: _tecnicoSeleccionado);
    }

    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            bool matchTexto = (data['placa_vehiculo'] ?? "").toString().contains(_filtroTexto) || 
                             (data['modelo_vehiculo'] ?? "").toString().toUpperCase().contains(_filtroTexto);
            
            bool matchFecha = true;
            if (_fechaFiltro != null && data['fecha_finalizacion'] != null) {
              DateTime f = (data['fecha_finalizacion'] as Timestamp).toDate();
              matchFecha = f.day == _fechaFiltro!.day && f.month == _fechaFiltro!.month && f.year == _fechaFiltro!.year;
            }
            return matchTexto && matchFecha;
          }).toList();

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return _buildClienteCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildClienteCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05))
      ),
      child: Row(
        children: [
          const Icon(Icons.stars, color: Colors.amber, size: 24),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['modelo_vehiculo'] ?? "S/D", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text("PLACA: ${data['placa_vehiculo']}", 
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          
          // Datos de interés para el Cliente (Kilometraje y Mantenimiento)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("KILOMETRAJE", style: TextStyle(color: Colors.white38, fontSize: 8)),
                Text("${data['kilometraje'] ?? '---'} KM", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 4),
                const Text("PRÓXIMO SERV.", style: TextStyle(color: Colors.white38, fontSize: 8)),
                Text(data['proximo_mantenimiento'] ?? "No programado", style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("REPORTE TÉCNICO:", style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                Text(data['instrucciones'] ?? "Mantenimiento General", 
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(data['fecha_finalizacion'] != null 
                ? DateFormat('dd MMM yyyy').format((data['fecha_finalizacion'] as Timestamp).toDate())
                : "", 
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
              const Text("ENTREGADO", style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}