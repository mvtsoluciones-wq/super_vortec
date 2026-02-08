import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DiagnosticScreen extends StatefulWidget {
  final String plate; 
  const DiagnosticScreen({super.key, required this.plate});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  final Map<String, bool> _selectedItems = {};
  late Stream<QuerySnapshot> _diagnosticosStream;

  @override
  void initState() {
    super.initState();
    // Consulta a Firebase filtrando por la placa del vehículo
    _diagnosticosStream = FirebaseFirestore.instance
        .collection('diagnosticos')
        .where('placa_vehiculo', isEqualTo: widget.plate)
        .snapshots();
  }

  // Función para abrir el reporte PDF del escáner
  Future<void> _launchScannerReport(String? dynamicUrl) async {
    final String url = (dynamicUrl != null && dynamicUrl.isNotEmpty) 
        ? dynamicUrl 
        : 'https://usait.x431.com/Home/Report/reportDetail/diagnose_record_id/592733fbge3bOM54nRKw54Dh2Y/report_type/X2/l/es'; 
    
    final Uri uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
        title: Text("Diagnóstico: ${widget.plate}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _diagnosticosStream, 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
             return const Center(child: Text("Sin diagnósticos pendientes.", style: TextStyle(color: Colors.grey)));
          }

          final docs = snapshot.data!.docs;

          double calculatedTotal = 0.0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final String docId = doc.id;
            bool isApproved = data['estado'] == 'aprobado';
            
            if (!isApproved && _selectedItems[docId] == true) {
              calculatedTotal += (data['total_reparacion'] ?? 0.0).toDouble();
            }
          }

          String? linkScanner;
          try {
            linkScanner = docs.firstWhere((d) {
              final data = d.data() as Map<String, dynamic>;
              return data.containsKey('link_escanner') && data['link_escanner'] != null;
            }).get('link_escanner');
          } catch (_) {
            linkScanner = null;
          }

          return Column(
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
                  onPressed: () => _launchScannerReport(linkScanner),
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
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final String docId = docs[index].id;
                    
                    bool isApproved = data['estado'] == 'aprobado';

                    if (!isApproved) {
                      _selectedItems.putIfAbsent(docId, () => false);
                    }

                    String urgencia = data['urgencia'] ?? "Verde";
                    Color statusColor = urgencia == "Rojo" ? Colors.red : (urgencia == "Amarillo" ? Colors.orange : Colors.green);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border(left: BorderSide(color: statusColor, width: 5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(data['sistema_reparar'] ?? "Sistema", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              if (isApproved)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(5)),
                                  child: const Text("APROBADO", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                )
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Presupuesto: ${data['numero_presupuesto'] ?? 'N/A'}",
                            style: TextStyle(color: Colors.blue[200], fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 15),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (!isApproved)
                                Transform.scale(
                                  scale: 1.2,
                                  child: Checkbox(
                                    activeColor: const Color(0xFFD50000),
                                    checkColor: Colors.white,
                                    value: _selectedItems[docId] ?? false,
                                    onChanged: (val) {
                                      setState(() => _selectedItems[docId] = val!);
                                    },
                                  ),
                                ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Reparación", style: TextStyle(color: Colors.grey, fontSize: 10)),
                                  Text("\$${(data['total_reparacion'] ?? 0).toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                ],
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (context) => BudgetDetailScreen(item: data))
                                  );
                                },
                                icon: const Icon(Icons.play_circle_fill, size: 20, color: Colors.red), 
                                label: const Text("Ver Detalle", style: TextStyle(color: Colors.white, fontSize: 12)),
                              )
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
                        Text("\$${calculatedTotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: calculatedTotal > 0 ? const Color(0xFFD50000) : Colors.grey[800],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: calculatedTotal > 0 ? () => _showApprovalDialog(context, calculatedTotal, docs) : null,
                        child: const Text("APROBAR REPARACIÓN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 6), Text(text, style: const TextStyle(color: Colors.white70, fontSize: 10))]);
  }

  void _showApprovalDialog(BuildContext context, double total, List<QueryDocumentSnapshot> allDocs) {
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
              const Text("¿Confirmar Aprobación?", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Se autorizará un total de: \$${total.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD50000)),
                  onPressed: () async {
                    Navigator.pop(ctx); 

                    final batch = FirebaseFirestore.instance.batch();
                    Set<String> numerosPresupuestos = {};
                    List<String> itemsAprobados = [];

                    for (var doc in allDocs) {
                      if (_selectedItems[doc.id] == true) {
                        batch.update(doc.reference, {
                          'estado': 'aprobado',
                          'fecha_aprobacion': FieldValue.serverTimestamp()
                        });
                        var data = doc.data() as Map<String, dynamic>;
                        if (data['numero_presupuesto'] != null) {
                          numerosPresupuestos.add(data['numero_presupuesto']);
                        }
                        itemsAprobados.add(data['sistema_reparar'] ?? "Item");
                      }
                    }

                    try {
                      await batch.commit();
                      
                      if (!context.mounted) return;

                      String presupuestosString = numerosPresupuestos.join(", ");
                      if (presupuestosString.isEmpty) presupuestosString = "Varios";

                      await FirebaseFirestore.instance.collection('notificaciones').add({
                        'titulo': 'REPARACIÓN APROBADA',
                        'mensaje': 'Cliente aprobó: ${itemsAprobados.length} ítems.',
                        'monto': total,
                        'placa': widget.plate,
                        'numero_presupuesto': presupuestosString,
                        'fecha': FieldValue.serverTimestamp(),
                        'leido': false,
                        'tipo': 'aprobacion'
                      });

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("¡Aprobación enviada al taller con éxito!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                      
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Error al enviar. Verifica tu internet.")),
                      );
                    }
                  },
                  child: const Text("CONFIRMAR Y ENVIAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class BudgetDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const BudgetDetailScreen({super.key, required this.item});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  late YoutubePlayerController _controller;
  bool _hasVideo = false;

  @override
  void initState() {
    super.initState();
    String videoUrl = widget.item['link_video'] ?? "";
    
    if (videoUrl.isEmpty) {
      videoUrl = widget.item['url_evidencia_video'] ?? "";
    }

    String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
    _hasVideo = videoId != null;

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
    final List breakdown = widget.item['presupuesto_items'] ?? [];
    const Color bgDark = Color(0xFF121212);
    const Color cardColor = Color(0xFF1E1E1E);

    Widget content = Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        title: const Text("Detalles",
            style: TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item['sistema_reparar'] ?? "Detalle",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            
            // ELIMINADO EL BLOQUE DE TEXTO GRIS DE "PINTURA GENERAL" (falla_detectada)
            
            const SizedBox(height: 25),

            if (_hasVideo) ...[
              const Text("VIDEO DEL DIAGNÓSTICO",
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 5))
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.red,
                  bottomActions: [
                    CurrentPosition(),
                    ProgressBar(isExpanded: true, colors: const ProgressBarColors(
                      playedColor: Colors.red,
                      handleColor: Colors.redAccent
                    )),
                    RemainingDuration(),
                    FullScreenButton(),
                  ],
                ),
              ),
            ] else ...[
               Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(
                   border: Border.all(color: Colors.white12),
                   borderRadius: BorderRadius.circular(10)
                 ),
                 child: const Column(
                   children: [
                     Icon(Icons.videocam_off, color: Colors.grey, size: 40),
                     SizedBox(height: 10),
                     Text("Sin video adjunto para este ítem", style: TextStyle(color: Colors.grey))
                   ],
                 ),
               )
            ],

            const SizedBox(height: 30),
            
            const Text("PRESUPUESTO DETALLADO",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            Container(
              decoration: BoxDecoration(
                  color: cardColor, 
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    child: Row(
                      children: const [
                        Expanded(flex: 2, child: Text("DESCRIPCIÓN", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
                        Expanded(child: Text("CANT.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
                        Expanded(child: Text("PRECIO", textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 1),

                  ...breakdown.map((detail) {
                    var cant = detail['cantidad'];
                    var precio = detail['precio_venta'] ?? detail['precio_unitario'];
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              detail['descripcion'] ?? "Repuesto/Servicio",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              cant.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "\$${(precio ?? 0).toString()}",
                              textAlign: TextAlign.right,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  const Divider(color: Colors.white24),
                  
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("TOTAL ITEM",
                            style: TextStyle(
                                color: Color(0xFFD50000),
                                fontWeight: FontWeight.bold)),
                        Text(
                            "\$${(widget.item['total_reparacion'] ?? 0).toStringAsFixed(2)}",
                            style: const TextStyle(
                                color: Color(0xFFD50000),
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
              decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.5))),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Colors.green, size: 24),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("GARANTÍA INCLUIDA",
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      Text(widget.item['garantia'] ?? "N/A",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );

    if (_hasVideo) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(controller: _controller),
        builder: (context, player) => content,
      );
    } else {
      return content;
    }
  }
}