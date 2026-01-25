import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'config_factura_web.dart';

class SeguimientoWebModule extends StatefulWidget {
  const SeguimientoWebModule({super.key});

  @override
  State<SeguimientoWebModule> createState() => _SeguimientoWebModuleState();
}

class _SeguimientoWebModuleState extends State<SeguimientoWebModule> {
  String? _tecnicoSeleccionado;
  // Mapa para almacenar temporalmente los links de video por cada diagnóstico activo
  final Map<String, String> _evidenciasYoutube = {}; 

  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color bgDark = const Color(0xFF0A0A0A);

  // --- 1. FINALIZAR TRABAJO Y MOVER A HISTORIAL_WEB CON VIDEO ---
  Future<void> _finalizarTrabajo(String docId, Map<String, dynamic> data) async {
    bool? confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBlack,
        title: const Text("¿FINALIZAR REPARACIÓN?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("El vehículo se moverá al historial con sus evidencias y saldrá de la lista activa.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("SÍ, FINALIZAR"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        // Obtenemos el link de youtube si fue ingresado
        String urlVideo = _evidenciasYoutube[docId] ?? "";

        await FirebaseFirestore.instance.collection('historial_web').add({
          ...data,
          'fecha_finalizacion': FieldValue.serverTimestamp(),
          'estado_entrega': 'FINALIZADO',
          'url_evidencia_video': urlVideo, // Campo nuevo para el cliente
        });

        await FirebaseFirestore.instance.collection('diagnosticos').doc(docId).update({
          'finalizado': true,
        });

        if (!mounted) return;
        // Limpiar el mapa temporal
        setState(() => _evidenciasYoutube.remove(docId));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ TRABAJO COMPLETADO Y ARCHIVADO CON VIDEO"), backgroundColor: Colors.green),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // --- 2. ACTUALIZAR FASE ---
  Future<void> _cambiarEstatus(String docId, String nuevoEstatus) async {
    await FirebaseFirestore.instance.collection('diagnosticos').doc(docId).update({
      'fase_reparacion': nuevoEstatus,
    });
  }

  // --- DIÁLOGO PARA URL DE YOUTUBE ---
  void _mostrarDialogoVideo(String docId) {
    final TextEditingController videoController = TextEditingController(text: _evidenciasYoutube[docId] ?? "");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBlack,
        title: const Text("EVIDENCIA EN VIDEO (YOUTUBE)", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: videoController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Pegue el URL del video aquí...",
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () {
              setState(() => _evidenciasYoutube[docId] = videoController.text);
              Navigator.pop(ctx);
            }, 
            child: const Text("VINCULAR VIDEO")
          ),
        ],
      ),
    );
  }

