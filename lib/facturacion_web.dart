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
  // Colores corporativos
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // Datos de prueba: Historial de facturas
  final List<Map<String, dynamic>> _facturasEmitidas = [
    {"nro": "FAC-0001", "cliente": "Juan Pérez", "total": 174.00, "fecha": "18/01/2026"},
    {"nro": "FAC-0002", "cliente": "Talleres ABC", "total": 464.00, "fecha": "18/01/2026"},
  ];

  // Datos de la factura actual en edición
  String _clienteActual = "Seleccionar Cliente...";
  double _montoActual = 0.0;
  String _nroFacturaActual = "FAC-0003";

  // Función para generar PDF Legal
  Future<void> _generateInvoicePdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("SUPER VORTEC 5.3 - FACTURA", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text(_nroFacturaActual, style: pw.TextStyle(fontSize: 16, color: PdfColors.red)),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text("CLIENTE: $_clienteActual"),
              pw.Text("FECHA DE EMISIÓN: 18/01/2026"),
              pw.SizedBox(height: 40),
              pw.TableHelper.fromTextArray(
                context: context,
                data: [
                  ['Descripción', 'Monto'],
                  ['Servicios Mecánicos y Repuestos', "\$${_montoActual.toStringAsFixed(2)}"],
                  ['TOTAL A PAGAR', "\$${(_montoActual * 1.16).toStringAsFixed(2)}"],
                ],
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _guardarFactura() {
    setState(() {
      _facturasEmitidas.add({
        "nro": _nroFacturaActual,
        "cliente": _clienteActual,
        "total": _montoActual * 1.16,
        "fecha": "18/01/2026"
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Factura guardada y enviada a la App"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- GENERADOR DE FACTURA ---
          Expanded(
            flex: 2,
            child: _buildInvoiceForm(),
          ),
          const SizedBox(width: 30),
          // --- LEYENDA / HISTORIAL ---
          Expanded(
            flex: 2,
            child: _buildInvoiceHistory(),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceForm() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandRed.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("EMISIÓN DE FACTURA", style: TextStyle(color: brandRed, fontWeight: FontWeight.bold)),
              Text(_nroFacturaActual, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 30),
          _buildReadOnlyField("Cliente", _clienteActual, Icons.person),
          const SizedBox(height: 20),
          _buildReadOnlyField("Monto Base (\$)", "\$${_montoActual.toStringAsFixed(2)}", Icons.monetization_on),
          const SizedBox(height: 40),
          const Divider(color: Colors.white10),
          _buildTotalSection(),
          const SizedBox(height: 30),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 9)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(icon, color: brandRed, size: 18),
              const SizedBox(width: 15),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("TOTAL CON IVA (16%)", style: TextStyle(color: Colors.white70, fontSize: 12)),
        Text("\$${(_montoActual * 1.16).toStringAsFixed(2)}", 
          style: TextStyle(color: brandRed, fontSize: 24, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _guardarFactura,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text("GUARDAR Y ENVIAR A APP"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _generateInvoicePdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text("IMPRIMIR COMPROBANTE PDF"),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24)),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceHistory() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("LEYENDA DE FACTURAS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _facturasEmitidas.length,
              itemBuilder: (context, index) {
                final f = _facturasEmitidas[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f['nro'], style: TextStyle(color: brandRed, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(f['cliente'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                      const Spacer(),
                      Text("\$${f['total']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 15),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 18),
                        onPressed: () => setState(() => _facturasEmitidas.removeAt(index)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}