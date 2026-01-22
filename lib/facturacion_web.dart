import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// --- IMPORTACIONES ---
import 'config_factura_web.dart'; 
// Asumimos que estos archivos exportan una lista llamada listaClientes y listaInventario
// import 'clientes_web.dart'; 
// import 'inventario_web.dart';

class FacturacionWebModule extends StatefulWidget {
  const FacturacionWebModule({super.key});

  @override
  State<FacturacionWebModule> createState() => _FacturacionWebModuleState();
}

class _FacturacionWebModuleState extends State<FacturacionWebModule> {
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // Estilos de texto grandes
  final TextStyle labelStyle = const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold);
  final TextStyle inputTextStyle = const TextStyle(color: Colors.white, fontSize: 20);
  final TextStyle titleStyle = const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900);

  // --- DATOS DEL CLIENTE ---
  final TextEditingController _ctrlNombre = TextEditingController();
  final TextEditingController _ctrlRif = TextEditingController();
  final TextEditingController _ctrlTelf = TextEditingController();
  final TextEditingController _ctrlDir = TextEditingController();

  // --- CONTROL DE FACTURA (Editable y Secuencial) ---
  final TextEditingController _ctrlFacturaN = TextEditingController(text: "0919");
  final TextEditingController _ctrlControlN = TextEditingController(text: "00-0919");
  final TextEditingController _ctrlGarantia = TextEditingController(text: "30 DÍAS");

  // --- CONCEPTOS ---
  final TextEditingController _itemConcepto = TextEditingController();
  final TextEditingController _itemPrecio = TextEditingController();
  final TextEditingController _itemCant = TextEditingController(text: "1");

  // --- ESTADO ---
  bool _ivaActivo = true;
  List<Map<String, dynamic>> _itemsFactura = [];
  List<Map<String, dynamic>> _facturasGuardadas = [];
  DateTime _fechaFiltro = DateTime.now();

  // Bases de datos simuladas (Sustituir por los imports de clientes_web e inventario_web)
  final List<Map<String, String>> _dbClientes = [
    {"nombre": "PRODUCTOS RONAVA C.A.", "id": "J-00030157-3", "tel": "(0212)239.64.13", "dir": "Los Ruices, Caracas"},
  ];
  final List<Map<String, dynamic>> _dbInventario = [
    {"nombre": "CÁMARA DOMO 1080P", "precio": 45.00, "stock": 25},
    {"nombre": "DVR 4 CANALES", "precio": 85.50, "stock": 10},
  ];

  List<Map<String, String>> _sugerenciasClientes = [];
  List<Map<String, dynamic>> _sugerenciasProductos = [];

  double get _subtotal => _itemsFactura.fold(0, (sum, item) => sum + item['total']);
  double get _montoIva => _ivaActivo ? (_subtotal * 0.16) : 0;
  double get _total => _subtotal + _montoIva;

  void _agregarItem() {
    if (_itemConcepto.text.isEmpty) return;
    double p = double.tryParse(_itemPrecio.text) ?? 0;
    int c = int.tryParse(_itemCant.text) ?? 1;
    setState(() {
      _itemsFactura.add({
        "linea": _itemsFactura.length + 1,
        "concepto": _itemConcepto.text.toUpperCase(),
        "precio": p,
        "cant": c,
        "total": p * c
      });
      _itemConcepto.clear(); _itemPrecio.clear(); _itemCant.text = "1";
    });
  }

  void _guardarFactura() {
    if (_itemsFactura.isEmpty) return;
    setState(() {
      _facturasGuardadas.add({
        "nro": _ctrlFacturaN.text,
        "control": _ctrlControlN.text,
        "cliente": _ctrlNombre.text,
        "monto": _total,
        "fecha": DateTime.now(),
      });
      // Secuencia automática
      int nro = (int.tryParse(_ctrlFacturaN.text) ?? 0) + 1;
      _ctrlFacturaN.text = nro.toString().padLeft(4, '0');
      _itemsFactura.clear();
      _ctrlNombre.clear(); _ctrlRif.clear(); _ctrlTelf.clear(); _ctrlDir.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Factura guardada exitosamente")));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _seccionIzquierda()),
              const SizedBox(width: 30),
              Expanded(flex: 1, child: _seccionDerechaTotales()),
            ],
          ),
          const SizedBox(height: 60),
          _seccionHistorial(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(ConfigFactura.logoPath, height: 120, errorBuilder: (c, e, s) => Icon(Icons.bolt, color: brandRed, size: 80)),
        Column(
          children: [
            _inputSecuencia("FACTURA N:", _ctrlFacturaN),
            const SizedBox(height: 10),
            _inputSecuencia("N DE CONTROL", _ctrlControlN),
          ],
        )
      ],
    );
  }

  Widget _seccionIzquierda() {
    return Column(
      children: [
        _buildCard("DATOS FISCALES DEL CLIENTE", [
          _buildSearchBar("Buscar cliente...", (v) {
            setState(() => _sugerenciasClientes = v.isEmpty ? [] : _dbClientes.where((c) => c['nombre']!.contains(v.toUpperCase())).toList());
          }, Icons.person_search),
          if (_sugerenciasClientes.isNotEmpty) _listadoClientes(),
          const SizedBox(height: 25),
          _field("Nombre o Razón Social", _ctrlNombre, Icons.business),
          const SizedBox(height: 15),
          _field("Domicilio Fiscal", _ctrlDir, Icons.map),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: _field("R.I.F o Cédula", _ctrlRif, Icons.badge)),
            const SizedBox(width: 15),
            Expanded(child: _field("Teléfono", _ctrlTelf, Icons.phone)),
          ]),
        ]),
        const SizedBox(height: 30),
        _buildCard("CONCEPTOS DE FACTURA", [
          _buildSearchBar("Buscar en Inventario...", (v) {
            setState(() => _sugerenciasProductos = v.isEmpty ? [] : _dbInventario.where((p) => p['nombre'].contains(v.toUpperCase())).toList());
          }, Icons.inventory),
          if (_sugerenciasProductos.isNotEmpty) _listadoProductos(),
          const SizedBox(height: 25),
          Row(children: [
            Expanded(flex: 3, child: _fieldSimple("Concepto", _itemConcepto)),
            const SizedBox(width: 10),
            Expanded(flex: 1, child: _fieldSimple("Precio \$", _itemPrecio)),
            const SizedBox(width: 10),
            Expanded(flex: 1, child: _fieldSimple("Cant", _itemCant)),
            const SizedBox(width: 10),
            IconButton(icon: Icon(Icons.add_circle, color: brandRed, size: 50), onPressed: _agregarItem)
          ]),
          const SizedBox(height: 20),
          _buildTablaItems(),
          const SizedBox(height: 25),
          _field("Detalle de Garantía", _ctrlGarantia, Icons.verified),
        ]),
      ],
    );
  }

  Widget _seccionDerechaTotales() {
    return _buildCard("RESUMEN DE PAGO", [
      _filaResumen("SUB-TOTAL", _subtotal),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("I.V.A. (16%)", style: labelStyle),
          Transform.scale(scale: 1.4, child: Switch(value: _ivaActivo, activeColor: brandRed, onChanged: (v) => setState(() => _ivaActivo = v))),
        ],
      ),
      if (_ivaActivo) _filaResumen("MONTO IVA", _montoIva),
      const Divider(color: Colors.white24, height: 40),
      _filaResumen("TOTAL A PAGAR", _total, destacar: true),
      const SizedBox(height: 40),
      _btn("GUARDAR FACTURA", Colors.green[800]!, _guardarFactura),
      const SizedBox(height: 15),
      _btn("CREAR PDF", brandRed, _generarFacturaPDF),
    ]);
  }

  Widget _seccionHistorial() {
    return _buildCard("HISTORIAL DE FACTURAS GUARDADAS", [
      Row(children: [
        Text("FILTRAR FECHA: ", style: labelStyle),
        const SizedBox(width: 20),
        ActionChip(
          label: Text("${_fechaFiltro.day}/${_fechaFiltro.month}/${_fechaFiltro.year}", style: inputTextStyle),
          onPressed: () async {
            DateTime? pick = await showDatePicker(context: context, initialDate: _fechaFiltro, firstDate: DateTime(2025), lastDate: DateTime(2030));
            if (pick != null) setState(() => _fechaFiltro = pick);
          },
        )
      ]),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(inputFill),
          columns: const [
            DataColumn(label: Text("NRO")), DataColumn(label: Text("CLIENTE")),
            DataColumn(label: Text("TOTAL")), DataColumn(label: Text("ACCIÓN"))
          ],
          rows: _facturasGuardadas.map((f) => DataRow(cells: [
            DataCell(Text(f['nro'], style: inputTextStyle)),
            DataCell(Text(f['cliente'], style: const TextStyle(color: Colors.white70, fontSize: 18))),
            DataCell(Text("\$${f['monto'].toStringAsFixed(2)}", style: inputTextStyle)),
            DataCell(IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white38), onPressed: () => setState(() => _facturasGuardadas.remove(f)))),
          ])).toList(),
        ),
      )
    ]);
  }

  // --- WIDGETS DE SOPORTE ---
  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: brandRed, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 25), ...children
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: labelStyle),
      const SizedBox(height: 10),
      TextField(controller: ctrl, style: inputTextStyle, decoration: InputDecoration(prefixIcon: Icon(icon, color: Colors.white60), filled: true, fillColor: inputFill)),
    ]);
  }

  Widget _fieldSimple(String hint, TextEditingController ctrl) {
    return TextField(controller: ctrl, style: inputTextStyle, decoration: InputDecoration(hintText: hint, filled: true, fillColor: inputFill));
  }

  Widget _inputSecuencia(String label, TextEditingController ctrl) {
    return SizedBox(
      width: 250,
      child: TextField(
        controller: ctrl,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white38, fontSize: 12), enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white10))),
      ),
    );
  }

  Widget _buildSearchBar(String hint, Function(String) onSearch, IconData icon) {
    return TextField(onChanged: onSearch, style: inputTextStyle, decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: brandRed), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))));
  }

  Widget _listadoClientes() {
    return Container(color: inputFill, child: Column(children: _sugerenciasClientes.map((c) => ListTile(title: Text(c['nombre']!, style: inputTextStyle), onTap: () => setState(() { _ctrlNombre.text = c['nombre']!; _ctrlRif.text = c['id']!; _ctrlDir.text = c['dir']!; _ctrlTelf.text = c['tel']!; _sugerenciasClientes = []; }))).toList()));
  }

  Widget _listadoProductos() {
    return Container(color: inputFill, child: Column(children: _sugerenciasProductos.map((p) => ListTile(title: Text(p['nombre'], style: inputTextStyle), trailing: Text("\$${p['precio']}", style: TextStyle(color: brandRed, fontSize: 20)), onTap: () => setState(() { _itemConcepto.text = p['nombre']; _itemPrecio.text = p['precio'].toString(); _sugerenciasProductos = []; }))).toList()));
  }

  Widget _buildTablaItems() {
    return SizedBox(
      width: double.infinity,
      child: DataTable(
        columns: const [DataColumn(label: Text("CANT")), DataColumn(label: Text("CONCEPTO")), DataColumn(label: Text("TOTAL"))],
        rows: _itemsFactura.map((i) => DataRow(cells: [
          DataCell(Text(i['cant'].toString(), style: inputTextStyle)),
          DataCell(Text(i['concepto'], style: const TextStyle(color: Colors.white70, fontSize: 18))),
          DataCell(Text("\$${i['total']}", style: inputTextStyle)),
        ])).toList(),
      ),
    );
  }

  Widget _filaResumen(String label, double val, {bool destacar = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: destacar ? titleStyle : labelStyle),
        Text("\$${val.toStringAsFixed(2)}", style: TextStyle(color: destacar ? brandRed : Colors.white, fontSize: destacar ? 35 : 22, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _btn(String t, Color c, VoidCallback f) {
    return SizedBox(width: double.infinity, height: 65, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: f, child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))));
  }

  Future<void> _generarFacturaPDF() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      build: (context) => pw.Column(children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text("SUPER VORTEC / MVT", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
          pw.Column(children: [pw.Text("FACTURA N: ${_ctrlFacturaN.text}"), pw.Text("CONTROL N: ${_ctrlControlN.text}")])
        ]),
        pw.SizedBox(height: 20),
        pw.Text("EMISOR: ${ConfigFactura.nombreEmpresa}"),
        pw.Text("RIF: ${ConfigFactura.rifEmpresa}"),
        pw.Divider(),
        pw.Text("CLIENTE: ${_ctrlNombre.text}"),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(data: _itemsFactura.map((i) => [i['cant'], i['concepto'], i['total']]).toList()),
        pw.SizedBox(height: 30),
        pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text("TOTAL A PAGAR: \$${_total.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 40),
        pw.Text("GARANTÍA: ${_ctrlGarantia.text}"),
      ]),
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}