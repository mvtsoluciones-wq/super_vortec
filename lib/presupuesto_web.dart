import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// --- MODELOS DE DATOS ---

class ClientePrueba {
  final String nombre;
  final String id;
  final String telefono;

  ClientePrueba({required this.nombre, required this.id, required this.telefono});
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
  // --- VARIABLES DE ESTADO ---
  final List<ItemPresupuesto> _itemsAgregados = [];
  int _cantidadActual = 1;
  ClientePrueba? _clienteSeleccionado;

  // --- CONFIGURACIÓN VISUAL ---
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // --- DATOS DE PRUEBA (IMPORTACIÓN) ---
  final List<ClientePrueba> _listaClientes = [
    ClientePrueba(nombre: "Juan Pérez", id: "V-12.345.678", telefono: "0414-1234567"),
    ClientePrueba(nombre: "Talleres Mecánicos C.A.", id: "J-30987654-2", telefono: "0212-5554433"),
    ClientePrueba(nombre: "María Rodríguez", id: "V-9.876.543", telefono: "0424-9998877"),
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

  // --- CÁLCULOS ---
  double get _subtotal => _itemsAgregados.fold(0, (sum, item) => sum + item.totalLinea);
  double get _iva => _subtotal * 0.16;
  double get _total => _subtotal + _iva;

  // --- LÓGICA DE PDF ---
  Future<void> _generatePdf() async {
    if (_clienteSeleccionado == null || _itemsAgregados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione cliente e ingrese ítems")),
      );
      return;
    }

    final pdf = pw.Document();
    
    // Carga de Imagen con Manejo de Errores
    pw.MemoryImage? logo;
    try {
      final ByteData bytes = await rootBundle.load('assets/logo_vortec.png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      debugPrint("Logo no encontrado en assets");
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ENCABEZADO
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("SUPER VORTEC 5.3", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(brandRed.value))),
                      pw.Text("Taller Mecánico & Repuestos Especializados", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text("Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}"),
                    ],
                  ),
                  if (logo != null) pw.Image(logo, width: 80),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 10),

