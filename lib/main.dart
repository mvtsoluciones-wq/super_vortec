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
      title: 'Super Vortec Clientes',
      theme: ThemeData(
        brightness: Brightness.dark,
        // PALETA DE COLORES: NEGRO, ROJO, BLANCO
        primaryColor: const Color(0xFFD50000), // Rojo Intenso
        scaffoldBackgroundColor: Colors.black, // Negro Puro
        canvasColor: Colors.black, // Para el Drawer
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.white),
        ),
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
    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'SUPER VORTEC', 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            letterSpacing: 2.0,
            color: Colors.white // Blanco
          )
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white), 
            onPressed: () {}
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // 1. MENÚ SUPERIOR (SLIDER)
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _buildSliderItem(Icons.calendar_month, "Citas", Colors.redAccent),
                  _buildSliderItem(Icons.monitor_heart, "Diagnóstico", Colors.white),
                  _buildSliderItem(Icons.storefront, "Tienda", Colors.white),
                  _buildSliderItem(Icons.local_offer, "Ofertas", Colors.redAccent),
                  _buildSliderItem(Icons.sell, "Marketplace", Colors.white),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. DIAGNÓSTICO
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text("TU VEHÍCULO", style: TextStyle(color: Colors.grey, fontSize: 14, letterSpacing: 1.5)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildDiagnosticCard(),
            ),

            const SizedBox(height: 30),

            // 3. OFERTAS
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text("DESTACADO", style: TextStyle(color: Colors.grey, fontSize: 14, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 10),
            _buildOfferBanner(),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20),
            decoration: const BoxDecoration(color: Color(0xFFD50000)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black,
                  radius: 30,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                SizedBox(height: 15),
                Text("MVTSOLUCIONES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Text("Silverado 5.3L", style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          _buildDrawerItem(Icons.calendar_today, "Citas"),
          _buildDrawerItem(Icons.monitor_heart, "Diagnóstico"),
          const Divider(color: Colors.white24),
          _buildDrawerItem(Icons.store, "Tienda"),
          _buildDrawerItem(Icons.percent, "Ofertas"),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {},
    );
  }

  Widget _buildDiagnosticCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFD50000), width: 1),
        boxShadow: [
          // CORRECCIÓN AQUÍ: Usamos .withValues(alpha: 0.1) en lugar de .withOpacity(0.1)
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.1), 
            blurRadius: 15, 
            spreadRadius: 1
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.directions_car, color: Colors.white, size: 30),
              Text("EN TALLER", style: TextStyle(color: Color(0xFFD50000), fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 15),
          const Text("Silverado 2008", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text("Diagnóstico de falla Cilindro 3", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: 0.5, 
            backgroundColor: Colors.grey[900],
            color: const Color(0xFFD50000),
            minHeight: 4,
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerRight,
            child: Text("50% Completado", style: TextStyle(color: Colors.white, fontSize: 12)),
          )
        ],
      ),
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
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.white),
          )
        ],
      ),
    );
  }

  Widget _buildOfferBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFD50000),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: Colors.black,
                    child: const Text("OFERTA FLASH", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  const Text("KIT VORTEC", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                  const Text("Bobinas + Bujías", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black12,
              child: const Center(
                child: Icon(Icons.flash_on, color: Colors.white, size: 60),
              ),
            ),
          )
        ],
      ),
    );
  }
}