  Future<String> _obtenerSiguienteNumeroOT() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('ordenes_trabajo')
          .orderBy('numero_secuencial', descending: true)
          .limit(1)
          .get();
      int siguiente = 1;
      if (snap.docs.isNotEmpty) {
        siguiente = (snap.docs.first['numero_secuencial'] as int) + 1;
      }
      return "00-${siguiente.toString().padLeft(3, '0')}";
    } catch (e) { return "00-001"; }
  }

  // --- 3. GENERACIÓN DE PDF ---
  Future<void> _generarOT(Map<String, dynamic> data, String funciones) async {
    final String numeroOT = await _obtenerSiguienteNumeroOT();
    final String fechaActual = DateTime.now().toString().split(' ')[0];
    final String placaActual = data['placa_vehiculo'] ?? '';

    DocumentSnapshot vehiculoDoc = await FirebaseFirestore.instance.collection('vehiculos').doc(placaActual).get();
    Map<String, dynamic>? vData = vehiculoDoc.exists ? vehiculoDoc.data() as Map<String, dynamic> : null;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginBottom: 1.5 * PdfPageFormat.cm, marginTop: 1.5 * PdfPageFormat.cm,
          marginLeft: 1.5 * PdfPageFormat.cm, marginRight: 1.5 * PdfPageFormat.cm,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(ConfigFactura.nombreEmpresa.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                      pw.Text("RIF: ${ConfigFactura.rifEmpresa}", style: const pw.TextStyle(fontSize: 9)),
                      pw.Text("TLF: ${ConfigFactura.telefonoEmpresa}", style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("ORDEN DE TRABAJO", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Nº: $numeroOT", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                      pw.Text("FECHA: $fechaActual", style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, color: PdfColors.black),
              pw.SizedBox(height: 15),
              pw.Text("TÉCNICO: ${(data['mecanico_asignado'] ?? "S/A").toString().toUpperCase()}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.5)),
                child: pw.Column(
                  children: [
                    pw.Container(width: double.infinity, padding: const pw.EdgeInsets.all(5), color: PdfColors.grey300, child: pw.Text("DATOS DEL VEHÍCULO", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Column(children: [
                        pw.Row(children: [
                          pw.Expanded(child: pw.Text("MARCA: ${(vData?['marca'] ?? 'N/A')}")),
                          pw.Expanded(child: pw.Text("MODELO: ${(vData?['modelo'] ?? data['modelo_vehiculo'] ?? 'N/A')}")),
                        ]),
                        pw.SizedBox(height: 5),
                        pw.Row(children: [
                          pw.Expanded(child: pw.Text("COLOR: ${(vData?['color'] ?? 'N/A')}")),
                          pw.Expanded(child: pw.Text("AÑO: ${(vData?['anio'] ?? 'N/A')}")),
                        ]),
                        pw.SizedBox(height: 8),
                        pw.Text("PLACA: $placaActual", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      ]),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 25),
              pw.Text("FUNCIONES Y TAREAS ASIGNADAS:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Container(
                width: double.infinity, height: 150, padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.5)),
                child: pw.Text(funciones, style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          );
        },
      ),
    );

    await FirebaseFirestore.instance.collection('ordenes_trabajo').add({
      'numero_ot': numeroOT,
      'numero_secuencial': int.parse(numeroOT.split('-')[1]),
      'fecha': FieldValue.serverTimestamp(),
      'placa_vehiculo': placaActual,
      'modelo_vehiculo': vData?['modelo'] ?? data['modelo_vehiculo'],
      'tecnico': data['mecanico_asignado'],
      'instrucciones': funciones,
    });

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: "OT_$numeroOT.pdf");
  }

  // --- 4. INTERFAZ DE TARJETA ACTUALIZADA ---
  Widget _buildTrabajoCard(String docId, Map<String, dynamic> data) {
    String faseActual = data['fase_reparacion'] ?? "EN ESPERA";
    bool tieneVideo = _evidenciasYoutube.containsKey(docId) && _evidenciasYoutube[docId]!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          PopupMenuButton<String>(
            onSelected: (val) => _cambiarEstatus(docId, val),
            color: cardBlack,
            itemBuilder: (ctx) => [
              _buildMenuItem("EN ESPERA", Icons.timer),
              _buildMenuItem("EN REPARACIÓN", Icons.build),
              _buildMenuItem("EN PRUEBAS", Icons.speed),
              _buildMenuItem("LISTO", Icons.check_circle),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: brandRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: brandRed.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  const Text("FASE / ESTATUS", style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(faseActual, style: TextStyle(color: brandRed, fontSize: 10, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 25),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['modelo_vehiculo'] ?? "S/D", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Text("PLACA: ${data['placa_vehiculo'] ?? ''}", style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          
          _buildActionButton(Icons.assignment_rounded, "OT", () => _mostrarDialogoOT(data)),
          const SizedBox(width: 15),
          
          // BOTÓN DE EVIDENCIA EN VIDEO (YOUTUBE)
          Column(
            children: [
              IconButton(
                icon: Icon(
                  Icons.play_circle_fill, 
                  color: tieneVideo ? Colors.red : Colors.white24, 
                  size: 26
                ), 
                onPressed: () => _mostrarDialogoVideo(docId)
              ),
              Text(
                tieneVideo ? "VIDEO OK" : "VINCULAR", 
                style: TextStyle(color: tieneVideo ? Colors.red : Colors.white24, fontSize: 8)
              ),
            ],
          ),
          const SizedBox(width: 20),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.withValues(alpha: 0.15),
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () => _finalizarTrabajo(docId, data), 
            icon: const Icon(Icons.verified, size: 18), 
            label: const Text("FINALIZAR", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: brandRed, size: 18),
          const SizedBox(width: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  void _mostrarDialogoOT(Map<String, dynamic> data) {
    final TextEditingController funcionesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBlack,
        title: const Text("REDACTAR ORDEN DE TRABAJO", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: funcionesController,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Tareas específicas...",
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          ElevatedButton(onPressed: () { Navigator.pop(ctx); _generarOT(data, funcionesController.text); }, child: const Text("GENERAR")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgDark,
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 35),
          _buildModernTecnicoSelector(),
          const SizedBox(height: 30),
          const Divider(color: Colors.white10),
          Expanded(
            child: _tecnicoSeleccionado == null
                ? _buildEmptyState("Selecciona un técnico")
                : _buildListaTrabajosAsignados(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.monitor_heart, color: brandRed, size: 35),
        const SizedBox(width: 20),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("MONITOREO DE REPARACIONES", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            Text("Control de estatus y finalización de procesos", style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildModernTecnicoSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('mecanicos').orderBy('nombre').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        var tecnicos = snapshot.data!.docs;
        return SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tecnicos.length,
            itemBuilder: (context, index) {
              var t = tecnicos[index].data() as Map<String, dynamic>;
              String nombre = t['nombre'].toString();
              bool isSelected = _tecnicoSeleccionado == nombre;
              return GestureDetector(
                onTap: () => setState(() => _tecnicoSeleccionado = nombre),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 20),
                  padding: const EdgeInsets.all(15),
                  width: 120,
                  decoration: BoxDecoration(
                    color: isSelected ? brandRed : cardBlack,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? Colors.white : Colors.white10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(radius: 20, backgroundColor: isSelected ? Colors.white : Colors.white12, child: Text(nombre[0])),
                      const SizedBox(height: 8),
                      Text(nombre.split(' ')[0], style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildListaTrabajosAsignados() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('diagnosticos')
          .where('mecanico_asignado', isEqualTo: _tecnicoSeleccionado)
          .where('finalizado', isEqualTo: false) 
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var trabajos = snapshot.data!.docs;
        if (trabajos.isEmpty) return _buildEmptyState("Sin trabajos activos");
        return ListView.builder(
          itemCount: trabajos.length,
          itemBuilder: (context, index) => _buildTrabajoCard(trabajos[index].id, trabajos[index].data() as Map<String, dynamic>),
        );
      },
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        IconButton(icon: Icon(icon, color: Colors.white, size: 22), onPressed: onTap),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 8)),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(child: Text(msg, style: const TextStyle(color: Colors.white24)));
  }
}