import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart'; // Necesario para cargar el logo
import 'package:intl/intl.dart'; // Para formatear la fecha

// --- IMPORTACIONES DE CONFIGURACIÓN ---
import 'config_factura_web.dart'; 

class PresupuestoAppModule extends StatefulWidget {
  const PresupuestoAppModule({super.key});

  @override
  State<PresupuestoAppModule> createState() => _PresupuestoAppModuleState();
}

class _PresupuestoAppModuleState extends State<PresupuestoAppModule> {
  String _filtroNombre = "";
  String? _clienteSeleccionadoId; 
  String? _clienteSeleccionadoNombre;

  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // --- FUNCIÓN MEJORADA PARA GENERAR PDF ---
  Future<void> _generarPDF(Map<String, dynamic> data, String docId) async {
    final pdf = pw.Document();
    final List items = data['presupuesto_items'] ?? [];
    
    // Cargar imagen del logo desde assets
    final ByteData bytes = await rootBundle.load(ConfigFactura.logoPath);
    final Uint8List byteList = bytes.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(byteList);

    // Formatear número de presupuesto (00-0001) 
    // Usamos los últimos 4 caracteres del docId para simular secuencia o puedes pasar un contador
    String nroPresupuesto = "00-${docId.substring(0, 4).toUpperCase()}";
    String fechaActual = DateFormat('dd/MM/yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- ENCABEZADO: LOGO Y DATOS EMPRESA ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Image(logoImage, width: 120),
                      pw.SizedBox(height: 10),
                      pw.Text(ConfigFactura.nombreEmpresa, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text("RIF: ${ConfigFactura.rifEmpresa}", style: const pw.TextStyle(fontSize: 9)),
                      pw.Text(ConfigFactura.direccionEmpresa, style: const pw.TextStyle(fontSize: 8)),
                      pw.Text("Tel: ${ConfigFactura.telefonoEmpresa}", style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("PRESUPUESTO", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                      pw.Text("NRO: $nroPresupuesto", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text("FECHA: $fechaActual", style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(thickness: 2, color: PdfColors.red900),
              pw.SizedBox(height: 15),

              // --- DATOS DEL CLIENTE Y VEHÍCULO ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("CLIENTE:", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.Text(_clienteSeleccionadoNombre?.toUpperCase() ?? "N/A", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("VEHÍCULO:", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.Text("${data['modelo_vehiculo']} - PLACA: ${data['placa_vehiculo']}", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 25),
              pw.Text("SISTEMA A INTERVENIR: ${data['sistema_reparar']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 10),

              // --- TABLA DE ITEMS ---
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey900),
                cellStyle: const pw.TextStyle(fontSize: 9),
                context: context,
                data: <List<String>>[
                  <String>['Item', 'Descripción', 'Cant', 'Precio Unit.', 'Subtotal'],
                  ...items.map((i) => [
                    i['item'].toString(),
                    i['descripcion'].toString(),
                    i['cantidad'].toString(),
                    "\$${(i['precio_unitario'] ?? 0).toStringAsFixed(2)}",
                    "\$${(i['subtotal'] ?? 0).toStringAsFixed(2)}"
                  ])
                ],
              ),

              // --- TOTALES Y GARANTÍA ---
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("TIEMPO DE GARANTÍA:", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.Text(data['garantia'] ?? "N/A", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    child: pw.Text(
                      "TOTAL A PAGAR: \$${(data['total_reparacion'] ?? 0).toStringAsFixed(2)}", 
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)
                    ),
                  ),
                ],
              ),

              pw.Spacer(),
              pw.Divider(color: PdfColors.grey400),
              pw.Center(
                child: pw.Text("Gracias por confiar en JMendez Performance - Soporte Técnico Especializado", 
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // --- RESTO DEL CÓDIGO (DIÁLOGOS Y BUILDERS) ---

  // Se actualizó la llamada a _generarPDF en el IconButton
  Widget _buildHistorialCard(String docId, Map<String, dynamic> data) {
    bool aprobado = data['aprobado'] ?? false;
    String modeloText = data['modelo_vehiculo'] ?? "VEHÍCULO";
    String mecanicoAsignado = data['mecanico_asignado'] ?? "PENDIENTE";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardBlack, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: Colors.white.withValues(alpha: 0.05))
      ),
      child: ExpansionTile(
        iconColor: Colors.white,
        collapsedIconColor: Colors.white54,
        title: Row(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(modeloText.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(aprobado ? "MECÁNICO: $mecanicoAsignado" : "PLACA: ${data['placa_vehiculo']}", 
                style: TextStyle(color: aprobado ? Colors.greenAccent : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            ]),
            const Spacer(),
            
            if (!aprobado)
              ElevatedButton.icon(
                onPressed: () => _abrirDialogoAprobacion(docId, data),
                icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                label: const Text("APROBAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], padding: const EdgeInsets.symmetric(horizontal: 15)),
              ),
            
            const SizedBox(width: 15),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 22), 
              onPressed: () => _generarPDF(data, docId) // Se agregó el docId aquí
            ),
            const SizedBox(width: 10),
            Text("\$${(data['total_reparacion'] ?? 0).toStringAsFixed(2)}", style: TextStyle(color: brandRed, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        // ... (resto del ExpansionTile se mantiene igual)
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black.withValues(alpha: 0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("GARANTÍA: ${data['garantia']}", style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                  Row(children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20), onPressed: () => _abrirEditorPresupuesto(docId, data)),
                    IconButton(icon: const Icon(Icons.check_circle, color: Colors.green, size: 20), 
                      onPressed: () => FirebaseFirestore.instance.collection('diagnosticos').doc(docId).update({'finalizado': true}),
                      tooltip: "Finalizar Trabajo",
                    ),
                  ])
                ]),
                Text("DETALLES: ${data['descripcion_falla']}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ... (Las funciones _abrirEditorPresupuesto, build, etc., se mantienen igual que en tu archivo original)

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_clienteSeleccionadoId == null ? "PRESUPUESTOS PENDIENTES" : "CLIENTE: ${_clienteSeleccionadoNombre?.toUpperCase()}", 
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const Spacer(),
            if (_clienteSeleccionadoId != null)
              OutlinedButton.icon(
                onPressed: () => setState(() { _clienteSeleccionadoId = null; }),
                icon: const Icon(Icons.arrow_back, size: 16, color: Colors.black),
                label: const Text("CAMBIAR CLIENTE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.black, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
          ],
        ),
        const SizedBox(height: 25),
        _clienteSeleccionadoId == null ? _buildBuscadorClientes() : _buildListaPresupuestos(),
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
              decoration: const InputDecoration(hintText: "BUSCAR CLIENTE...", prefixIcon: Icon(Icons.person_search, color: Colors.white54), border: InputBorder.none, contentPadding: EdgeInsets.all(20)),
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
                      onTap: () => setState(() { _clienteSeleccionadoId = c.id; _clienteSeleccionadoNombre = c['nombre']; }),
                      leading: CircleAvatar(backgroundColor: brandRed, child: const Icon(Icons.person, color: Colors.white)),
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

  Widget _buildListaPresupuestos() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('diagnosticos')
            .where('cliente_id', isEqualTo: _clienteSeleccionadoId)
            .where('finalizado', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("Sin presupuestos pendientes", style: TextStyle(color: Colors.white24)));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return _buildHistorialCard(docs[index].id, data);
            },
          );
        },
      ),
    );
  }

  // --- WIDGETS DE APOYO ---
  void _abrirDialogoAprobacion(String docId, Map<String, dynamic> data) {
    String? mecanicoSeleccionado;
    showDialog(
      context: context,
      builder: (diagCtx) => StatefulBuilder(
        builder: (diagCtx, setDialogState) => AlertDialog(
          backgroundColor: cardBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.white10)),
          title: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text("APROBAR Y ASIGNAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Selecciona el técnico que llevará a cabo la reparación:", style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('mecanicos').orderBy('nombre').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator(color: Colors.white);
                  var mecanicos = snapshot.data!.docs;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: mecanicoSeleccionado,
                        isExpanded: true,
                        dropdownColor: cardBlack,
                        hint: const Text("Seleccionar mecánico", style: TextStyle(color: Colors.white24, fontSize: 14)),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        items: mecanicos.map((m) => DropdownMenuItem(value: m['nombre'].toString(), child: Text(m['nombre'].toString().toUpperCase()))).toList(),
                        onChanged: (val) => setDialogState(() => mecanicoSeleccionado = val),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(diagCtx), child: const Text("CANCELAR", style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: mecanicoSeleccionado == null ? null : () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(diagCtx);
                try {
                  await FirebaseFirestore.instance.collection('diagnosticos').doc(docId).update({
                    'aprobado': true,
                    'mecanico_asignado': mecanicoSeleccionado,
                    'estado_taller': 'EN REPARACIÓN',
                    'fecha_aprobacion': FieldValue.serverTimestamp(),
                  });
                  if (!mounted) return;
                  navigator.pop();
                  messenger.showSnackBar(const SnackBar(content: Text("✅ TRABAJO APROBADO Y ASIGNADO"), backgroundColor: Colors.green));
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text("❌ ERROR: $e")));
                }
              },
              child: const Text("APROBAR AHORA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  void _abrirEditorPresupuesto(String docId, Map<String, dynamic> data) {
    final TextEditingController editSistema = TextEditingController(text: data['sistema_reparar']);
    final TextEditingController editDesc = TextEditingController(text: data['descripcion_falla']);
    final TextEditingController editGarantia = TextEditingController(text: data['garantia']);
    List<Map<String, dynamic>> editItems = (data['presupuesto_items'] as List).map((item) => {'item': TextEditingController(text: item['item']), 'descripcion': TextEditingController(text: item['descripcion']), 'cantidad': TextEditingController(text: item['cantidad'].toString()), 'precio_unitario': TextEditingController(text: item['precio_unitario'].toString())}).toList();
    showDialog(
      context: context,
      builder: (diagCtx) => StatefulBuilder(
        builder: (diagCtx, setDialogState) => AlertDialog(
          backgroundColor: cardBlack,
          title: Text("EDITAR PRESUPUESTO: ${data['modelo_vehiculo']}", style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 850,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEditField("SISTEMA", editSistema),
                  const SizedBox(height: 15),
                  _buildEditField("DESCRIPCIÓN", editDesc, maxLines: 3),
                  const SizedBox(height: 15),
                  _buildEditField("GARANTÍA", editGarantia),
                  const Divider(color: Colors.white10, height: 40),
                  ...editItems.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var row = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: _buildTableInput(row['item'], "Item")),
                          const SizedBox(width: 5),
                          Expanded(flex: 1, child: _buildTableInput(row['cantidad'], "Cant.", isNum: true)),
                          const SizedBox(width: 5),
                          Expanded(flex: 1, child: _buildTableInput(row['precio_unitario'], "\$", isNum: true)),
                          IconButton(icon: const Icon(Icons.remove_circle, color: Colors.redAccent), onPressed: () => setDialogState(() => editItems.removeAt(idx)))
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(onPressed: () => setDialogState(() => editItems.add({'item': TextEditingController(), 'descripcion': TextEditingController(), 'cantidad': TextEditingController(text: "1"), 'precio_unitario': TextEditingController()})), icon: const Icon(Icons.add_circle, color: Colors.green), label: const Text("AÑADIR ÍTEM"))
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(diagCtx), child: const Text("CANCELAR")),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(diagCtx);
                double nuevoTotal = 0;
                List<Map<String, dynamic>> itemsParaSubir = editItems.map((e) {
                  double c = double.tryParse(e['cantidad'].text) ?? 0;
                  double p = double.tryParse(e['precio_unitario'].text) ?? 0;
                  nuevoTotal += (c * p);
                  return {'item': e['item'].text.toUpperCase(), 'descripcion': e['descripcion'].text.toUpperCase(), 'cantidad': c, 'precio_unitario': p, 'subtotal': c * p};
                }).toList();
                try {
                  await FirebaseFirestore.instance.collection('diagnosticos').doc(docId).update({'sistema_reparar': editSistema.text.toUpperCase(), 'descripcion_falla': editDesc.text.toUpperCase(), 'garantia': editGarantia.text.toUpperCase(), 'presupuesto_items': itemsParaSubir, 'total_reparacion': nuevoTotal});
                  if (!mounted) return;
                  navigator.pop();
                  messenger.showSnackBar(const SnackBar(content: Text("✅ ACTUALIZADO")));
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(content: Text("❌ ERROR: $e")));
                }
              },
              child: const Text("GUARDAR"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(height: 5), TextField(controller: controller, maxLines: maxLines, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)))]);
  }

  Widget _buildTableInput(TextEditingController c, String h, {bool isNum = false}) {
    return TextField(controller: c, keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: InputDecoration(hintText: h, isDense: true, filled: true, fillColor: inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none)));
  }
}