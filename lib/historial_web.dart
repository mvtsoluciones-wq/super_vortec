import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String? _tecnicoSeleccionado;
  DateTime? _fechaFiltro;

  Future<void> _abrirVideo(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir el enlace de video")),
        );
      }
    }
  }

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
        Text("REPORTE INTEGRAL DE SERVICIO", 
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        Text("Historial completo con evidencias multimedia y diagnósticos técnicos", 
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
              hintText: "BUSCAR POR PLACA O MODELO...",
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 15),
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
              context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _fechaFiltro = picked);
          },
          icon: const Icon(Icons.calendar_month, color: Colors.white, size: 18),
          label: Text(_fechaFiltro == null ? "FECHA" : DateFormat('dd/MM/yyyy').format(_fechaFiltro!)),
        ),
      ],
    );
  }

  Widget _buildTablaHistorialClientes() {
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
            itemBuilder: (context, index) => _buildReporteCard(docs[index].data() as Map<String, dynamic>),
          );
        },
      ),
    );
  }

  Widget _buildReporteCard(Map<String, dynamic> data) {
    String? videoRecepcion = data['url_video_recepcion'] ?? "";
    String? videoReparacion = data['url_evidencia_video'] ?? data['evidencia_youtube'] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05))
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // COLUMNA 1: VEHÍCULO
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['modelo_vehiculo'] ?? "S/D", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("PLACA: ${data['placa_vehiculo']}", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 15),
                    _buildVideoBtn("VIDEO RECEPCIÓN", videoRecepcion!, Icons.input_rounded),
                    const SizedBox(height: 8),
                    _buildVideoBtn("VIDEO REPARACIÓN", videoReparacion!, Icons.build_circle_outlined),
                  ],
                ),
              ),
              
              // COLUMNA 2: DIAGNÓSTICOS
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextBlock("FALLA REPORTADA (RECEPCIÓN):", data['falla_reportada'] ?? "No descrita"),
                    const SizedBox(height: 15),
                    _buildTextBlock("DIAGNÓSTICO TÉCNICO:", data['diagnostico_tecnico'] ?? "Sin diagnóstico registrado"),
                  ],
                ),
              ),

              // COLUMNA 3: ESTATUS Y FECHA
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(data['fecha_finalizacion'] != null 
                      ? DateFormat('dd/MM/yyyy').format((data['fecha_finalizacion'] as Timestamp).toDate()) : "",
                      style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                      child: const Text("ENTREGADO", style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextBlock(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: brandRed, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(content, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
      ],
    );
  }

  Widget _buildVideoBtn(String label, String url, IconData icon) {
    bool activo = url.isNotEmpty;
    return InkWell(
      onTap: activo ? () => _abrirVideo(url) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: activo ? brandRed.withValues(alpha: 0.5) : Colors.white10)
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: activo ? brandRed : Colors.white10, size: 16),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: activo ? Colors.white : Colors.white10, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}