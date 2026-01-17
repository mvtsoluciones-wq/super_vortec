import 'package:flutter/material.dart';

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
        primaryColor: const Color(0xFFD50000), // Rojo Intenso
        scaffoldBackgroundColor: Colors.black, // Negro Puro de base
        useMaterial3: true,
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
          "description": "El vehículo presenta inestabilidad en ralentí (misfire). Se procede a escanear y verificar bobinas y bujías del banco 1.",
        },
        {
          "title": "Cambio de Aceite y Filtro",
          "date": "10 Dic 2025",
          "status": "Finalizado",
          "isCompleted": true,
          "warranty": "3 Meses",
          "daysLeft": "54 Días",
          "elapsed": "1 Mes y 7 días",
          "description": "Mantenimiento preventivo completo. Se utilizó aceite sintético 5W-30 Dexos y filtro original AC Delco.",
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
          "description": "Se reemplazaron pastillas delanteras y traseras por desgaste excesivo. Se rectificaron discos de freno.",
        },
      ]
    },
  ];

  int _currentPage = 0; 

  @override
  Widget build(BuildContext context) {
    const Color brandRed = Color(0xFFD50000);
    final currentHistory = myVehicles[_currentPage]['history'] as List<Map<String, dynamic>>;

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
          // 1. EL FONDO
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  Color(0xFF252525),
                  Colors.black,
                ],
              ),
            ),
          ),
          
          // 2. EL CONTENIDO
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 100), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MENÚ SUPERIOR (SLIDER)
                SizedBox(
                  height: 110,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      _buildSliderItem(Icons.calendar_month, "CITAS", brandRed),
                      _buildSliderItem(Icons.notifications, "NOTIFIC.", Colors.amber), 
                      _buildSliderItem(Icons.monitor_heart, "DIAGNÓSTICO", Colors.white),
                      _buildSliderItem(Icons.storefront, "TIENDA", brandRed),
                      _buildSliderItem(Icons.local_offer, "OFERTAS", Colors.green),
                      _buildSliderItem(Icons.sell, "MARKET", brandRed),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // TÍTULO E INDICADOR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "VEHÍCULO ACTIVO", 
                        style: TextStyle(
                          color: Colors.grey, 
                          fontSize: 10, 
                          letterSpacing: 2.5, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                      Text(
                        "${_currentPage + 1}/${myVehicles.length}", 
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      )
                    ],
                  ),
                ),

                // SLIDER DE VEHÍCULOS
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

                // INDICADORES
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

                // SECCIÓN DE HISTORIAL
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: Text(
                    "HISTORIAL DE SERVICIOS", 
                    style: TextStyle(
                      color: Colors.grey, 
                      fontSize: 10, 
                      letterSpacing: 2.5, 
                      fontWeight: FontWeight.bold
                    )
                  ),
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

  // --- WIDGETS AUXILIARES ---
  
  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> historyItem) {
    bool isCompleted = historyItem['isCompleted'];
    Color statusColor = isCompleted ? Colors.green : const Color(0xFFD50000);

    return GestureDetector(
      // NAVEGACIÓN A LA NUEVA PANTALLA
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
                // Icono de flecha para indicar que se puede hacer click
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
                    Text(
                      vehicleData['brand'], 
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14, 
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold
                      )
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicleData['model'], 
                      style: const TextStyle(
                        fontWeight: FontWeight.w800, 
                        fontSize: 20, 
                        color: Colors.white,
                        letterSpacing: 0.5
                      )
                    ),
                    Text(
                      vehicleData['year'], 
                      style: const TextStyle(
                        color: Colors.grey, 
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5
                      )
                    ),
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
                  child: const Text(
                    "EN TALLER", 
                    style: TextStyle(
                      color: Color(0xFFD50000), 
                      fontWeight: FontWeight.bold, 
                      fontSize: 8,
                      letterSpacing: 0.5
                    )
                  ),
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

  Widget _buildSliderItem(IconData icon, String label, Color iconColor) {
    return Container(
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

// --- NUEVA PANTALLA DE DETALLES ---
class RepairDetailScreen extends StatelessWidget {
  final Map<String, dynamic> historyItem;

  const RepairDetailScreen({super.key, required this.historyItem});

  @override
  Widget build(BuildContext context) {
    bool isCompleted = historyItem['isCompleted'];
    Color statusColor = isCompleted ? Colors.green : const Color(0xFFD50000);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("DETALLES DE SERVICIO", style: TextStyle(fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // FONDO COMPARTIDO
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
                // ESTADO
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
                // TÍTULO GRANDE
                Text(
                  historyItem['title'],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey, size: 14),
                    const SizedBox(width: 8),
                    Text(historyItem['date'], style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 40),
                
                // DESCRIPCIÓN TÉCNICA
                const Text("INFORME TÉCNICO", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    historyItem['description'] ?? "No hay descripción disponible.",
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                  ),
                ),

                if (isCompleted) ...[
                  const SizedBox(height: 40),
                  const Text("GARANTÍA Y TIEMPOS", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildDetailStat("GARANTÍA", historyItem['warranty'], Icons.verified_user)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildDetailStat("RESTANTE", historyItem['daysLeft'], Icons.hourglass_bottom, highlight: true)),
                    ],
                  ),
                ],

                const SizedBox(height: 50),
                // BOTÓN DE SOPORTE
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD50000),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.support_agent),
                    label: const Text("CONTACTAR SOPORTE"),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, IconData icon, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(color: highlight ? Colors.greenAccent : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}