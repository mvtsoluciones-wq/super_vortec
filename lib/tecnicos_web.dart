import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'config_factura_web.dart'; // Asegúrate de que la ruta sea correcta

class TecnicosWebModule extends StatefulWidget {
  const TecnicosWebModule({super.key});

  @override
  State<TecnicosWebModule> createState() => _TecnicosWebModuleState();
}

class _TecnicosWebModuleState extends State<TecnicosWebModule> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _especialidadController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // --- FUNCIÓN OPTIMIZADA: GENERACIÓN DE PDF INSTANTÁNEA Y CON MÁRGENES ---
  Future<void> _verPDFHistorial(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    
    // Preparación de datos previa para velocidad
    final DateTime fechaDoc = (data['fecha'] as Timestamp).toDate();
    final String fechaFormateada = DateFormat('dd/MM/yyyy').format(fechaDoc);
    final String numeroOT = data['numero_ot'] ?? "00-000";

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
              // ENCABEZADO FISCAL (Desde ConfigFactura)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(ConfigFactura.nombreEmpresa.toUpperCase(), 
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                      pw.Text("RIF: ${ConfigFactura.rifEmpresa}", style: const pw.TextStyle(fontSize: 8)),
                      pw.Text("TLF: ${ConfigFactura.telefonoEmpresa}", style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("ORDEN DE TRABAJO (COPIA)", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Nº: $numeroOT", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                      pw.Text("FECHA: $fechaFormateada", style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 0.5, color: PdfColors.grey),
              pw.SizedBox(height: 15),
              
              pw.Text("TÉCNICO RESPONSABLE: ${data['tecnico']?.toString().toUpperCase()}", 
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              
              pw.SizedBox(height: 15),
              
              // DATOS DEL VEHÍCULO
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("DATOS DEL VEHÍCULO", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.SizedBox(height: 5),
                    pw.Row(children: [
                      pw.Expanded(child: pw.Text("MODELO: ${data['modelo_vehiculo'] ?? 'N/A'}", style: const pw.TextStyle(fontSize: 10))),
                      pw.Expanded(child: pw.Text("PLACA: ${data['placa_vehiculo'] ?? 'N/A'}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    ]),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
              
              pw.Text("INSTRUCCIONES ASIGNADAS:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.SizedBox(height: 5),
              pw.Expanded(
                child: pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.5)),
                  child: pw.Text(data['instrucciones'] ?? "SIN INSTRUCCIONES", style: const pw.TextStyle(fontSize: 9)),
                ),
              ),

              pw.SizedBox(height: 20),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(children: [pw.SizedBox(width: 100, child: pw.Divider(thickness: 0.5)), pw.Text("Firma Mecánico", style: const pw.TextStyle(fontSize: 7))]),
                  pw.Column(children: [pw.SizedBox(width: 100, child: pw.Divider(thickness: 0.5)), pw.Text("Recibido Cliente", style: const pw.TextStyle(fontSize: 7))]),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: "OT_REIMPRESION_$numeroOT");
  }

  // --- PANEL LATERAL DE HISTORIAL ---
  void _mostrarHistorialTecnico(String nombreTecnico) {
    String filtroModelo = "";
    DateTime? fechaFiltro;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Historial",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: StatefulBuilder(
            builder: (dialogCtx, setModalState) => Container(
              width: 550,
              height: double.infinity,
              color: const Color(0xFF0D0D0D),
              padding: const EdgeInsets.all(30),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nombreTecnico, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            const Text("HISTORIAL POR MODELO", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
                          ],
                        ),
                        IconButton(onPressed: () => Navigator.pop(dialogCtx), icon: const Icon(Icons.close, color: Colors.white24))
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (val) => setModalState(() => filtroModelo = val.toUpperCase()),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: "BUSCAR MODELO (Ej: SILVERADO)...",
                              prefixIcon: const Icon(Icons.search, color: Colors.white24),
                              filled: true, fillColor: inputFill,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: Icon(Icons.calendar_month, color: fechaFiltro == null ? Colors.white24 : brandRed),
                          onPressed: () async {
                            DateTime? p = await showDatePicker(context: dialogCtx, initialDate: DateTime.now(), firstDate: DateTime(2025), lastDate: DateTime.now());
                            if (p != null) setModalState(() => fechaFiltro = p);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('ordenes_trabajo').where('tecnico', isEqualTo: nombreTecnico).snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          var ordenes = snapshot.data!.docs.where((doc) {
                            var d = doc.data() as Map<String, dynamic>;
                            bool matchesM = (d['modelo_vehiculo'] ?? "").toString().toUpperCase().contains(filtroModelo);
                            if (fechaFiltro != null) {
                              DateTime date = (d['fecha'] as Timestamp).toDate();
                              return matchesM && date.day == fechaFiltro!.day && date.month == fechaFiltro!.month && date.year == fechaFiltro!.year;
                            }
                            return matchesM;
                          }).toList();

                          if (ordenes.isEmpty) return const Center(child: Text("Sin registros para este técnico", style: TextStyle(color: Colors.white10)));

                          return ListView.builder(
                            itemCount: ordenes.length,
                            itemBuilder: (context, i) {
                              var d = ordenes[i].data() as Map<String, dynamic>;
                              return InkWell(
                                onTap: () => _verPDFHistorial(d),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                                  child: Row(
                                    children: [
                                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(d['numero_ot'] ?? "00-000", style: TextStyle(color: brandRed, fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text(d['fecha'] != null ? DateFormat('dd/MM/yyyy').format((d['fecha'] as Timestamp).toDate()) : "", style: const TextStyle(color: Colors.white24, fontSize: 10)),
                                      ]),
                                      const Spacer(),
                                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                        Text(d['modelo_vehiculo'] ?? "MODELO N/A", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                        Text(d['placa_vehiculo'] ?? "", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                      ]),
                                      const SizedBox(width: 15),
                                      const Icon(Icons.picture_as_pdf, color: Colors.white24, size: 18),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(anim1), child: child);
      },
    );
  }

  // --- CRUD TÉCNICOS ---
  Future<void> _registrarTecnico() async {
    if (_nombreController.text.isEmpty) return;
    await FirebaseFirestore.instance.collection('mecanicos').add({
      'nombre': _nombreController.text.trim().toUpperCase(),
      'especialidad': _especialidadController.text.trim().toUpperCase(),
      'telefono': _telefonoController.text.trim(),
      'fecha_registro': FieldValue.serverTimestamp(),
      'disponible': true,
    });
    _nombreController.clear(); _especialidadController.clear(); _telefonoController.clear();
  }

  void _eliminarTecnico(String id) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: cardBlack,
        title: const Text("¿ELIMINAR TÉCNICO?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Esta acción eliminará al técnico permanentemente.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandRed),
            onPressed: () {
              FirebaseFirestore.instance.collection('mecanicos').doc(id).delete();
              Navigator.pop(c);
            },
            child: const Text("ELIMINAR"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("GESTIÓN DE PERSONAL TÉCNICO", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(child: _buildInput("Nombre Completo", _nombreController, Icons.person)),
              const SizedBox(width: 15),
              Expanded(child: _buildInput("Especialidad", _especialidadController, Icons.build)),
              const SizedBox(width: 15),
              Expanded(child: _buildInput("Teléfono", _telefonoController, Icons.phone)),
              const SizedBox(width: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: brandRed, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 22)),
                onPressed: _registrarTecnico, icon: const Icon(Icons.add_circle), label: const Text("REGISTRAR"),
              )
            ],
          ),
          const SizedBox(height: 40),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('mecanicos').orderBy('nombre').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 2.8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var docId = snapshot.data!.docs[index].id;
                    var t = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return InkWell(
                      onTap: () => _mostrarHistorialTecnico(t['nombre']),
                      borderRadius: BorderRadius.circular(10),
                      child: _buildTecnicoCard(docId, t),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTecnicoCard(String id, Map<String, dynamic> t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: brandRed.withValues(alpha: 0.1), child: Icon(Icons.engineering, color: brandRed, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t['nombre'] ?? "S/N", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
              Text(t['especialidad'] ?? "GENERAL", style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
            onPressed: () => _eliminarTecnico(id),
          )
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        prefixIcon: Icon(icon, color: brandRed, size: 18),
        filled: true, fillColor: inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}