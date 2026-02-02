import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import 'config_factura_web.dart';
import 'ventas_web.dart'; 

class RecibosWebModule extends StatefulWidget {
  const RecibosWebModule({super.key});

  @override
  State<RecibosWebModule> createState() => _RecibosWebModuleState();
}

class _RecibosWebModuleState extends State<RecibosWebModule> {
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color bgDark = const Color(0xFF050505);
  final Color inputFill = const Color(0xFF1E1E1E);

  String _filtroBusqueda = "";

  // --- NAVEGACIÓN A VENTAS ---
  void _irAVentas(Map<String, dynamic> data, String docId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VentasWebModule(datosRecibo: data, idRecibo: docId),
      ),
    );
  }

  // --- FUNCIÓN: ELIMINAR RECIBO ---
  Future<void> _eliminarRecibo(String docId) async {
    bool confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBlack,
        title: const Text("¿Eliminar Recibo?", style: TextStyle(color: Colors.white)),
        content: const Text("Esta acción borrará el registro permanentemente de la base de datos.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      )
    ) ?? false;

    if (confirmar) {
      try {
        await FirebaseFirestore.instance.collection('recibos').doc(docId).delete();
        _notificar("🗑️ Recibo eliminado correctamente", Colors.orange);
      } catch (e) {
        _notificar("Error al eliminar: $e", Colors.red);
      }
    }
  }

  // --- GENERAR PDF ---
  Future<void> _generarPDFRecibo(Map<String, dynamic> data, String docId) async {
    final pdf = pw.Document();
    var configRef = FirebaseFirestore.instance.collection('configuracion').doc('factura');
    var configSnap = await configRef.get();
    var configData = configSnap.data() ?? {};
    
    pw.MemoryImage? logoImage;
    if (configData['logoBase64'] != null) {
      try { logoImage = pw.MemoryImage(base64Decode(configData['logoBase64'])); } catch (_) {}
    }

    String nroRecibo = data['numero_recibo'] ?? "";
    if (nroRecibo.isEmpty) {
      int correlativo = configData['ultimo_nro_recibo'] ?? 1;
      nroRecibo = "00-${correlativo.toString().padLeft(4, '0')}";
      await configRef.update({'ultimo_nro_recibo': correlativo + 1});
      await FirebaseFirestore.instance.collection('recibos').doc(docId).update({'numero_recibo': nroRecibo});
    }

    DateTime fechaBase = data['fecha_emision_recibo'] != null ? (data['fecha_emision_recibo'] as Timestamp).toDate() : DateTime.now();
    String fechaEmision = DateFormat('dd/MM/yyyy HH:mm').format(fechaBase);
    List items = data['presupuesto_items'] ?? [];
    double totalPagar = (data['total_reparacion'] ?? 0).toDouble();

    String nombreClientePDF = "Cliente";
    if (data['cliente_id'] != null) {
       var docC = await FirebaseFirestore.instance.collection('clientes').doc(data['cliente_id']).get();
       if (!docC.exists) {
          var q = await FirebaseFirestore.instance.collection('clientes').where('cedula', isEqualTo: data['cliente_id']).limit(1).get();
          if (q.docs.isNotEmpty) docC = q.docs.first;
       }
       if (docC.exists) nombreClientePDF = docC.data()?['nombre'] ?? "Cliente";
    }

    String nombreEmpresa = configData['nombreEmpresa'] ?? ConfigFactura.nombreEmpresa;
    String rifEmpresa = configData['rifEmpresa'] ?? ConfigFactura.rifEmpresa;
    String direccionEmpresa = configData['direccion'] ?? ConfigFactura.direccionEmpresa;
    String telefonoEmpresa = configData['telefono'] ?? ConfigFactura.telefonoEmpresa;

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      build: (pw.Context context) {
        return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              if (logoImage != null) pw.Image(logoImage, width: 100),
              pw.SizedBox(height: 5),
              pw.Text(nombreEmpresa, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(rifEmpresa, style: const pw.TextStyle(fontSize: 10)),
              pw.Text(direccionEmpresa, style: const pw.TextStyle(fontSize: 8)),
              pw.Text(telefonoEmpresa, style: const pw.TextStyle(fontSize: 8)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text("RECIBO DE PAGO", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
              pw.Text("NRO: $nroRecibo", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(fechaEmision, style: const pw.TextStyle(fontSize: 10)),
            ]),
          ]),
          pw.SizedBox(height: 20), pw.Divider(),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text("CLIENTE:", style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              pw.Text(nombreClientePDF.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text("ID: ${data['cliente_id']}", style: const pw.TextStyle(fontSize: 8)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text("VEHÍCULO:", style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              pw.Text("${data['modelo_vehiculo']} - ${data['placa_vehiculo']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ]),
          ]),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 10),
            data: <List<String>>[['Descripción', 'Cant.', 'Precio Unit.', 'Total'], ...items.map((i) => [i['item'].toString(), i['cantidad'].toString(), "\$${(i['precio_unitario'] ?? 0).toStringAsFixed(2)}", "\$${(i['subtotal'] ?? 0).toStringAsFixed(2)}"])],
          ),
          pw.SizedBox(height: 15),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Text("TOTAL PAGADO:   ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text("\$${totalPagar.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
          ]),
          pw.Spacer(),
          pw.Center(child: pw.Text("Gracias por su preferencia", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500))),
        ]);
      },
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Recibo_$nroRecibo');
  }

  // --- ENVIAR WHATSAPP ---
  Future<void> _enviarWhatsapp(Map<String, dynamic> data) async {
    try {
      String telefono = "";
      String nombreCliente = "Cliente";
      if (data['cliente_id'] != null) {
        var clienteDoc = await FirebaseFirestore.instance.collection('clientes').doc(data['cliente_id']).get();
        if (!clienteDoc.exists) {
           var query = await FirebaseFirestore.instance.collection('clientes').where('cedula', isEqualTo: data['cliente_id']).limit(1).get();
           if (query.docs.isNotEmpty) clienteDoc = query.docs.first;
        }
        if (clienteDoc.exists) {
          var cData = clienteDoc.data();
          telefono = cData?['telefono'] ?? "";
          nombreCliente = cData?['nombre'] ?? "Cliente";
        }
      }
      if (telefono.isEmpty) { _notificar("⚠️ Cliente sin teléfono registrado", Colors.orange); return; }
      
      telefono = telefono.replaceAll(RegExp(r'[^0-9]'), '');
      if (!telefono.startsWith('58') && telefono.length > 9) telefono = "58$telefono";

      String mensaje = "Hola $nombreCliente! 🚗\n\nAdjuntamos el recibo de su vehículo ${data['modelo_vehiculo']} (${data['placa_vehiculo']}).\n\nTotal Pagado: \$${data['total_reparacion']}\n\nGracias por elegir Super Vortec.";
      final Uri url = Uri.parse("https://wa.me/$telefono?text=${Uri.encodeComponent(mensaje)}");
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) _notificar("No se pudo abrir WhatsApp", Colors.red);
    } catch (e) { _notificar("Error: $e", Colors.red); }
  }

  // --- FACTURAR ---
  Future<void> _enviarAFacturacion(String docId, Map<String, dynamic> data) async {
    try {
      var existe = await FirebaseFirestore.instance.collection('facturas_pendientes').where('origen_recibo_id', isEqualTo: docId).get();
      if (existe.docs.isNotEmpty) { _notificar("⚠️ Ya está en facturación", Colors.orange); return; }
      
      Map<String, dynamic> datosFactura = Map.from(data);
      if (data['cliente_id'] != null) {
        var clienteDoc = await FirebaseFirestore.instance.collection('clientes').doc(data['cliente_id']).get();
        if (clienteDoc.exists) {
          datosFactura['datos_fiscales_cliente'] = clienteDoc.data();
        }
      }

      await FirebaseFirestore.instance.collection('facturas_pendientes').add({
        ...datosFactura, 'origen_recibo_id': docId, 'fecha_ingreso_facturacion': FieldValue.serverTimestamp(), 'estatus_fiscal': 'PENDIENTE',
      });
      await FirebaseFirestore.instance.collection('recibos').doc(docId).update({'estado_facturacion': 'ENVIADO'});
      _notificar("✅ Enviado a Facturación", Colors.blue);
    } catch (e) { _notificar("Error: $e", Colors.red); }
  }

  // --- ENVIAR A APP ---
  Future<void> _enviarAClienteApp(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('recibos').doc(docId).update({'recibo_disponible_app': true, 'fecha_envio_app': FieldValue.serverTimestamp()});
      _notificar("✅ Enviado a App Cliente", Colors.green);
    } catch (e) { _notificar("Error: $e", Colors.red); }
  }

  void _notificar(String msj, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msj), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    // CAMBIO CLAVE: Se usa Scaffold en lugar de Container para evitar el error "No Material widget found"
    return Scaffold(
      backgroundColor: bgDark,
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("CONTROL DE CAJA Y RECIBOS", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    Text("Historial de pagos y emisión de documentos", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                  ],
                ),
                Container(
                  width: 350,
                  height: 45,
                  decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
                  child: TextField(
                    onChanged: (val) => setState(() => _filtroBusqueda = val.toUpperCase()),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.white38),
                      hintText: "Buscar recibo, placa o cliente...",
                      hintStyle: TextStyle(color: Colors.white24),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(top: 8)
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 30),
            
            // Encabezados
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  _headerCell("CLIENTE / FECHA", flex: 3),
                  _headerCell("VEHÍCULO", flex: 2),
                  _headerCell("NRO RECIBO", flex: 2),
                  _headerCell("TOTAL", flex: 2, align: TextAlign.right),
                  _headerCell("ESTATUS", flex: 2, align: TextAlign.center),
                  _headerCell("ACCIONES", flex: 6, align: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Lista de Datos
            Expanded(child: _buildListaRecibos()),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text, {int flex = 1, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(text, textAlign: align, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildListaRecibos() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('recibos').orderBy('fecha_emision_recibo', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs.where((d) {
          var data = d.data() as Map<String, dynamic>;
          String searchKey = "${data['placa_vehiculo']} ${data['modelo_vehiculo']} ${data['cliente_id']} ${data['numero_recibo'] ?? ''}".toUpperCase();
          return searchKey.contains(_filtroBusqueda);
        }).toList();

        if (docs.isEmpty) return const Center(child: Text("No se encontraron registros", style: TextStyle(color: Colors.white24)));

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (c, i) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _buildReciboRow(docs[index].id, docs[index].data() as Map<String, dynamic>),
        );
      },
    );
  }

  Widget _buildReciboRow(String docId, Map<String, dynamic> data) {
    bool enviadoApp = data['recibo_disponible_app'] ?? false;
    String estadoFactura = data['estado_facturacion'] ?? "PENDIENTE";
    double total = (data['total_reparacion'] ?? 0).toDouble();
    DateTime fecha = data['fecha_emision_recibo'] != null ? (data['fecha_emision_recibo'] as Timestamp).toDate() : DateTime.now();
    String nroRecibo = data['numero_recibo'] ?? "";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05))
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NombreClienteWidget(clienteId: data['cliente_id']),
                Text(DateFormat('dd/MM HH:mm').format(fecha), style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['modelo_vehiculo'] ?? "S/D", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                Text(data['placa_vehiculo'] ?? "", style: TextStyle(color: brandRed, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              nroRecibo.isNotEmpty ? nroRecibo : "PENDIENTE", 
              style: TextStyle(color: nroRecibo.isNotEmpty ? Colors.white70 : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)
            ),
          ),
          Expanded(
            flex: 2,
            child: Text("\$${total.toStringAsFixed(2)}", textAlign: TextAlign.right, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if(enviadoApp) const Padding(padding: EdgeInsets.only(right: 5), child: Icon(Icons.phone_android, size: 14, color: Colors.blue)),
                if(estadoFactura == 'ENVIADO') const Icon(Icons.receipt, size: 14, color: Colors.orange),
                if(!enviadoApp && estadoFactura != 'ENVIADO') const Text("-", style: TextStyle(color: Colors.white24)),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionIcon(Icons.picture_as_pdf, Colors.redAccent, "PDF", () => _generarPDFRecibo(data, docId)),
                const SizedBox(width: 5),
                _actionIcon(Icons.wechat, Colors.green, "WhatsApp", () => _enviarWhatsapp(data)),
                const SizedBox(width: 5),
                _actionIcon(Icons.monetization_on, Colors.purpleAccent, "Venta", () => _irAVentas(data, docId)),
                const SizedBox(width: 5),
                _actionIcon(Icons.cloud_upload, Colors.blue, "Facturar", () => _enviarAFacturacion(docId, data)),
                const SizedBox(width: 5),
                _actionIcon(Icons.send_to_mobile, enviadoApp ? Colors.grey : Colors.orange, "App", () => _enviarAClienteApp(docId)),
                const SizedBox(width: 5),
                _actionIcon(Icons.delete_outline, Colors.grey, "Borrar Recibo", () => _eliminarRecibo(docId)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: color.withValues(alpha: 0.3))
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _NombreClienteWidget extends StatelessWidget {
  final String? clienteId;
  const _NombreClienteWidget({required this.clienteId});

  @override
  Widget build(BuildContext context) {
    if (clienteId == null) return const Text("S/N", style: TextStyle(color: Colors.white38));

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('clientes').doc(clienteId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1));
        
        if (snapshot.hasData && snapshot.data!.exists) {
          String nombre = snapshot.data!.get('nombre') ?? "Cliente";
          return Text(nombre.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
        } else {
          return Text(clienteId!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
        }
      },
    );
  }
}