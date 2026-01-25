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
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color bgDark = const Color(0xFF0A0A0A);

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
    } catch (e) {
      return "00-001"; 
    }
  }

  // --- GENERACIÓN DE PDF AJUSTADA (CUADRO RECORTADO Y SIN FIRMAS) ---
  Future<void> _generarOT(Map<String, dynamic> data, String funciones) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final String numeroOT = await _obtenerSiguienteNumeroOT();
      final String fechaActual = DateTime.now().toString().split(' ')[0];
      final String placaActual = data['placa_vehiculo'] ?? '';

      DocumentSnapshot vehiculoDoc = await FirebaseFirestore.instance
          .collection('vehiculos')
          .doc(placaActual)
          .get();

      Map<String, dynamic>? vData = vehiculoDoc.exists 
          ? vehiculoDoc.data() as Map<String, dynamic> 
          : null;

      QuerySnapshot mecanicoSnap = await FirebaseFirestore.instance
          .collection('mecanicos')
          .where('nombre', isEqualTo: data['mecanico_asignado'])
          .limit(1)
          .get();
      
      Map<String, dynamic>? datosMecanico = mecanicoSnap.docs.isNotEmpty 
          ? mecanicoSnap.docs.first.data() as Map<String, dynamic> 
          : null;

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.copyWith(
            marginBottom: 1.5 * PdfPageFormat.cm,
            marginTop: 1.5 * PdfPageFormat.cm,
            marginLeft: 1.5 * PdfPageFormat.cm,
            marginRight: 1.5 * PdfPageFormat.cm,
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
                        pw.Text(ConfigFactura.nombreEmpresa.toUpperCase(), 
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
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
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(children: [
                        pw.Text("TÉCNICO RESPONSABLE: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text((data['mecanico_asignado'] ?? "SIN ASIGNAR").toString().toUpperCase()),
                      ]),
                      if (datosMecanico != null) ...[
                        pw.SizedBox(height: 4),
                        pw.Text("ESPECIALIDAD: ${datosMecanico['especialidad'] ?? 'GENERAL'} | TELÉFONO: ${datosMecanico['telefono'] ?? 'N/A'}", 
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                      ]
                    ]
                  ),
                ),
                
                pw.SizedBox(height: 20),
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.5)),
                  child: pw.Column(
                    children: [
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(5),
                        color: PdfColors.grey300,
                        child: pw.Text("DATOS DEL VEHÍCULO", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Column(children: [
                          pw.Row(children: [
                            pw.Expanded(child: pw.Text("MARCA: ${(vData?['marca'] ?? data['marca_vehiculo'] ?? 'N/A')}")),
                            pw.Expanded(child: pw.Text("MODELO: ${(vData?['modelo'] ?? data['modelo_vehiculo'] ?? 'N/A')}")),
                          ]),
                          pw.SizedBox(height: 5),
                          pw.Row(children: [
                            pw.Expanded(child: pw.Text("COLOR: ${(vData?['color'] ?? data['color_vehiculo'] ?? 'N/A')}")),
                            pw.Expanded(child: pw.Text("AÑO: ${(vData?['anio'] ?? data['ano_vehiculo'] ?? 'N/A')}")),
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
                // --- CAMBIO: Cuadro recortado (altura fija menor) ---
                pw.Container(
                  width: double.infinity,
                  height: 150, // Se redujo de 300 o Expanded a 150 para recortarlo
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.5)),
                  child: pw.Text(funciones, style: const pw.TextStyle(fontSize: 10)),
                ),

                // --- CAMBIO: Se eliminó la sección de firmas inferior ---
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
        'marca_vehiculo': vData?['marca'] ?? data['marca_vehiculo'],
        'color_vehiculo': vData?['color'] ?? data['color_vehiculo'],
        'ano_vehiculo': vData?['anio'] ?? data['ano_vehiculo'],
        'tecnico': data['mecanico_asignado'],
        'instrucciones': funciones,
      });

      if (!mounted) return;
      Navigator.pop(context); 
      await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: "OT_$numeroOT.pdf");

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // --- El resto de los métodos se mantienen exactamente igual ---
  void _mostrarDialogoOT(Map<String, dynamic> data) {
    final TextEditingController funcionesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.white10)),
        title: const Text("REDACTAR ORDEN DE TRABAJO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: funcionesController,
          maxLines: 6,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: "Escriba las tareas específicas para el técnico...",
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR", style: TextStyle(color: Colors.white38))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(ctx);
              _generarOT(data, funcionesController.text);
            },
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text("GENERAR OT"),
          ),
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
          const Text("EQUIPO DE TRABAJO", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 15),
          _buildModernTecnicoSelector(),
          const SizedBox(height: 30),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),
          Expanded(
            child: _tecnicoSeleccionado == null
                ? _buildEmptyState("Selecciona un técnico para monitorear sus tareas")
                : _buildListaTrabajosAsignados(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: brandRed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("CENTRO DE SEGUIMIENTO", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            Text(_tecnicoSeleccionado == null ? "Monitoreo global del taller" : "Visualizando carga de: $_tecnicoSeleccionado", 
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildModernTecnicoSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('mecanicos').orderBy('nombre').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator(color: Colors.white);
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
                  width: 125,
                  decoration: BoxDecoration(
                    color: isSelected ? brandRed : cardBlack,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? Colors.white : Colors.white10, width: 2),
                    boxShadow: isSelected ? [BoxShadow(color: brandRed.withValues(alpha: 0.4), blurRadius: 20)] : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: isSelected ? Colors.white : Colors.white12,
                        child: Text(nombre[0], style: TextStyle(color: isSelected ? brandRed : Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      const SizedBox(height: 10),
                      Text(nombre.split(' ')[0], style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), overflow: TextOverflow.ellipsis),
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
        var trabajos = snapshot.data!.docs;
        if (trabajos.isEmpty) return _buildEmptyState("Sin reparaciones activas");
        return ListView.builder(
          itemCount: trabajos.length,
          itemBuilder: (context, index) {
            var data = trabajos[index].data() as Map<String, dynamic>;
            return _buildTrabajoCard(trabajos[index].id, data);
          },
        );
      },
    );
  }

  Widget _buildTrabajoCard(String docId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 4, height: 50,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 10)]),
          ),
          const SizedBox(width: 25),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['modelo_vehiculo'] ?? "S/D", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 5),
                Text("PLACA: ${data['placa_vehiculo'] ?? ''}", style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("SISTEMA", style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                Text(data['sistema_reparar'] ?? "GENERAL", style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
          _buildActionButton(Icons.assignment_rounded, "OT", () => _mostrarDialogoOT(data)),
          const SizedBox(width: 20),
          _buildActionButton(Icons.camera_enhance_rounded, "EVIDENCIAS", () {}),
          const SizedBox(width: 20),
          _buildActionButton(Icons.note_add_rounded, "NOTAS", () {}),
          const SizedBox(width: 15),
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, [VoidCallback? onTap]) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 22),
            onPressed: onTap ?? () {},
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState(String mensaje) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.supervised_user_circle_sharp, color: Colors.white.withValues(alpha: 0.05), size: 100),
          const SizedBox(height: 20),
          Text(mensaje, style: const TextStyle(color: Colors.white24, fontSize: 14)),
        ],
      ),
    );
  }
}