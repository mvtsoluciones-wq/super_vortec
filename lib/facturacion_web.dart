import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FacturacionWebModule extends StatefulWidget {
  const FacturacionWebModule({super.key});

  @override
  State<FacturacionWebModule> createState() => _FacturacionWebModuleState();
}

class _FacturacionWebModuleState extends State<FacturacionWebModule> {
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // --- DATOS DEL EMISOR (TALLER) ---
  final TextEditingController _confNombreTaller = TextEditingController(text: "SUPER VORTEC 5.3");
  final TextEditingController _confRifTaller = TextEditingController(text: "J-50123456-7");
  final TextEditingController _confDirTaller = TextEditingController(text: "AV. PRINCIPAL CARACAS, VENEZUELA");

  // --- DATOS DEL RECEPTOR (CLIENTE) ---
  final TextEditingController _ctrlNombre = TextEditingController();
  final TextEditingController _ctrlRif = TextEditingController();
  final TextEditingController _ctrlDireccion = TextEditingController();
  final TextEditingController _ctrlTelefono = TextEditingController();
  final TextEditingController _ctrlNroFactura = TextEditingController(text: "FAC-0001");
  final TextEditingController _ctrlNroControl = TextEditingController(text: "CON-0001");

  // --- CONTROLADORES DE ITEMS ---
  final TextEditingController _itemNombreCtrl = TextEditingController();
  final TextEditingController _itemDescCtrl = TextEditingController();
  final TextEditingController _itemCantCtrl = TextEditingController(text: "1");
  final TextEditingController _itemPrecioCtrl = TextEditingController();

  // --- BASE DE DATOS SIMULADA ---
  final List<Map<String, String>> _clientesRegistrados = [
    {"nombre": "Juan Pérez", "id": "V-12.345.678", "tel": "0414-1234567", "dir": "Av. Principal Caracas"},
    {"nombre": "Talleres ABC", "id": "J-30987654-2", "tel": "0212-5554433", "dir": "Zona Industrial Valencia"},
  ];

  final List<Map<String, dynamic>> _inventarioRegistrado = [
    {"nombre": "Aceite 15W40", "precio": 12.50, "desc": "Cuarto de aceite mineral"},
    {"nombre": "Filtro Gasolina", "precio": 8.00, "desc": "Filtro universal inyección"},
    {"nombre": "Mano de Obra", "precio": 40.00, "desc": "Servicio técnico especializado"},
  ];

  final List<Map<String, dynamic>> _itemsFactura = [];
  List<Map<String, String>> _clientesFiltrados = []; // AHORA SE USA EN LA UI
  List<Map<String, dynamic>> _productosFiltrados = [];

  double get _subtotal => _itemsFactura.fold(0, (sum, item) => sum + item['total']);
  double get _iva => _subtotal * 0.16;
  double get _total => _subtotal + _iva;

