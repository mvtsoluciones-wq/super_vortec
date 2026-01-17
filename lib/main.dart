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

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Definimos el ROJO DE LA MARCA
    const Color brandRed = Color(0xFFD50000);

    return Scaffold(
      // Extendemos el cuerpo detrás del AppBar para que el degradado cubra TODO
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparente para ver el fondo
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'MI GARAJE', 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            letterSpacing: 3.0, // Espaciado amplio estilo Premium
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
      // FONDO "SPOTLIGHT"
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3), // El centro de luz está un poco arriba
            radius: 1.2,
            colors: [
              Color(0xFF252525), // Centro: Gris Carbón (Luz)
              Colors.black,      // Bordes: Negro Profundo (Sombra)
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 100), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. MENÚ SUPERIOR (SLIDER)
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

              const SizedBox(height: 25),

              // 2. TARJETA DE CRISTAL
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                child: Text(
                  "VEHÍCULO ACTIVO", 
                  style: TextStyle(
                    color: Colors.grey, 
                    fontSize: 10, 
                    letterSpacing: 2.5, 
                    fontWeight: FontWeight.bold
                  )
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildGlassCard(),
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET: TARJETA CRISTAL AHUMADO ---
  Widget _buildGlassCard() {
    bool isInWorkshop = true; // Interruptor de estado

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20), 
      decoration: BoxDecoration(
        // Fondo semitransparente (Efecto Cristal)
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
          // FILA 1: Encabezado
          Row(
            children: [
              // Icono flotante
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD50000).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_car, color: Color(0xFFD50000), size: 24),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CHEVROLET SILVERADO", 
                      style: TextStyle(
                        fontWeight: FontWeight.w900, 
                        fontSize: 16, 
                        color: Colors.white,
                        letterSpacing: 1.0
                      )
                    ),
                    // AQUÍ ESTÁ EL CAMBIO: Solo muestra "2008"
                    Text(
                      "2008", 
                      style: TextStyle(
                        color: Colors.grey, 
                        fontSize: 12, // Un poco más grande para que destaque solo
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ],
                ),
              ),
              
              if (isInWorkshop)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      fontSize: 9,
                      letterSpacing: 1.0
                    )
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 20),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 20),

          // FILA 2: DATOS TÉCNICOS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTechInfo("PLACA", "123 ASD"),
              Container(width: 1, height: 30, color: Colors.white10),
              _buildTechInfo("COLOR", "AZUL"),
              Container(width: 1, height: 30, color: Colors.white10),
              _buildTechInfo("ODÓMETRO", "250.000"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label, 
          style: const TextStyle(
            color: Colors.grey, 
            fontSize: 9, 
            letterSpacing: 1.5
          )
        ),
        const SizedBox(height: 5),
        Text(
          value, 
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: 14,
            letterSpacing: 1.0
          )
        ),
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
                colors: [
                  const Color(0xFF2C2C2C),
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ]
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10, 
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0
            ),
          )
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
                CircleAvatar(
                  backgroundColor: Color(0xFFD50000),
                  radius: 30,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
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
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white, letterSpacing: 1)),
      onTap: () {},
    );
  }
}