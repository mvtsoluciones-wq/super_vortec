import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // Importante para el video

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
    // 1. PRIORIDAD ROJA
    {
      "system": "Motor (ECM)",
      "code": "P0303",
      "title": "Fallo de Encendido Cilindro 3",
      "diagnosis": "Bobina de encendido quemada y bujía carbonizada. Se detectó resistencia infinita en el componente.",
      "priority": "CRÍTICA",
      "color": Colors.red, 
      "price": 85.00,
      "isSelected": true, 
      "isFixable": true,
      "videoUrl": "https://www.youtube.com/watch?v=wblL1YIDu-A", // Video de ejemplo
      "breakdown": [
        {"item": "Bobina Original AC Delco", "cost": 55.00},
        {"item": "Bujía Iridium", "cost": 10.00},
        {"item": "Mano de Obra", "cost": 20.00},
      ]
    },
    // 2. PRIORIDAD NARANJA
    {
      "system": "Admisión",
      "code": "P0171",
      "title": "Mezcla Pobre (Banco 1)",
      "diagnosis": "Sensor MAF sucio provocando lectura errónea de aire. Se recomienda limpieza y calibración.",
      "priority": "ALERTA",
      "color": Colors.orange, 
      "price": 35.00,
      "isSelected": false, 
      "isFixable": true,
      "videoUrl": "https://www.youtube.com/watch?v=YuUtjWC2y0s",
      "breakdown": [
        {"item": "Limpiador Electrónico", "cost": 10.00},
        {"item": "Mano de Obra / Calibración", "cost": 25.00},
      ]
    },
    {
      "system": "Suspensión",
      "code": "N/A",
      "title": "Bieletas Delanteras",
      "diagnosis": "Juego excesivo detectado en inspección visual. Generará ruido pronto.",
      "priority": "ALERTA",
      "color": Colors.orange, 
      "price": 60.00,
      "isSelected": false,
      "isFixable": true,
      "videoUrl": "https://www.youtube.com/watch?v=3XoBQPC-1vM",
      "breakdown": [
        {"item": "Par de Bieletas (Genéricas)", "cost": 30.00},
        {"item": "Instalación", "cost": 30.00},
      ]
    },
    // 3. PRIORIDAD VERDE
    {
      "system": "Frenos (ABS)",
      "code": "OK",
      "title": "Sistema de Frenado",
      "diagnosis": "Módulos y sensores operando correctamente. Vida útil pastillas 60%.",
      "priority": "ESTABLE",
      "color": Colors.green, 
      "price": 0.00,
      "isSelected": false,
      "isFixable": false, 
      "videoUrl": "",
      "breakdown": [] 
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

  Future<void> _launchScannerReport() async {
    const url = 'https://usait.x431.com/Home/Report/reportDetail/diagnose_record_id/592733fbge3bOM54nRKw54Dh2Y/report_type/X2/l/es'; 
    final Uri uri = Uri.parse(url);
    try {
      await launchUrl(
        uri, 
        mode: LaunchMode.inAppWebView,
        webViewConfiguration: const WebViewConfiguration(enableJavaScript: true),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se pudo cargar el reporte")));
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
              onPressed: _launchScannerReport,
              icon: const Icon(Icons.description, color: Colors.blueAccent),
              label: const Text("Ver reporte del escaner", style: TextStyle(color: Colors.white, letterSpacing: 1)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLegendItem(Colors.red, "Crítica"),
                _buildLegendItem(Colors.orange, "Media"),
                _buildLegendItem(Colors.green, "OK"),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _diagnosticItems.length,
              itemBuilder: (context, index) {
                final item = _diagnosticItems[index];
                final bool isFixable = item['isFixable'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border(left: BorderSide(color: item['color'], width: 5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(item['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: item['color'].withValues(alpha: 0.2), borderRadius: BorderRadius.circular(5)),
                            child: Text(item['code'], style: TextStyle(color: item['color'], fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: "Diagnóstico: ", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
                            TextSpan(text: item['diagnosis'], style: TextStyle(color: Colors.grey[500])),
                          ],
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 10),

                      if (isFixable)
                        Row(
                          children: [
                            Transform.scale(
                              scale: 1.2,
                              child: Checkbox(
                                activeColor: const Color(0xFFD50000),
                                checkColor: Colors.white,
                                value: item['isSelected'],
                                onChanged: (val) {
                                  setState(() {
                                    item['isSelected'] = val;
                                    _calculateTotal();
                                  });
                                },
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Reparación", style: TextStyle(color: Colors.grey, fontSize: 10)),
                                Text("\$${item['price'].toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              ],
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (context) => BudgetDetailScreen(item: item))
                                );
                              },
                              icon: const Icon(Icons.play_circle_fill, size: 20, color: Colors.red), // Icono Play
                              label: const Text("Ver Evidencia", style: TextStyle(color: Colors.white, fontSize: 12)),
                            )
                          ],
                        )
                      else
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text("Sistema Operativo", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        )
                    ],
                  ),
                );
              },
            ),
          ),

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
                    const Text("TOTAL A PAGAR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
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
                    onPressed: _totalPrice > 0 ? () => _showApprovalDialog(context) : null,
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

  Widget _buildLegendItem(Color color, String text) {
    return Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 6), Text(text, style: const TextStyle(color: Colors.white70, fontSize: 10))]);
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
              Text("Total autorizado: \$${_totalPrice.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 25),
              SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD50000)), onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text("VOLVER AL GARAJE", style: TextStyle(color: Colors.white))))
            ],
          ),
        ),
      ),
    );
  }
}

// --- PANTALLA DETALLE ACTUALIZADA (VIDEO + PRESUPUESTO) ---
class BudgetDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const BudgetDetailScreen({super.key, required this.item});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    String? videoId = YoutubePlayer.convertUrlToId(widget.item['videoUrl'] ?? "");
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? "", 
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false, forceHD: true),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List breakdown = widget.item['breakdown'] ?? [];
    const Color bgDark = Color(0xFF121212);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text("Evidencia y Costos", style: TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView( // Scroll por si el video es grande
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TÍTULO
            Text(widget.item['title'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // 2. DIAGNÓSTICO (Sin código, solo texto)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
              child: Text(
                widget.item['diagnosis'],
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
            ),
            
            const SizedBox(height: 25),
            
            // 3. VIDEO DE LA FALLA (Cuadrícula)
            if (widget.item['videoUrl'] != null && widget.item['videoUrl'].isNotEmpty) ...[
              const Text("EVIDENCIA EN VIDEO", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                clipBehavior: Clip.antiAlias, // Para redondear el video
                child: YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.red,
                  bottomActions: [
                    CurrentPosition(),
                    ProgressBar(isExpanded: true, colors: const ProgressBarColors(playedColor: Colors.red, handleColor: Colors.redAccent)),
                    RemainingDuration(),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // 4. DESGLOSE DEL PRESUPUESTO
            const Text("PRESUPUESTO DETALLADO", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  ...breakdown.map((detail) => Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(detail['item'], style: const TextStyle(color: Colors.white70)),
                        Text("\$${detail['cost'].toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("TOTAL ITEM", style: TextStyle(color: Color(0xFFD50000), fontWeight: FontWeight.bold)),
                      Text("\$${widget.item['price'].toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFD50000), fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}