  // --- LÓGICA DE BÚSQUEDA ---
  void _buscarCliente(String query) {
    setState(() {
      if (query.isEmpty) {
        _clientesFiltrados = [];
      } else {
        _clientesFiltrados = _clientesRegistrados
            .where((c) => c['nombre']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _buscarProducto(String query) {
    setState(() {
      if (query.isEmpty) {
        _productosFiltrados = [];
      } else {
        _productosFiltrados = _inventarioRegistrado
            .where((p) => p['nombre'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _agregarItem() {
    if (_itemNombreCtrl.text.isEmpty || _itemPrecioCtrl.text.isEmpty) return;
    double precio = double.tryParse(_itemPrecioCtrl.text) ?? 0;
    int cant = int.tryParse(_itemCantCtrl.text) ?? 1;
    
    setState(() {
      _itemsFactura.add({
        "item": _itemNombreCtrl.text,
        "desc": _itemDescCtrl.text,
        "cant": cant,
        "precio": precio,
        "total": precio * cant
      });
      _itemNombreCtrl.clear();
      _itemDescCtrl.clear();
      _itemCantCtrl.text = "1";
      _itemPrecioCtrl.clear();
      _productosFiltrados = [];
    });
  }

  // --- GENERACIÓN DE PDF ---
  Future<void> _generarFacturaPDF() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(_confNombreTaller.text, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text("RIF: ${_confRifTaller.text}"),
                pw.Text(_confDirTaller.text, style: const pw.TextStyle(fontSize: 8)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text("FACTURA: ${_ctrlNroFactura.text}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(brandRed.toARGB32()))),
                pw.Text("CONTROL: ${_ctrlNroControl.text}"),
                pw.Text("FECHA: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}"),
              ]),
            ]),
            pw.SizedBox(height: 30),
            pw.Text("DATOS DEL CLIENTE:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.Text("NOMBRE: ${_ctrlNombre.text}"),
            pw.Text("RIF/CI: ${_ctrlRif.text} | TEL: ${_ctrlTelefono.text}"),
            pw.Text("DIR: ${_ctrlDireccion.text}"),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['CANT.', 'DESCRIPCIÓN', 'PRECIO UNIT.', 'TOTAL'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromInt(brandRed.toARGB32())),
              data: _itemsFactura.map((i) => [
                i['cant'].toString(),
                "${i['item']} - ${i['desc']}",
                "\$${i['precio'].toStringAsFixed(2)}",
                "\$${i['total'].toStringAsFixed(2)}"
              ]).toList(),
            ),
            pw.SizedBox(height: 30),
            pw.Align(alignment: pw.Alignment.centerRight, child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text("SUBTOTAL: \$${_subtotal.toStringAsFixed(2)}"),
                pw.Text("IVA (16%): \$${_iva.toStringAsFixed(2)}"),
                pw.Divider(color: PdfColors.grey),
                pw.Text("TOTAL A PAGAR: \$${_total.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ]
            )),
          ],
        );
      },
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 2,
          child: Column(children: [
            _buildCard("SELECCIÓN DE CLIENTE", [
              _buildBuscadorCliente(), // CAMPO QUE USA _clientesFiltrados
              const SizedBox(height: 15),
              _inputField("Nombre Completo", _ctrlNombre, Icons.person),
              const SizedBox(height: 15),
              Row(children: [
                Expanded(child: _inputField("RIF/CI", _ctrlRif, Icons.badge)),
                const SizedBox(width: 10),
                Expanded(child: _inputField("Teléfono", _ctrlTelefono, Icons.phone)),
              ]),
            ]),
            const SizedBox(height: 20),
            _buildCard("IMPORTAR DESDE INVENTARIO", [
              _buildBuscadorProducto(),
              const SizedBox(height: 15),
              Row(children: [
                Expanded(flex: 3, child: _itemInput("Item / Producto", _itemNombreCtrl)),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: _itemInput("Precio \$", _itemPrecioCtrl)),
                const SizedBox(width: 10),
                Expanded(flex: 1, child: _itemInput("Cant.", _itemCantCtrl)),
              ]),
              const SizedBox(height: 10),
              _itemInput("Notas adicionales", _itemDescCtrl),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _agregarItem,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, minimumSize: const Size(double.infinity, 45)),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("AGREGAR A LA FACTURA", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              _buildTablaItems(),
            ]),
          ]),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 1,
          child: Column(children: [
            _buildCard("TOTALES Y EMISIÓN", [
              _displayResumen("SUBTOTAL", "\$${_subtotal.toStringAsFixed(2)}"),
              _displayResumen("IVA (16%)", "\$${_iva.toStringAsFixed(2)}"),
              const Divider(color: Colors.white10, height: 30),
              _displayResumen("TOTAL", "\$${_total.toStringAsFixed(2)}", isTotal: true),
              const SizedBox(height: 30),
              _inputField("Nro. Factura", _ctrlNroFactura, Icons.numbers),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _generarFacturaPDF,
                style: ElevatedButton.styleFrom(backgroundColor: brandRed, minimumSize: const Size(double.infinity, 60)),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text("GENERAR E IMPRIMIR PDF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  // --- WIDGETS DE SOPORTE ---
  Widget _buildBuscadorCliente() {
    return Column(
      children: [
        TextField(
          onChanged: _buscarCliente,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: "Buscar cliente en base de datos...",
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            filled: true, fillColor: inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        // ESTE BLOQUE ELIMINA EL ERROR DE "UNUSED FIELD"
        if (_clientesFiltrados.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: _clientesFiltrados.map((c) => ListTile(
                title: Text(c['nombre']!, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  setState(() {
                    _ctrlNombre.text = c['nombre']!;
                    _ctrlRif.text = c['id']!;
                    _ctrlTelefono.text = c['tel']!;
                    _ctrlDireccion.text = c['dir']!;
                    _clientesFiltrados = [];
                  });
                },
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildBuscadorProducto() {
    return Column(children: [
      TextField(
        onChanged: _buscarProducto,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: "Buscar producto en inventario...",
          prefixIcon: const Icon(Icons.inventory_2, color: Colors.white),
          filled: true, fillColor: inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      if (_productosFiltrados.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(8)),
          child: Column(children: _productosFiltrados.map((p) => ListTile(
            title: Text(p['nombre'], style: const TextStyle(color: Colors.white)),
            subtitle: Text("\$${p['precio']}", style: TextStyle(color: brandRed)),
            onTap: () => setState(() {
              _itemNombreCtrl.text = p['nombre'];
              _itemPrecioCtrl.text = p['precio'].toString();
              _itemDescCtrl.text = p['desc'];
              _productosFiltrados = [];
            }),
          )).toList()),
        )
    ]);
  }

  Widget _buildTablaItems() {
    return SizedBox(
      width: double.infinity,
      child: DataTable(
        headingRowHeight: 40,
        horizontalMargin: 10,
        columns: const [
          DataColumn(label: Text("DESCRIPCIÓN", style: TextStyle(color: Colors.white38, fontSize: 11))),
          DataColumn(label: Text("CANT", style: TextStyle(color: Colors.white38, fontSize: 11))),
          DataColumn(label: Text("TOTAL", style: TextStyle(color: Colors.white38, fontSize: 11))),
          DataColumn(label: Text("", style: TextStyle(color: Colors.white38, fontSize: 11))),
        ],
        rows: _itemsFactura.map((i) => DataRow(cells: [
          DataCell(Text(i['item'], style: const TextStyle(color: Colors.white, fontSize: 12))),
          DataCell(Text(i['cant'].toString(), style: const TextStyle(color: Colors.white, fontSize: 12))),
          DataCell(Text("\$${i['total'].toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 12))),
          DataCell(IconButton(icon: const Icon(Icons.close, color: Colors.white24, size: 16), onPressed: () => setState(() => _itemsFactura.remove(i)))),
        ])).toList(),
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
        const SizedBox(height: 20),
        ...children
      ]),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        prefixIcon: Icon(icon, color: Colors.white, size: 18),
        filled: true, fillColor: inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _itemInput(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        filled: true, fillColor: inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _displayResumen(String label, String value, {bool isTotal = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: isTotal ? Colors.white : Colors.white38, fontSize: isTotal ? 14 : 12)),
      Text(value, style: TextStyle(color: isTotal ? brandRed : Colors.white, fontSize: isTotal ? 22 : 16, fontWeight: FontWeight.bold)),
    ]);
  }
}