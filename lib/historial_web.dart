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
  DateTime? _fechaFiltro;

  // --- FUNCIÓN PARA ABRIR VIDEO ---
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

  // --- LÓGICA DE TIEMPOS Y GARANTÍAS ---
  String _calcularTiempoDesdeEntrega(DateTime fechaFin) {
    final diferencia = DateTime.now().difference(fechaFin).inDays;
    if (diferencia == 0) return "ENTREGADO HOY";
    return "HACE $diferencia DÍAS";
  }

  Map<String, dynamic> _calcularGarantia(DateTime fechaFin, int diasGarantia) {
    final fechaVencimiento = fechaFin.add(Duration(days: diasGarantia));
    final restante = fechaVencimiento.difference(DateTime.now()).inDays;
    return {
      "restante": restante < 0 ? 0 : restante,
      "vencida": restante < 0,
    };
  }

  // --- DIÁLOGO DE DETALLE DE PRESUPUESTO ---
  void _mostrarPresupuestoDetalle(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBlack,
        title: Text("DETALLE DE PRESUPUESTO APROBADO", 
          style: TextStyle(color: brandRed, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("TOTAL APROBADO: \$${data['presupuesto_total'] ?? '0.00'}", 
              style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.w900)),
            const Divider(color: Colors.white10, height: 20),
            const Text("OBSERVACIONES COMERCIALES:", style: TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 5),
            Text(data['notas_presupuesto'] ?? "Sin notas adicionales.", 
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CERRAR")),
        ],
      ),
    );
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
          _buildListaHistorial(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("HISTORIAL DE SERVICIOS Y GARANTÍAS", 
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        Text("Control de post-venta, tiempos de protección y presupuestos", 
          style: TextStyle(color: Colors.white38, fontSize: 13)),
      ],
    );
  }

  Widget _buildFiltros() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (val) => setState(() => _filtroTexto = val.toUpperCase()),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: "BUSCAR POR PLACA O MODELO...",
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true, fillColor: inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
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
          label: Text(_fechaFiltro == null ? "FILTRAR FECHA" : DateFormat('dd/MM/yyyy').format(_fechaFiltro!)),
        ),
      ],
    );
  }

  Widget _buildListaHistorial() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('historial_web').orderBy('fecha_finalizacion', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            bool matchTexto = (data['placa_vehiculo'] ?? "").toString().contains(_filtroTexto) || 
                             (data['modelo_vehiculo'] ?? "").toString().toUpperCase().contains(_filtroTexto);
            return matchTexto;
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
    DateTime fechaFin = (data['fecha_finalizacion'] as Timestamp).toDate();
    int diasGarantia = data['dias_garantia'] ?? 30;
    var infoGarantia = _calcularGarantia(fechaFin, diasGarantia);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
              // COLUMNA 1: VEHÍCULO Y VIDEOS
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['modelo_vehiculo'] ?? "S/D", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("PLACA: ${data['placa_vehiculo']}", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 20),
                    _buildVideoBtn("VIDEO RECEPCIÓN", data['url_video_recepcion'] ?? "", Icons.videocam),
                    const SizedBox(height: 10),
                    _buildVideoBtn("VIDEO REPARACIÓN", data['url_evidencia_video'] ?? "", Icons.play_circle_fill),
                  ],
                ),
              ),
              
              // COLUMNA 2: DETALLES TÉCNICOS Y GARANTÍAS
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextBlock("FALLA DE ENTRADA:", data['falla_reportada'] ?? "No especificada"),
                      const SizedBox(height: 15),
                      _buildTextBlock("DETALLE DEL DIAGNÓSTICO:", data['diagnostico_tecnico'] ?? "Sin detalle técnico"),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoRow("GARANTÍA TOTAL:", "$diasGarantia DÍAS"),
                          _buildInfoRow("RESTANTE:", "${infoGarantia['restante']} DÍAS", 
                            color: infoGarantia['vencida'] ? Colors.red : Colors.greenAccent),
                        ],
                      ),
                      const SizedBox(height: 5),
                      _buildInfoRow("TIEMPO DESDE ENTREGA:", _calcularTiempoDesdeEntrega(fechaFin)),
                    ],
                  ),
                ),
              ),

              // COLUMNA 3: PRESUPUESTO Y ESTADO
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("MONTO APROBADO", style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                    Text("\$${data['presupuesto_total'] ?? '0.00'}", 
                      style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        side: const BorderSide(color: Colors.white12)
                      ),
                      onPressed: () => _mostrarPresupuestoDetalle(data),
                      icon: const Icon(Icons.receipt_long, size: 14),
                      label: const Text("VER PRESUPUESTO", style: TextStyle(fontSize: 10)),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: infoGarantia['vencida'] ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Text(infoGarantia['vencida'] ? "GARANTÍA EXPIRADA" : "PROTECCIÓN ACTIVA", 
                        style: TextStyle(color: infoGarantia['vencida'] ? Colors.red : Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                    )
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
        Text(label, style: TextStyle(color: brandRed, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(content, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color color = Colors.white70}) {
    return Row(
      children: [
        Text("$label ", style: const TextStyle(color: Colors.white38, fontSize: 10)),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
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
          color: activo ? brandRed.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: activo ? brandRed.withValues(alpha: 0.4) : Colors.white10)
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