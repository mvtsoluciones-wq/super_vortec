import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  // Estado del Total
  double _totalPrice = 0.0;

  // DATOS DE DIAGNÓSTICO
  final List<Map<String, dynamic>> _diagnosticItems = [
    {
      "system": "Motor (ECM)",
      "code": "P0303",
      "title": "Fallo de Encendido Cilindro 3",
      "diagnosis": "Bobina de encendido quemada y bujía carbonizada. Requiere reemplazo inmediato.",
      "priority": "CRÍTICA",
      "color": Colors.red, // SEMÁFORO ROJO
      "price": 85.00,
      "isSelected": true, 
      "isFixable": true,
    },
    {
      "system": "Admisión",
      "code": "P0171",
      "title": "Mezcla Pobre (Banco 1)",
      "diagnosis": "Sensor MAF sucio. Se recomienda limpieza y calibración.",
      "priority": "ALERTA",
      "color": Colors.orange, // SEMÁFORO NARANJA
      "price": 35.00,
      "isSelected": false, 
      "isFixable": true,
    },
    {
      "system": "Frenos (ABS)",
      "code": "OK",
      "title": "Sistema de Frenado",
      "diagnosis": "Módulos y sensores operando correctamente. Vida útil pastillas 60%.",
      "priority": "ESTABLE",
      "color": Colors.green, // SEMÁFORO VERDE
      "price": 0.00,
      "isSelected": false,
      "isFixable": false, 
    },
    {
      "system": "Suspensión",
      "code": "N/A",
      "title": "Bieletas Delanteras",
      "diagnosis": "Juego excesivo detectado en inspección visual. Generará ruido pronto.",
      "priority": "ALERTA",
      "color": Colors.orange, // SEMÁFORO NARANJA
      "price": 60.00,
      "isSelected": false,
      "isFixable": true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _calculateTotal();
  }

  void _calculateTotal() {
    double tempTotal = 0;
    for (var item in _diagnosticItems) {
      if (item['isSelected'] == true) {
        tempTotal += item['price'];
      }
    }
    setState(() {
      _totalPrice = tempTotal;
    });
  }

  // FUNCIÓN ACTUALIZADA: Abre el link ESPECÍFICO DENTRO de la App
  Future<void> _launchScannerReport() async {
    // 1. Tu enlace específico de Launch X431
    const url = 'https://usait.x431.com/Home/Report/reportDetail/diagnose_record_id/592733fbge3bOM54nRKw54Dh2Y/report_type/X2/l/es'; 
    final Uri uri = Uri.parse(url);
    
    try {
      // 2. Usamos 'inAppWebView' para que NO se salga de la aplicación
      await launchUrl(
        uri, 
        mode: LaunchMode.inAppWebView, // <--- ESTO HACE LA MAGIA
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo cargar el reporte del escaner")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF121212);
    const Color cardColor = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Resultados del Escáner", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. LINK AL REPORTE ORIGINAL
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: cardColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _launchScannerReport, // Llama a la nueva función
              icon: const Icon(Icons.description, color: Colors.blueAccent), // Icono azul para reporte
              label: const Text("Ver reporte del escaner", style: TextStyle(color: Colors.white, letterSpacing: 1)),
            ),
          ),

          // 2. LEYENDA DEL SEMÁFORO
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(Colors.red, "Prioridad Alta"),
                _buildLegendItem(Colors.orange, "Grado Medio"),
                _buildLegendItem(Colors.green, "No Grave / OK"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. LISTA SEMÁFORO Y CHECKBOXES
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _diagnosticItems.length,
              itemBuilder: (context, index) {
                final item = _diagnosticItems[index];
                final bool isFixable = item['isFixable'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border(
                      left: BorderSide(color: item['color'], width: 6), // EL SEMÁFORO VISUAL 🚦
                    ),
                  ),
                  child: Theme(
                    data: ThemeData(unselectedWidgetColor: Colors.grey),
                    child: CheckboxListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      activeColor: const Color(0xFFD50000),
                      checkColor: Colors.white,
                      value: item['isSelected'],
                      onChanged: isFixable 
                        ? (bool? value) {
                            setState(() {
                              item['isSelected'] = value;
                              _calculateTotal();
                            });
                          }
                        : null, 
                      
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['title'], 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)
                            ),
                          ),
                          if (isFixable)
                            Text(
                              "\$${item['price'].toStringAsFixed(0)}", 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: item['color'].withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              "${item['code']} - ${item['priority']}",
                              style: TextStyle(color: item['color'], fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(item['diagnosis'], style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. BARRA TOTALIZADORA Y BOTÓN APROBAR
          Container(
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.black, blurRadius: 20, offset: Offset(0, -5))]
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("PRESUPUESTO TOTAL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                    Text("\$${_totalPrice.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _totalPrice > 0 ? const Color(0xFFD50000) : Colors.grey[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _totalPrice > 0 ? () {
                      _showApprovalDialog(context);
                    } : null,
                    child: const Text("APROBAR REPARACIÓN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // WIDGET AUXILIAR PARA LA LEYENDA
  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showApprovalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, color: Colors.green, size: 50),
              const SizedBox(height: 20),
              const Text("¡Servicio Aprobado!", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                "Has autorizado reparaciones por un total de \$${_totalPrice.toStringAsFixed(2)}. \n\nEl taller ha sido notificado y comenzará a trabajar en tu vehículo.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD50000)),
                  onPressed: () {
                    Navigator.pop(ctx); 
                    Navigator.pop(context); 
                  }, 
                  child: const Text("VOLVER AL GARAJE", style: TextStyle(color: Colors.white))
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}