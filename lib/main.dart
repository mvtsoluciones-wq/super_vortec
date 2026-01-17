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
  // DATOS ENRIQUECIDOS CON HISTORIAL
  final List<Map<String, dynamic>> myVehicles = [
    {
      "brand": "CHEVROLET",
      "model": "SILVERADO",
      "year": "2008",
      "plate": "123 ASD",
      "color": "AZUL",
      "km": "250.000",
      "isInWorkshop": true,
      // HISTORIAL DE LA SILVERADO
      "history": [
        {
          "title": "Diagnóstico de Falla Cilindro 3",
          "date": "17 Ene 2026",
          "status": "En Proceso",
          "isCompleted": false,
        },
        {
          "title": "Cambio de Aceite y Filtro",
          "date": "10 Dic 2025",
          "status": "Finalizado",
          "isCompleted": true,
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
      // HISTORIAL DE LA TAHOE
      "history": [
        {
          "title": "Reemplazo de Pastillas de Freno",
          "date": "05 Nov 2025",
          "status": "Finalizado",
          "isCompleted": true,
        },
      ]
    },
  ];

  int _currentPage = 0; 

  @override
  Widget build(BuildContext context) {
    const Color brandRed = Color(0xFFD50000);
    // Obtenemos el historial del vehículo actual
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
      body: Container(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 100), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. MENÚ SUPERIOR
              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    _buildSliderItem(Icons.calendar_month, "CITAS", brandRed),
                    _buildSliderItem(Icons.monitor_heart, "DIAGNÓSTICO", Colors.white),
                    _buildSliderItem(Icons.storefront, "TIENDA", brandRed),
                    _buildSliderItem(Icons.local_offer, "OFERTAS", Colors.green),
                    _buildSliderItem(Icons.sell, "MARKET", brandRed),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. TÍTULO E INDICADOR
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

              // 3. SLIDER DE VEHÍCULOS
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

              // 4. INDICADORES
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

              // 5. SECCIÓN DE HISTORIAL DINÁMICO
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

              // LISTA DE HISTORIAL (Se construye según el vehículo seleccionado)
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shrinkWrap: true, // Importante para que funcione dentro del SingleChildScrollView
                physics: const NeverScrollableScrollPhysics(), // Evita conflicto de scroll
                itemCount: currentHistory.length,
                itemBuilder: (context, index) {
                  return _buildHistoryCard(currentHistory[index]);
                },
              ),

              const SizedBox(height: 50), // Espacio final
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET: TARJETA DE HISTORIAL INDIVIDUAL ---
  Widget _buildHistoryCard(Map<String, dynamic> historyItem) {
    bool isCompleted = historyItem['isCompleted'];
    Color statusColor = isCompleted ? Colors.green : const Color(0xFFD50000);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Fondo gris oscuro sólido para diferenciar
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Icono de estado
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
          // Textos
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
          // Badge de estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              historyItem['status'],
              style: TextStyle(
                color: statusColor,
                fontSize: 9,
                fontWeight: FontWeight.bold
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET: TARJETA DE VEHÍCULO ---
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

  // --- WIDGETS AUXILIARES ---
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