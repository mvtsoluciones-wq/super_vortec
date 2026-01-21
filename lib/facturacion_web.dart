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

  // --- BASES DE DATOS SIMULADAS ---
  final List<Map<String, String>> _dbClientes = [
    {"nombre": "PRODUCTOS RONAVA C.A.", "id": "J-00030157-3", "tel": "(0212)239.64.13", "dir": "Av. Don Diego Cisneros Edif Siemens, Los Ruices"},
    {"nombre": "JUAN PÉREZ", "id": "V-12.345.678", "tel": "0414-1112233", "dir": "Urb. El Marqués, Caracas"},
  ];

  final List<Map<String, dynamic>> _dbInventario = [
    {"nombre": "CÁMARA DOMO 1080P", "precio": 45.00, "stock": 25},
    {"nombre": "DVR 4 CANALES", "precio": 85.50, "stock": 10},
    {"nombre": "DISCO DURO 1TB", "precio": 60.00, "stock": 15},
    {"nombre": "MANTENIMIENTO CCTV", "precio": 240671.85, "stock": 999}, 
  ];

  // --- DATOS DEL EMISOR (MVT) ---
  final TextEditingController _confNombreEmpresa = TextEditingController(text: "MENDEZ Y VEGAS TELECOMUNICACIONES C.A.");
  final TextEditingController _confRifEmpresa = TextEditingController(text: "J-29799471-8");
  final TextEditingController _confDireccion = TextEditingController(text: "Urb. Simon Rodriguez, La Campiña, Caracas");
  final TextEditingController _confTelfEmpresa = TextEditingController(text: "(0212) 639.04.57 / 0412-202.55.50");

  // --- DATOS DEL CLIENTE ---
  final TextEditingController _ctrlNombreCliente = TextEditingController();
  final TextEditingController _ctrlRifCliente = TextEditingController();
  final TextEditingController _ctrlDirCliente = TextEditingController();
  final TextEditingController _ctrlTelfCliente = TextEditingController();

  // --- CONTROL Y FECHA ---
  final TextEditingController _ctrlNroFactura = TextEditingController();
  final TextEditingController _ctrlNroControl = TextEditingController(text: "00-");
  final TextEditingController _ctrlDia = TextEditingController(text: DateTime.now().day.toString().padLeft(2, '0'));
  final TextEditingController _ctrlMes = TextEditingController(text: DateTime.now().month.toString().padLeft(2, '0'));
  final TextEditingController _ctrlAnio = TextEditingController(text: DateTime.now().year.toString());
  final TextEditingController _ctrlNotas = TextEditingController(); // VACÍO AHORA

  // --- ITEMS ACUMULATIVOS ---
  final List<Map<String, dynamic>> _itemsFactura = [];
  final TextEditingController _itemConcepto = TextEditingController();
  final TextEditingController _itemPrecio = TextEditingController();
  final TextEditingController _itemCant = TextEditingController(text: "1");

  // --- SUGERENCIAS ---
  List<Map<String, String>> _sugerenciasClientes = [];
  List<Map<String, dynamic>> _sugerenciasProductos = [];

  double get _subtotal => _itemsFactura.fold(0, (sum, item) => sum + item['total']);
  double get _iva => _subtotal * 0.16;
  double get _total => _subtotal + _iva;

  void _buscarCliente(String query) {
    setState(() {
      _sugerenciasClientes = query.isEmpty 
          ? [] 
          : _dbClientes.where((c) => c['nombre']!.contains(query.toUpperCase())).toList();
    });
  }

  void _buscarProducto(String query) {
    setState(() {
      _sugerenciasProductos = query.isEmpty 
          ? [] 
          : _dbInventario.where((p) => p['nombre'].contains(query.toUpperCase())).toList();
    });
  }

  void _agregarItem() {
    if (_itemConcepto.text.isEmpty || _itemPrecio.text.isEmpty) return;
    double precio = double.tryParse(_itemPrecio.text.replaceAll(',', '.')) ?? 0;
    int cant = int.tryParse(_itemCant.text) ?? 1;

    setState(() {
      _itemsFactura.add({
        "cant": cant,
        "concepto": _itemConcepto.text.toUpperCase(),
        "precio": precio,
        "total": precio * cant
      });
      _itemConcepto.clear();
      _itemPrecio.clear();
      _itemCant.text = "1";
      _sugerenciasProductos = []; // Limpia sugerencias al agregar
    });
  }

  void _procesarFacturaFinal() {
    for (var item in _itemsFactura) {
      for (var prod in _dbInventario) {
        if (prod['nombre'] == item['concepto']) {
          prod['stock'] -= item['cant'];
        }
      }
    }
    _generarFacturaPDF();
  }

  Future<void> _generarFacturaPDF() async {
    final pdf = pw.Document();
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
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("SUPER VORTEC 5.3", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(brandRed.toARGB32()))),
                      pw.Text(_confNombreEmpresa.text, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text("R.I.F: ${_confRifEmpresa.text}", style: const pw.TextStyle(fontSize: 9)),
                      pw.Text(_confDireccion.text, style: const pw.TextStyle(fontSize: 8)),
                      pw.Text("Telf: ${_confTelfEmpresa.text}", style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.5, color: PdfColors.red)),
                        child: pw.Column(
                          children: [
                            pw.Text("N° de CONTROL", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                            pw.Text(_ctrlNroControl.text, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text("FACTURA N°: ${_ctrlNroFactura.text}", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 25),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("NOMBRE O RAZON SOCIAL: ${_ctrlNombreCliente.text.toUpperCase()}", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text("DOMICILIO FISCAL: ${_ctrlDirCliente.text.toUpperCase()}", style: const pw.TextStyle(fontSize: 9)),
                    pw.Row(children: [
                      pw.Text("R.I.F: ${_ctrlRifCliente.text.toUpperCase()}    ", style: const pw.TextStyle(fontSize: 9)),
                      pw.Text("TELÉFONO: ${_ctrlTelfCliente.text}", style: const pw.TextStyle(fontSize: 9)),
                    ]),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Table(
                    border: pw.TableBorder.all(width: 0.5),
                    children: [
                      pw.TableRow(children: [
                        pw.Container(width: 30, child: pw.Center(child: pw.Text("Día", style: const pw.TextStyle(fontSize: 8)))),
                        pw.Container(width: 30, child: pw.Center(child: pw.Text("Mes", style: const pw.TextStyle(fontSize: 8)))),
                        pw.Container(width: 40, child: pw.Center(child: pw.Text("Año", style: const pw.TextStyle(fontSize: 8)))),
                      ]),
                      pw.TableRow(children: [
                        pw.Center(child: pw.Text(_ctrlDia.text, style: const pw.TextStyle(fontSize: 11))),
                        pw.Center(child: pw.Text(_ctrlMes.text, style: const pw.TextStyle(fontSize: 11))),
                        pw.Center(child: pw.Text(_ctrlAnio.text, style: const pw.TextStyle(fontSize: 11))),
                      ]),
                    ]
                  ),
                ]
              ),
              pw.SizedBox(height: 15),
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {0: const pw.FlexColumnWidth(1), 1: const pw.FlexColumnWidth(5), 2: const pw.FlexColumnWidth(1.5), 3: const pw.FlexColumnWidth(1.5)},
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Center(child: pw.Text("CANT", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Center(child: pw.Text("CONCEPTO / DESCRIPCIÓN", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Center(child: pw.Text("PRECIO", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Center(child: pw.Text("P. TOTAL", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)))),
                    ]
                  ),
                  ..._itemsFactura.map((item) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Center(child: pw.Text(item['cant'].toString(), style: const pw.TextStyle(fontSize: 9)))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item['concepto'], style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(item['precio'].toStringAsFixed(2), style: const pw.TextStyle(fontSize: 9)))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(item['total'].toStringAsFixed(2), style: const pw.TextStyle(fontSize: 9)))),
                    ]
                  )),
                ]
              ),
              pw.SizedBox(height: 15),
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Container(padding: const pw.EdgeInsets.all(5), decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)), child: pw.Text("NOTAS: ${_ctrlNotas.text.toUpperCase()}", style: const pw.TextStyle(fontSize: 8)))),
                  pw.SizedBox(width: 10),
                  pw.Expanded(flex: 2, child: pw.Table(border: pw.TableBorder.all(width: 0.5), children: [
                    pw.TableRow(children: [pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("SUB-TOTAL")), pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(_subtotal.toStringAsFixed(2))))]),
                    pw.TableRow(children: [pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("I.V.A. (16%)")), pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(_iva.toStringAsFixed(2))))]),
                    pw.TableRow(children: [pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("TOTAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))), pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(_total.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))))]),
                  ])),
                ]
              )
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildSectionCard("1. DATOS FISCALES DEL CLIENTE", [
                  _buildSearchBar("Buscar Cliente...", _buscarCliente, Icons.person_search),
                  if (_sugerenciasClientes.isNotEmpty) _buildSuggestionsClientes(),
                  const SizedBox(height: 15),
                  _inputField("Nombre o Razón Social", _ctrlNombreCliente, Icons.person),
                  const SizedBox(height: 15),
                  _inputField("Domicilio Fiscal", _ctrlDirCliente, Icons.location_on),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(child: _inputField("R.I.F.", _ctrlRifCliente, Icons.badge)),
                    const SizedBox(width: 15),
                    Expanded(child: _inputField("Teléfono", _ctrlTelfCliente, Icons.phone)),
                  ]),
                ]),
                const SizedBox(height: 20),
                _buildSectionCard("2. CONCEPTOS DE LA FACTURA", [
                  _buildSearchBar("Buscar en Inventario...", _buscarProducto, Icons.inventory),
                  if (_sugerenciasProductos.isNotEmpty) _buildSuggestionsProductos(),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(flex: 1, child: _itemInput("Cant", _itemCant)),
                    const SizedBox(width: 10),
                    Expanded(flex: 4, child: _itemInput("Concepto", _itemConcepto)),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: _itemInput("Precio", _itemPrecio)),
                    const SizedBox(width: 10),
                    IconButton(icon: Icon(Icons.add_circle, color: brandRed, size: 35), onPressed: _agregarItem)
                  ]),
                  const SizedBox(height: 20),
                  _buildItemsDataTable(),
                  const SizedBox(height: 20),
                  _inputField("Notas / Observaciones", _ctrlNotas, Icons.edit_note),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildSectionCard("3. CONTROL Y TOTALES", [
                  _inputField("N° Factura", _ctrlNroFactura, Icons.numbers),
                  const SizedBox(height: 10),
                  _inputField("N° Control", _ctrlNroControl, Icons.verified),
                  const Divider(color: Colors.white10, height: 30),
                  _displayTotalRow("SUB-TOTAL", _subtotal),
                  _displayTotalRow("I.V.A. (16%)", _iva),
                  const Divider(color: Colors.white10, height: 30),
                  _displayTotalRow("TOTAL A PAGAR", _total, isGrandTotal: true),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _itemsFactura.isEmpty ? null : _procesarFacturaFinal,
                    style: ElevatedButton.styleFrom(backgroundColor: brandRed, minimumSize: const Size(double.infinity, 55)),
                    icon: const Icon(Icons.print, color: Colors.white),
                    label: const Text("GUARDAR Y GENERAR PDF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---
  Widget _buildSearchBar(String hint, Function(String) onSearch, IconData icon) {
    return TextField(
      onChanged: onSearch,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: Colors.white),
        filled: true, fillColor: inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSuggestionsClientes() {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(8)),
      child: Column(children: _sugerenciasClientes.map((c) => ListTile(
        title: Text(c['nombre']!, style: const TextStyle(color: Colors.white, fontSize: 12)),
        onTap: () => setState(() {
          _ctrlNombreCliente.text = c['nombre']!; _ctrlRifCliente.text = c['id']!;
          _ctrlDirCliente.text = c['dir']!; _ctrlTelfCliente.text = c['tel']!;
          _sugerenciasClientes = [];
        }),
      )).toList()),
    );
  }

  Widget _buildSuggestionsProductos() {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(8)),
      child: Column(children: _sugerenciasProductos.map((p) => ListTile(
        title: Text(p['nombre'], style: const TextStyle(color: Colors.white, fontSize: 12)),
        subtitle: Text("Stock: ${p['stock']}", style: const TextStyle(color: Colors.white38, fontSize: 10)),
        onTap: () => setState(() {
          _itemConcepto.text = p['nombre']; _itemPrecio.text = p['precio'].toString();
          _sugerenciasProductos = [];
        }),
      )).toList()),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20), ...children,
      ]),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl, style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        prefixIcon: Icon(icon, color: Colors.white, size: 18),
        filled: true, fillColor: inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _itemInput(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl, style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: label, hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
        filled: true, fillColor: inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildItemsDataTable() {
    return SizedBox(
      width: double.infinity,
      child: DataTable(
        headingRowHeight: 40,
        columns: const [
          DataColumn(label: Text("CANT", style: TextStyle(color: Colors.white38))),
          DataColumn(label: Text("CONCEPTO", style: TextStyle(color: Colors.white38))),
          DataColumn(label: Text("TOTAL", style: TextStyle(color: Colors.white38))),
          DataColumn(label: Text("", style: TextStyle(color: Colors.white38))),
        ],
        rows: _itemsFactura.map((item) => DataRow(cells: [
          DataCell(Text(item['cant'].toString(), style: const TextStyle(color: Colors.white))),
          DataCell(Text(item['concepto'], style: const TextStyle(color: Colors.white))),
          DataCell(Text("\$${item['total'].toStringAsFixed(2)}", style: const TextStyle(color: Colors.white))),
          DataCell(IconButton(icon: const Icon(Icons.close, color: Colors.white24, size: 16), onPressed: () => setState(() => _itemsFactura.remove(item)))),
        ])).toList(),
      ),
    );
  }

  Widget _displayTotalRow(String label, double value, {bool isGrandTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isGrandTotal ? Colors.white : Colors.white38, fontSize: isGrandTotal ? 14 : 12)),
          Text("\$${value.toStringAsFixed(2)}", style: TextStyle(color: isGrandTotal ? brandRed : Colors.white, fontSize: isGrandTotal ? 20 : 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}