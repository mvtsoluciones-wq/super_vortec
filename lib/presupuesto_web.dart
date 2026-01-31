import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:intl/intl.dart'; // Asegúrate de tener esta importación para las fechas

import 'config_factura_web.dart'; 

// --- MODELOS DE DATOS ---
class ClientePrueba {
  final String nombre;
  final String id;
  final String telefono;
  final String vehiculo; 
  final String placa;

  ClientePrueba({
    required this.nombre, 
    required this.id, 
    required this.telefono,
    this.vehiculo = "RENAULT KOLEOS", 
    this.placa = "123-TYU",
  });
}

class ItemPresupuesto {
  final String nombre;
  final int cantidad;
  final double precioUnitario;
  final String tipo;

  double get totalLinea => cantidad * precioUnitario;

  ItemPresupuesto({
    required this.nombre, 
    required this.cantidad, 
    required this.precioUnitario, 
    required this.tipo
  });
}

class PresupuestoWebModule extends StatefulWidget {
  const PresupuestoWebModule({super.key});

  @override
  State<PresupuestoWebModule> createState() => _PresupuestoWebModuleState();
}

class _PresupuestoWebModuleState extends State<PresupuestoWebModule> {
  final List<ItemPresupuesto> _itemsAgregados = [];
  int _cantidadActual = 1;
  ClientePrueba? _clienteSeleccionado;
  
