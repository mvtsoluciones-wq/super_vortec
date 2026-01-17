import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
// Importamos tu archivo de citas
import 'citas.dart';
import 'diagnostico.dart';

void main() {
  runApp(const SuperVortecApp());
}

class SuperVortecApp extends StatelessWidget {
  const SuperVortecApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mi Garaje',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD50000),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
      ),
      home: const ClientHomeScreen(),
    );
  }
}

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  // DATOS
  final List<Map<String, dynamic>> myVehicles = [
    {
      "brand": "CHEVROLET",
      "model": "SILVERADO",
      "year": "2008",
      "plate": "123 ASD",
      "color": "AZUL",
      "km": "250.000",
      "isInWorkshop": true,
      "history": [
        {
          "title": "Diagnóstico de Falla Cilindro 3",
          "date": "17 Ene 2026",
          "status": "En Proceso",
          "isCompleted": false,
          "warranty": "Pendiente", 
          "daysLeft": "-",
          "elapsed": "En curso",
          "complaint": "El cliente reporta tembladera en mínimo y pérdida de potencia al acelerar a fondo.",
          "diagnosis": "Se detectó código P0303. La bobina del cilindro 3 tiene resistencia infinita (quemada) y la bujía está carbonizada.",
          "videoReception": "https://www.youtube.com/watch?v=wblL1YIDu-A", 
          "videoRepair": "https://www.youtube.com/watch?v=YuUtjWC2y0s", 
          "budget": [
            {"item": "Bobina AC Delco Original", "price": 45.00},
            {"item": "Bujía Iridium (x1)", "price": 12.00},
            {"item": "Mano de Obra Diagnóstico", "price": 30.00},
            {"item": "Mano de Obra Reemplazo", "price": 15.00},
          ]
        },
        {
          "title": "Cambio de Aceite y Filtro",
          "date": "10 Dic 2025",
          "status": "Finalizado",
          "isCompleted": true,
          "warranty": "3 Meses",
          "daysLeft": "54 Días",
          "elapsed": "1 Mes y 7 días",
          "complaint": "Mantenimiento programado por kilometraje.",
          "diagnosis": "Niveles de fluidos bajos, aceite degradado.",
          "videoReception": "https://www.youtube.com/watch?v=wblL1YIDu-A",
          "videoRepair": "https://www.youtube.com/watch?v=YuUtjWC2y0s",
          "budget": [
            {"item": "Aceite 5W30 Dexos (5L)", "price": 60.00},
            {"item": "Filtro de Aceite", "price": 8.00},
            {"item": "Servicio de Cambio", "price": 15.00},
          ]
        },
      ]
    },
    {
      "brand": "CHEVROLET",
      "model": "TAHOE",
      "year": "2015",
      "plate": "999 VRT",
      "color": "NEGRO",
      "km": "120.500",
      "isInWorkshop": false,
      "history": [
        {
          "title": "Reemplazo de Pastillas de Freno",
          "date": "05 Nov 2025",
          "status": "Finalizado",
          "isCompleted": true,
          "warranty": "6 Meses",
          "daysLeft": "110 Días",
          "elapsed": "2 Meses",
          "complaint": "Ruido metálico al frenar.",
          "diagnosis": "Pastillas delanteras al 10% de vida. Discos requieren rectificación.",
          "videoReception": "https://www.youtube.com/watch?v=3XoBQPC-1vM",
          "videoRepair": "https://www.youtube.com/watch?v=3XoBQPC-1vM",
          "budget": [
            {"item": "Juego Pastillas Delanteras", "price": 55.00},
            {"item": "Rectificación Discos (x2)", "price": 40.00},
            {"item": "Mano de Obra", "price": 35.00},
          ]
        },
      ]
    },
  ];

  int _currentPage = 0; 

  @override
  Widget build(BuildContext context) {
    const Color brandRed = Color(0xFFD50000);
    final currentHistory = myVehicles.isNotEmpty 
        ? (myVehicles[_currentPage]['history'] as List<Map<String, dynamic>>)
        : <Map<String, dynamic>>[];

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'MI GARAJE', 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            letterSpacing: 3.0,
            fontSize: 18,
            color: Colors.white
          )
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white), 
            onPressed: () {}
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [Color(0xFF252525), Colors.black],
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 100), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 110,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      _buildSliderItem(context, Icons.calendar_month, "CITAS", brandRed, 
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AppointmentsScreen()))
                      ),
                      _buildSliderItem(context, Icons.notifications, "NOTIFIC.", Colors.amber), 
                      _buildSliderItem(context, Icons.monitor_heart, "DIAGNÓSTICO", Colors.white, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const DiagnosticScreen()))),
                      _buildSliderItem(context, Icons.storefront, "TIENDA", brandRed),
                      _buildSliderItem(context, Icons.local_offer, "OFERTAS", Colors.green),
                      _buildSliderItem(context, Icons.sell, "MARKET", brandRed),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("VEHÍCULO ACTIVO", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 2.5, fontWeight: FontWeight.bold)),
                      Text("${_currentPage + 1}/${myVehicles.length}", style: TextStyle(color: Colors.grey[600], fontSize: 10))
                    ],
                  ),
                ),
                SizedBox(
                  height: 220, 
                  child: PageView.builder(
                    itemCount: myVehicles.length,
                    onPageChanged: (int index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildVehicleCard(myVehicles[index]),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(myVehicles.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 5,
                      width: _currentPage == index ? 20 : 5,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? brandRed : Colors.grey[800],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 30),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: Text("HISTORIAL DE SERVICIOS", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 2.5, fontWeight: FontWeight.bold)),
                ),
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(), 
                  itemCount: currentHistory.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryCard(context, currentHistory[index]);
                  },
                ),
                const SizedBox(height: 50), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> historyItem) {
    bool isCompleted = historyItem['isCompleted'];
    Color statusColor = isCompleted ? Colors.green : const Color(0xFFD50000);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RepairDetailScreen(historyItem: historyItem),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), 
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ]
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.timelapse,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        historyItem['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        historyItem['date'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 12),
              ],
            ),
            if (isCompleted) ...[
              const SizedBox(height: 15),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHistoryStat(Icons.verified_user_outlined, "Garantía", historyItem['warranty']),
                  _buildHistoryStat(Icons.hourglass_bottom, "Restan", historyItem['daysLeft'], isHighlighted: true),
                  _buildHistoryStat(Icons.history, "Pasado", historyItem['elapsed']),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryStat(IconData icon, String label, String value, {bool isHighlighted = false}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value, 
          style: TextStyle(
            color: isHighlighted ? Colors.greenAccent : Colors.white, 
            fontSize: 11, 
            fontWeight: FontWeight.bold
          )
        ),
      ],
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicleData) {
    bool isInWorkshop = vehicleData['isInWorkshop'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15), 
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05), 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1), 
          width: 1
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD50000).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_car, color: Color(0xFFD50000), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicleData['brand'], style: const TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(vehicleData['model'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white, letterSpacing: 0.5)),
                    Text(vehicleData['year'], style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),
              if (isInWorkshop)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFD50000)),
                  ),
                  child: const Text("EN TALLER", style: TextStyle(color: Color(0xFFD50000), fontWeight: FontWeight.bold, fontSize: 8, letterSpacing: 0.5)),
                ),
            ],
          ),
          const Spacer(),
          const Divider(color: Colors.white10, height: 1),
          const Spacer(), 
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTechInfo("PLACA", vehicleData['plate']),
              Container(width: 1, height: 25, color: Colors.white10),
              _buildTechInfo("COLOR", vehicleData['color']),
              Container(width: 1, height: 25, color: Colors.white10),
              _buildTechInfo("KM", vehicleData['km']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 8, letterSpacing: 1.0)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildSliderItem(BuildContext context, IconData icon, String label, Color iconColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF2C2C2C), Colors.black.withValues(alpha: 0.8)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 5))]
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.0))
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20),
            decoration: const BoxDecoration(color: Color(0xFF111111)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(backgroundColor: Color(0xFFD50000), radius: 30, child: Icon(Icons.person, color: Colors.white, size: 30)),
                SizedBox(height: 15),
                Text("MVTSOLUCIONES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                Text("Usuario Premium", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          _buildDrawerItem(Icons.settings, "CONFIGURACIÓN"),
          _buildDrawerItem(Icons.logout, "CERRAR SESIÓN"),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title) {
    return ListTile(leading: Icon(icon, color: Colors.white), title: Text(title, style: const TextStyle(color: Colors.white, letterSpacing: 1)), onTap: () {});
  }
}

