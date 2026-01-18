import 'package:flutter/material.dart';
// Ahora estos imports se usarán en la función _imprimirPDF
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

  String _clienteActual = "Sin Seleccionar";
  double _montoRepuestos = 0.0;
  double _montoServicios = 0.0;
  String _nroFacturaActual = "FAC-0001";
  final List<Map<String, dynamic>> _facturasEmitidas = [];

  double get _subtotal => _montoRepuestos + _montoServicios;
  double get _iva => _subtotal * 0.16;
  double get _total => _subtotal + _iva;

  // --- FUNCIÓN QUE ELIMINA LOS ERRORES DE UNUSED IMPORT ---
  Future<void> _imprimirPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("SUPER VORTEC 5.3", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(brandRed.toARGB32()))),
              pw.Text("Factura Nro: $_nroFacturaActual"),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text("Cliente: $_clienteActual"),
              pw.Text("Fecha: ${DateTime.now().toString()}"),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                data: <List<String>>[
                  ['Concepto', 'Monto'],
                  ['Repuestos', "\$${_montoRepuestos.toStringAsFixed(2)}"],
                  ['Mano de Obra', "\$${_montoServicios.toStringAsFixed(2)}"],
                  ['IVA (16%)', "\$${_iva.toStringAsFixed(2)}"],
                  ['TOTAL', "\$${_total.toStringAsFixed(2)}"],
                ],
              ),
            ],
          );
        },
      ),
    );

    // Abre el menú de impresión del navegador/sistema
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _seleccionarCaso(String cliente, double r, double s) {
    setState(() {
      _clienteActual = cliente;
      _montoRepuestos = r;
      _montoServicios = s;
      _nroFacturaActual = "FAC-${(_facturasEmitidas.length + 1).toString().padLeft(4, '0')}";
    });
  }

  void _guardarFactura() {
    if (_clienteActual == "Sin Seleccionar") return;
    setState(() {
      _facturasEmitidas.add({
        "nro": _nroFacturaActual,
        "cliente": _clienteActual,
        "total": _total,
        "fecha": "18/01/2026",
      });
      _clienteActual = "Sin Seleccionar";
      _montoRepuestos = 0.0;
      _montoServicios = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Row(
        children: [
          // PANEL IZQUIERDO: GENERADOR
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("GENERAR FACTURA", style: TextStyle(color: brandRed, fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    children: [
                      ActionChip(label: const Text("Importar Juan"), onPressed: () => _seleccionarCaso("Juan Pérez", 120, 50)),
                      ActionChip(label: const Text("Importar María"), onPressed: () => _seleccionarCaso("María García", 80, 40)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _datoLabel("CLIENTE", _clienteActual),
                  _datoLabel("SUBTOTAL", "\$${_subtotal.toStringAsFixed(2)}"),
                  _datoLabel("TOTAL CON IVA", "\$${_total.toStringAsFixed(2)}"),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _imprimirPDF, // USO DE LA LIBRERÍA PDF/PRINTING
                          icon: const Icon(Icons.print),
                          label: const Text("PDF / IMPRIMIR"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _guardarFactura,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
                          icon: const Icon(Icons.save),
                          label: const Text("GUARDAR"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          // PANEL DERECHO: LEYENDA
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("LEYENDA DE FACTURAS", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _facturasEmitidas.length,
                      itemBuilder: (context, index) {
                        final f = _facturasEmitidas[index];
                        return ListTile(
                          title: Text(f['cliente'], style: const TextStyle(color: Colors.white)),
                          subtitle: Text(f['nro'], style: const TextStyle(color: Colors.white24)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(() => _facturasEmitidas.removeAt(index)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _datoLabel(String l, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l, style: const TextStyle(color: Colors.white24, fontSize: 10)),
          Text(v, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}