  // Nota: _numeroControl ya no es fijo, se genera dinámicamente en el PDF
  bool _cargandoConfig = true; 

  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();
    _cargarConfiguracionBaseDeDatos(); 
  }

  // --- FUNCIÓN SINCRONIZADA CON TU BASE DE DATOS (factura) ---
  Future<void> _cargarConfiguracionBaseDeDatos() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('factura')
          .get();

      if (doc.exists) {
        var data = doc.data()!;
        setState(() {
          ConfigFactura.nombreEmpresa = data['nombreEmpresa'] ?? ConfigFactura.nombreEmpresa;
          ConfigFactura.rifEmpresa = data['rifEmpresa'] ?? ConfigFactura.rifEmpresa;
          ConfigFactura.direccionEmpresa = data['direccion'] ?? ConfigFactura.direccionEmpresa;
          ConfigFactura.telefonoEmpresa = data['telefono'] ?? ConfigFactura.telefonoEmpresa;
          ConfigFactura.correoEmpresa = data['email'] ?? ConfigFactura.correoEmpresa;
          ConfigFactura.ivaPorcentaje = data['iva'] ?? ConfigFactura.ivaPorcentaje;
          ConfigFactura.logoBase64 = data['logoBase64']; 
          _cargandoConfig = false;
        });
      } else {
        setState(() => _cargandoConfig = false);
      }
    } catch (e) {
      debugPrint("Error al cargar configuración desde DB: $e");
      setState(() => _cargandoConfig = false);
    }
  }

  void _guardarPresupuesto() {
    if (_clienteSeleccionado == null) {
      _notificar("Error: Debe seleccionar un cliente", Colors.red);
      return;
    }
    if (_itemsAgregados.isEmpty) {
      _notificar("Error: Agregue al menos un repuesto o servicio", Colors.red);
      return;
    }
    // Nota: El número real se genera al crear el PDF/Guardar en DB
    _notificar("Éxito: Presupuesto listo para generar", Colors.green);
  }

  void _notificar(String msj, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msj), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  final List<ClientePrueba> _listaClientes = [
    ClientePrueba(nombre: "NATHALY VILLEGAS", id: "V-12.345.678", telefono: "0414-1234567"),
    ClientePrueba(nombre: "Talleres Mecánicos C.A.", id: "J-30987654-2", telefono: "0212-5554433"),
  ];

  final Map<String, double> _inventarioRepuestos = {
    'Kit de Distribución': 150.0,
    'Pastillas de Freno': 80.0,
    'Filtro de Aceite': 25.0,
    'Bomba de Agua': 110.0,
  };

  final Map<String, double> _catalogoServicios = {
    'Cambio de Aceite': 20.0,
    'Ajuste de Motor': 400.0,
    'Escaneo Computarizado': 45.0,
    'Limpieza de Inyectores': 60.0,
  };

  double get _subtotal => _itemsAgregados.fold(0.0, (total, item) => total + item.totalLinea);
  double get _iva => _subtotal * (double.tryParse(ConfigFactura.ivaPorcentaje) ?? 16.0) / 100;
  double get _total => _subtotal + _iva;

  // --- FUNCIÓN MODIFICADA: LOGO DB, NUMERACIÓN SECUENCIAL Y CÉDULA ---
  Future<void> _generatePdf() async {
    if (_clienteSeleccionado == null || _itemsAgregados.isEmpty) return;

    final pdf = pw.Document();
    
    // 1. Obtener configuración actualizada desde Firestore (Logo y Correlativo)
    var configDoc = await FirebaseFirestore.instance.collection('configuracion').doc('factura').get();
    pw.MemoryImage? logoImage;
    int nroCorrelativo = 1;

    if (configDoc.exists) {
      // Decodificar Logo
      String? base64Logo = configDoc.data()?['logoBase64'];
      if (base64Logo != null && base64Logo.isNotEmpty) {
        try {
          logoImage = pw.MemoryImage(base64Decode(base64Logo));
        } catch (e) {
          debugPrint("Error decodificando logo: $e");
        }
      }
      // Obtener último número
      nroCorrelativo = configDoc.data()?['ultimo_nro'] ?? 1;
    }

    // Formatear número y fecha
    String nroPresupuestoFormateado = "00-${nroCorrelativo.toString().padLeft(4, '0')}";
    String fechaActual = DateFormat('dd/MM/yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImage != null) pw.Container(width: 180, child: pw.Image(logoImage)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(ConfigFactura.nombreEmpresa, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text("RIF: ${ConfigFactura.rifEmpresa}", style: const pw.TextStyle(fontSize: 9)),
                      pw.Text(ConfigFactura.direccionEmpresa, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                      pw.Text("Tel: ${ConfigFactura.telefonoEmpresa}", style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 25),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("PRESUPUESTO", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // Usamos el número formateado dinámico
                      pw.Text("NRO: $nroPresupuestoFormateado", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("FECHA: $fechaActual", style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _pdfDataRow("CLIENTE:", _clienteSeleccionado!.nombre),
                    // Agregamos la Cédula/ID debajo del nombre
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 75), // Alineado con el valor del nombre
                      child: pw.Text("ID: ${_clienteSeleccionado!.id}", style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.SizedBox(height: 4),
                    _pdfDataRow("VEHÍCULO:", "${_clienteSeleccionado!.vehiculo} - PLACA: ${_clienteSeleccionado!.placa}"),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                data: <List<String>>[
                  ['Descripción', 'Cant.', 'Precio Unit.', 'Subtotal'],
                  ..._itemsAgregados.map((i) => [i.nombre, i.cantidad.toString(), "\$${i.precioUnitario.toStringAsFixed(2)}", "\$${i.totalLinea.toStringAsFixed(2)}"])
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("TIEMPO DE GARANTÍA: ________________", style: const pw.TextStyle(fontSize: 8)),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    color: PdfColors.grey100,
                    child: pw.Text("TOTAL A PAGAR: \$${_total.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Center(child: pw.Text("Gracias por confiar en JMendez Performance", style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic))),
            ],
          );
        },
      ),
    );

    // 2. Actualizar el correlativo en Firebase para el próximo presupuesto
    await FirebaseFirestore.instance.collection('configuracion').doc('factura').update({
      'ultimo_nro': nroCorrelativo + 1
    });

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Presupuesto_$nroPresupuestoFormateado');
  }

  pw.Widget _pdfDataRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(width: 75, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
        pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoConfig) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD50000)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            _buildTopHeader(),
            const SizedBox(height: 30),
            _buildClientImporter(),
            const SizedBox(height: 30),
            _buildSelectionArea(),
            const SizedBox(height: 30),
            _buildItemsTable(),
            const SizedBox(height: 30),
            _buildBottomSummaryAndSave(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("SISTEMA DE PRESUPUESTOS", style: TextStyle(color: brandRed, fontWeight: FontWeight.w900, fontSize: 18)),
            const Text("SINCRONIZADO CON LA NUBE", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _generatePdf,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text("DESCARGAR PDF"),
          style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
        ),
      ],
    );
  }

  Widget _buildClientImporter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          const Icon(Icons.person_search, color: Colors.white24),
          const SizedBox(width: 15),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ClientePrueba>(
                dropdownColor: cardBlack,
                hint: const Text("Seleccionar cliente...", style: TextStyle(color: Colors.white24)),
                value: _clienteSeleccionado,
                items: _listaClientes.map((c) => DropdownMenuItem(value: c, child: Text(c.nombre, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (val) => setState(() => _clienteSeleccionado = val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionArea() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _customSelector("Repuesto", _inventarioRepuestos, "Repuesto")),
        const SizedBox(width: 15),
        Expanded(child: _customSelector("Mano de Obra", _catalogoServicios, "Servicio")),
        const SizedBox(width: 15),
        _buildQtyCounter(),
      ],
    );
  }

  Widget _buildQtyCounter() {
    return Container(
      height: 45,
      decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.remove, color: Colors.white), onPressed: () => setState(() => _cantidadActual > 1 ? _cantidadActual-- : null)),
          Text("$_cantidadActual", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: () => setState(() => _cantidadActual++)),
        ],
      ),
    );
  }

  Widget _customSelector(String label, Map<String, double> fuente, String tipo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 9)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: cardBlack,
              items: fuente.keys.map((k) => DropdownMenuItem(value: k, child: Text(k, style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _itemsAgregados.add(ItemPresupuesto(nombre: val, cantidad: _cantidadActual, precioUnitario: fuente[val]!, tipo: tipo));
                    _cantidadActual = 1;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: DataTable(
        columns: const [
          DataColumn(label: Text("CONCEPTO", style: TextStyle(color: Colors.white38))),
          DataColumn(label: Text("CANT.", style: TextStyle(color: Colors.white38))),
          DataColumn(label: Text("TOTAL", style: TextStyle(color: Colors.white38))),
          DataColumn(label: Text("", style: TextStyle(color: Colors.white38))),
        ],
        rows: _itemsAgregados.asMap().entries.map((e) => DataRow(cells: [
          DataCell(Text(e.value.nombre, style: const TextStyle(color: Colors.white))),
          DataCell(Text("${e.value.cantidad}", style: const TextStyle(color: Colors.white70))),
          DataCell(Text("\$${e.value.totalLinea.toStringAsFixed(2)}", style: TextStyle(color: brandRed, fontWeight: FontWeight.bold))),
          DataCell(IconButton(icon: const Icon(Icons.close, color: Colors.white10), onPressed: () => setState(() => _itemsAgregados.removeAt(e.key)))),
        ])).toList(),
      ),
    );
  }

  Widget _buildBottomSummaryAndSave() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed: _guardarPresupuesto,
          icon: const Icon(Icons.save),
          label: const Text("GUARDAR PRESUPUESTO"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(20)),
        ),
        Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _summaryRow("SUBTOTAL", "\$${_subtotal.toStringAsFixed(2)}"),
              _summaryRow("IVA (${ConfigFactura.ivaPorcentaje}%)", "\$${_iva.toStringAsFixed(2)}"),
              const Divider(color: Colors.white10),
              _summaryRow("TOTAL", "\$${_total.toStringAsFixed(2)}", isBold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String l, String v, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: TextStyle(color: isBold ? Colors.white : Colors.white38)),
        Text(v, style: TextStyle(color: isBold ? brandRed : Colors.white, fontWeight: FontWeight.bold, fontSize: isBold ? 18 : 14)),
      ],
    );
  }
}