class RepairDetailScreen extends StatelessWidget {
  final Map<String, dynamic> historyItem;

  const RepairDetailScreen({super.key, required this.historyItem});

  @override
  Widget build(BuildContext context) {
    bool isCompleted = historyItem['isCompleted'];
    Color statusColor = isCompleted ? Colors.green : const Color(0xFFD50000);
    List budgetList = historyItem['budget'] ?? [];
    double totalBudget = budgetList.fold(0, (sum, item) => sum + (item['price'] as double));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("INFORME DE SERVICIO", style: TextStyle(fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [Color(0xFF252525), Colors.black],
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(25, 120, 25, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    historyItem['status'].toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  historyItem['title'],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
                ),
                const SizedBox(height: 10),
                Text(historyItem['date'], style: const TextStyle(color: Colors.grey, fontSize: 14)),
                
                const SizedBox(height: 40),
                
                _buildSectionTitle("REPORTE TÉCNICO"),
                const SizedBox(height: 15),
                _buildInfoBlock("Falla Reportada", historyItem['complaint']),
                const SizedBox(height: 10),
                _buildInfoBlock("Diagnóstico Técnico", historyItem['diagnosis']),

                const SizedBox(height: 30),

                _buildSectionTitle("EVIDENCIA MULTIMEDIA"),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildVideoCard(
                      context, 
                      "Recepción", 
                      historyItem['videoReception'], 
                      title: "Recepción: ${historyItem['title']}",
                      desc: historyItem['complaint']
                    )),
                    const SizedBox(width: 15),
                    Expanded(child: _buildVideoCard(
                      context, 
                      "Reparación", 
                      historyItem['videoRepair'],
                      title: "Reparación: ${historyItem['title']}",
                      desc: historyItem['diagnosis']
                    )),
                  ],
                ),

