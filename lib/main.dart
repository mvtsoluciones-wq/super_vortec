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
    // Definimos el ROJO DE LA MARCA para usarlo fácil
    const Color brandRed = Color(0xFFD50000);

    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'MI GARAJE', 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            letterSpacing: 2.0,
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
                  _buildSliderItem(Icons.calendar_month, "Citas", brandRed),
                  _buildSliderItem(Icons.monitor_heart, "Diagnóstico", Colors.white),
                  _buildSliderItem(Icons.storefront, "Tienda", brandRed),
                  _buildSliderItem(Icons.local_offer, "Ofertas", Colors.green),
                  _buildSliderItem(Icons.sell, "Marketplace", brandRed),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. TARJETA COMPACTA
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text("TU VEHÍCULO", style: TextStyle(color: Colors.grey, fontSize: 14, letterSpacing: 1.5)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildDiagnosticCard(),
            ),
            
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

  // --- TARJETA COMPACTA CON LÓGICA CONDICIONAL ---
  Widget _buildDiagnosticCard() {
    // 💡 AQUÍ ESTÁ EL INTERRUPTOR
    // Cambia esto a 'false' para probar cómo se ve cuando NO está en el taller.
    bool isInWorkshop = true; 

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15), 
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3A3A3A), 
            Color(0xFF121212), 
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FILA 1: Encabezado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_car, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("CHEVROLET SILVERADO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    Text("Año 2008", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              
              // 🔽 CONDICIÓN: Solo mostramos este bloque si isInWorkshop es VERDADERO
              if (isInWorkshop)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD50000).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFFD50000).withValues(alpha: 0.5)),
                  ),
                  child: const Text("EN TALLER", style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold, fontSize: 9)),
                ),
            ],
          ),
          
          const SizedBox(height: 15),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 15),

          // FILA 2: DATOS TÉCNICOS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactInfo("PLACA", "123 ASD"),
              _buildCompactInfo("COLOR", "AZUL"),
              _buildCompactInfo("KM", "250.000"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
}