              // DATOS CLIENTE
              pw.Text("DATOS DEL CLIENTE:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text("Nombre: ${_clienteSeleccionado!.nombre}"),
              pw.Text("ID/RIF: ${_clienteSeleccionado!.id}"),
              pw.Text("Teléfono: ${_clienteSeleccionado!.telefono}"),
              pw.SizedBox(height: 20),

              // TABLA
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromInt(brandRed.value)),
                cellHeight: 25,
                data: <List<String>>[
                  ['Concepto', 'Cant.', 'P. Unitario', 'Total'],
                  ..._itemsAgregados.map((i) => [
                    i.nombre,
                    i.cantidad.toString(),
                    "\$${i.precioUnitario.toStringAsFixed(2)}",
                    "\$${i.totalLinea.toStringAsFixed(2)}"
                  ])
                ],
              ),
              
              pw.Spacer(),

              // TOTALES
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 180,
                  child: pw.Column(
                    children: [
                      _pdfRow("Subtotal:", "\$${_subtotal.toStringAsFixed(2)}"),
                      _pdfRow("IVA (16%):", "\$${_iva.toStringAsFixed(2)}"),
                      pw.Divider(),
                      _pdfRow("TOTAL NETO:", "\$${_total.toStringAsFixed(2)}", isBold: true),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _pdfRow(String l, String v, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(l, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(v, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  // --- INTERFAZ DE USUARIO ---

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopHeader(),
          const SizedBox(height: 30),
          _buildClientImporter(),
          const SizedBox(height: 30),
          _buildSelectionArea(),
          const SizedBox(height: 30),
          _buildItemsTable(),
          const SizedBox(height: 30),
          _buildBottomSummary(),
        ],
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
            const Text("SUPER VORTEC - PANEL ADMINISTRATIVO", style: TextStyle(color: Colors.white24, fontSize: 10)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _generatePdf,
          icon: const Icon(Icons.picture_as_pdf, size: 18),
          label: const Text("DESCARGAR PDF"),
          style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
        ),
      ],
    );
  }

  Widget _buildClientImporter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Row(
        children: [
          const Icon(Icons.person_search, color: Colors.white24),
          const SizedBox(width: 15),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ClientePrueba>(
                dropdownColor: cardBlack,
                hint: const Text("Importar datos del cliente...", style: TextStyle(color: Colors.white24)),
                value: _clienteSeleccionado,
                items: _listaClientes.map((c) => DropdownMenuItem(value: c, child: Text(c.nombre, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (val) => setState(() => _clienteSeleccionado = val),
              ),
            ),
          ),
          if (_clienteSeleccionado != null) ...[
            const VerticalDivider(color: Colors.white10),
            _infoChip("ID", _clienteSeleccionado!.id),
            const SizedBox(width: 20),
            _infoChip("TEL", _clienteSeleccionado!.telefono),
          ]
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
    return Column(
      children: [
        const Text("CANT.", style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 45,
          decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.remove, color: Colors.white, size: 14), onPressed: () => setState(() => _cantidadActual > 1 ? _cantidadActual-- : null)),
              Text("$_cantidadActual", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add, color: Colors.white, size: 14), onPressed: () => setState(() => _cantidadActual++)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _customSelector(String label, Map<String, double> fuente, String tipo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: cardBlack,
              hint: const Text("Seleccionar...", style: TextStyle(color: Colors.white24, fontSize: 12)),
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
      decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.02)),
        columns: const [
          DataColumn(label: Text("CONCEPTO", style: TextStyle(color: Colors.white38, fontSize: 10))),
          DataColumn(label: Text("CANT.", style: TextStyle(color: Colors.white38, fontSize: 10))),
          DataColumn(label: Text("UNITARIO", style: TextStyle(color: Colors.white38, fontSize: 10))),
          DataColumn(label: Text("TOTAL", style: TextStyle(color: Colors.white38, fontSize: 10))),
          DataColumn(label: Text("", style: TextStyle(color: Colors.white38))),
        ],
        rows: _itemsAgregados.asMap().entries.map((e) => DataRow(cells: [
          DataCell(Text(e.value.nombre, style: const TextStyle(color: Colors.white, fontSize: 13))),
          DataCell(Text("${e.value.cantidad}", style: const TextStyle(color: Colors.white70))),
          DataCell(Text("\$${e.value.precioUnitario.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white70))),
          DataCell(Text("\$${e.value.totalLinea.toStringAsFixed(2)}", style: TextStyle(color: brandRed, fontWeight: FontWeight.bold))),
          DataCell(IconButton(icon: const Icon(Icons.close, color: Colors.white10, size: 16), onPressed: () => setState(() => _itemsAgregados.removeAt(e.key)))),
        ])).toList(),
      ),
    );
  }

  Widget _buildBottomSummary() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: brandRed.withValues(alpha: 0.2))),
        child: Column(
          children: [
            _summaryRow("SUBTOTAL", "\$${_subtotal.toStringAsFixed(2)}"),
            const SizedBox(height: 10),
            _summaryRow("IVA (16%)", "\$${_iva.toStringAsFixed(2)}"),
            const Divider(color: Colors.white10, height: 30),
            _summaryRow("TOTAL ESTIMADO", "\$${_total.toStringAsFixed(2)}", isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String l, String v, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: TextStyle(color: isBold ? Colors.white : Colors.white38, fontSize: isBold ? 14 : 11, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(v, style: TextStyle(color: isBold ? brandRed : Colors.white, fontWeight: FontWeight.bold, fontSize: isBold ? 18 : 14)),
      ],
    );
  }

  Widget _infoChip(String l, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(l, style: const TextStyle(color: Colors.white24, fontSize: 9)),
    Text(v, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
  ]);
}