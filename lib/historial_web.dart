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
  String? _tecnicoSeleccionado;

  // EFECTO DE BORDE NEGRO PARA TÍTULOS (Stroke effect)
  final List<Shadow> _bordeNegro = [
    const Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
    const Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
    const Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
    const Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
  ];

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

  String _calcularTiempoDesdeEntrega(DateTime fechaFin) {
    final diferencia = DateTime.now().difference(fechaFin).inDays;
    if (diferencia == 0) return "ENTREGADO HOY";
    return "HACE $diferencia DÍAS";
  }

  Map<String, dynamic> _calcularGarantia(DateTime fechaFin, dynamic garantiaData) {
    int diasTotales = 30; 
    String totalTexto = "30 DÍAS";

    try {
      if (garantiaData != null) {
        totalTexto = garantiaData.toString().toUpperCase();
        if (garantiaData is int) {
          diasTotales = garantiaData;
        } else if (garantiaData is String) {
          String raw = garantiaData.toUpperCase();
          if (raw.contains("MESES")) {
            int meses = int.tryParse(raw.split(' ')[0]) ?? 1;
            diasTotales = meses * 30;
          } else {
            diasTotales = int.tryParse(raw.split(' ')[0]) ?? 30;
          }
        }
      }
    } catch (e) {
      diasTotales = 30;
    }

    final fechaVencimiento = fechaFin.add(Duration(days: diasTotales));
    final restante = fechaVencimiento.difference(DateTime.now()).inDays;
    return {
      "restante": restante < 0 ? 0 : restante,
      "vencida": restante < 0,
      "total_db": totalTexto
    };
  }

  void _mostrarPresupuestoDetalle(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBlack,
        title: Text("DETALLE DE PRESUPUESTO APROBADO", 
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: _bordeNegro)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("TOTAL APROBADO: \$${data['total_reparacion'] ?? '0.00'}", 
              style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.w900)),
            const Divider(color: Colors.white10, height: 20),
            const Text("OBSERVACIONES COMERCIALES:", style: TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 5),
            Text(data['notas_presupuesto'] ?? "Sin notas adicionales.", 
              style: const TextStyle(color: Colors.white38, fontSize: 13)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("HISTORIAL DE SERVICIOS Y GARANTÍAS", 
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2, shadows: _bordeNegro)),
        const Text("Control de post-venta, tiempos de protección y presupuestos", 
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
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true, fillColor: inputFill,
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
          label: Text(_fechaFiltro == null ? "FILTRAR FECHA" : DateFormat('dd/MM/yyyy').format(_fechaFiltro!), style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildListaHistorial() {
    Query query = FirebaseFirestore.instance.collection('historial_web').orderBy('fecha_finalizacion', descending: true);
    
    if (_tecnicoSeleccionado != null) {
      query = query.where('mecanico_asignado', isEqualTo: _tecnicoSeleccionado);
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
    DateTime fechaFin = (data['fecha_finalizacion'] as Timestamp).toDate();
    var infoGarantia = _calcularGarantia(fechaFin, data['garantia']);
    String placa = data['placa_vehiculo'] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10)
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
                    Text(data['modelo_vehiculo'] ?? "S/D", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, shadows: _bordeNegro)),
                    Text("PLACA: $placa", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 20),
                    
                    // --- MODIFICACIÓN: VIDEO RECEPCIÓN DESDE COLECCIÓN VEHICULOS ---
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('vehiculos').doc(placa).get(),
                      builder: (context, snapshot) {
                        String urlRepo = "";
                        if (snapshot.hasData && snapshot.data!.exists) {
                          urlRepo = snapshot.data!.get('video_recepcion') ?? "";
                        }
                        return _buildVideoBtn("VIDEO RECEPCIÓN", urlRepo, Icons.videocam_outlined);
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildVideoBtn("VIDEO REPARACIÓN", data['url_evidencia_video'] ?? data['evidencia_youtube'] ?? "", Icons.play_circle_fill),
                  ],
                ),
              ),
              
              // COLUMNA 2: DETALLES TÉCNICOS Y GARANTÍA ALINEADA
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTextBlock("DESCRIPCIÓN DE FALLA:", data['descripcion_falla'] ?? "No especificada en recepción"),
                          ),
                          const SizedBox(width: 15),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: infoGarantia['vencida'] ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: infoGarantia['vencida'] ? Colors.red.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3))
                            ),
                            child: Column(
                              children: [
                                Text("${infoGarantia['restante']}", 
                                  style: TextStyle(color: infoGarantia['vencida'] ? Colors.red : Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold, shadows: _bordeNegro)),
                                Text("DÍAS RESTANTES", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 7, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildTextBlock("SISTEMA A REPARAR:", data['sistema_reparar'] ?? "Sin sistema asignado"),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoRow("GARANTÍA TOTAL:", infoGarantia['total_db']),
                          _buildInfoRow("TIEMPO DESDE ENTREGA:", _calcularTiempoDesdeEntrega(fechaFin)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // COLUMNA 3: PRESUPUESTO
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("MONTO APROBADO", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, shadows: _bordeNegro)),
                    Text("\$${data['total_reparacion'] ?? '0.00'}", 
                      style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        side: const BorderSide(color: Colors.white12)
                      ),
                      onPressed: () => _mostrarPresupuestoDetalle(data),
                      icon: const Icon(Icons.receipt_long, size: 14, color: Colors.white),
                      label: const Text("VER PRESUPUESTO", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
        Text(label, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, shadows: _bordeNegro)),
        const SizedBox(height: 4),
        Text(content, style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.4)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("$label ", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, shadows: _bordeNegro)),
        Text(value, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildVideoBtn(String label, String url, IconData icon) {
    bool activo = url.isNotEmpty;
    return InkWell(
      onTap: activo ? () => _abrirVideo(url) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 5),
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
            Text(label, style: TextStyle(color: activo ? Colors.white : Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, shadows: activo ? _bordeNegro : null)),
          ],
        ),
      ),
    );
  }
}