                const SizedBox(height: 30),

                _buildSectionTitle("PRESUPUESTO APROBADO"),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      ...budgetList.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(item['item'], style: const TextStyle(color: Colors.white70, fontSize: 13))),
                            Text("\$${item['price'].toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("TOTAL", style: TextStyle(color: Color(0xFFD50000), fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("\$${totalBudget.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFD50000), fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 50),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title, 
      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)
    );
  }

  Widget _buildInfoBlock(String label, String? content) {
    const double fontSize = 16;
    const FontWeight fontWeight = FontWeight.bold;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 2.0
                    ..color = Colors.black,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  color: Color(0xFFD50000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(content ?? "Pendiente...", style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, String label, String? videoUrl, {required String title, required String? desc}) {
    bool hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    String? thumbnailUrl;

    if (hasVideo) {
      String? videoId = YoutubePlayer.convertUrlToId(videoUrl!); // Sin '!'
      if (videoId != null) {
        thumbnailUrl = "https://img.youtube.com/vi/$videoId/mqdefault.jpg";
      }
    }

    return GestureDetector(
      onTap: () {
        if (hasVideo) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InAppVideoPlayerScreen(
                videoUrl: videoUrl!, // Sin '!' (o con '!' si Dart lo pide, pero si sale warning se quita)
                // En este caso Dart se quejaba del !, así que lo quitamos arriba. 
                // Pero ojo: aquí SÍ necesitamos el ! si 'videoUrl' es String?. 
                // El warning decía que el receiver NO es null. Eso significa que Dart ya sabe que es String.
                // Así que lo dejamos como `videoUrl` a secas.
                
                videoTitle: title,
                videoDescription: desc ?? "Sin detalles adicionales.",
              ),
            ),
          );
        } else {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No hay video disponible"))
            );
        }
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: hasVideo ? Colors.white24 : Colors.white10),
          image: thumbnailUrl != null 
            ? DecorationImage(
                image: NetworkImage(thumbnailUrl!), 
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken)
              ) 
            : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.play_circle_fill, 
              color: hasVideo ? const Color(0xFFD50000) : Colors.grey.withValues(alpha: 0.3), 
              size: 40
            ),
            Positioned(
              bottom: 10,
              child: Text(
                label, 
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)]
                )
              ),
            )
          ],
        ),
      ),
    );
  }
}

class InAppVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final String videoDescription;

  const InAppVideoPlayerScreen({
    super.key, 
    required this.videoUrl,
    required this.videoTitle,
    required this.videoDescription,
  });

  @override
  State<InAppVideoPlayerScreen> createState() => _InAppVideoPlayerScreenState();
}

class _InAppVideoPlayerScreenState extends State<InAppVideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Aquí también quitamos el ! si sale warning, pero YoutubePlayer.convertUrlToId espera String
    // Si widget.videoUrl ya es String (no nullable), no hace falta !
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? "",
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        forceHD: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openInYoutubeApp() async {
    final Uri uri = Uri.parse(widget.videoUrl);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
         // Verificamos si el contexto sigue vivo antes de usarlo (arregla el otro warning)
         if (!context.mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se pudo abrir YouTube")));
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFFD50000),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xFFD50000),
          handleColor: Color(0xFFD50000),
        ),
      ),
      builder: (context, player) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.3,
                colors: [Color(0xFF252525), Colors.black],
              ),
            ),
            child: Column(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Spacer(),
                        const Text("EVIDENCIA DIGITAL", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
                        const Spacer(),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: player,
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      border: const Border(top: BorderSide(color: Colors.white10))
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD50000),
                                  borderRadius: BorderRadius.circular(5)
                                ),
                                child: const Text("VIDEO TÉCNICO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.open_in_new, color: Colors.white70),
                                onPressed: _openInYoutubeApp,
                                tooltip: "Abrir en YouTube",
                              )
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            widget.videoTitle,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 15),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 15),
                          const Text("DETALLES DEL REGISTRO:", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(
                            widget.videoDescription,
                            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD50000),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                              ),
                              onPressed: _openInYoutubeApp, 
                              icon: const Icon(Icons.ondemand_video, color: Colors.white),
                              label: const Text("ABRIR EN APP DE YOUTUBE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}