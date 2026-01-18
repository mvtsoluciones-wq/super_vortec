import 'package:flutter/material.dart';

class AdminControlPanel extends StatefulWidget {
  const AdminControlPanel({super.key});

  @override
  State<AdminControlPanel> createState() => _AdminControlPanelState();
}

class _AdminControlPanelState extends State<AdminControlPanel> {
  int _activeTab = 0;
  final String _currentUserName = "MVT SOLUCIONES"; 

  // Colores de marca unificados
  final Color bgBlack = const Color(0xFF000000);
  final Color cardGrey = const Color(0xFF111111);
  final Color vorteRed = const Color(0xFFD50000);
  final Color successGreen = const Color(0xFF00C853);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    
    // BLOQUEO PARA PC (Ancho > 800)
    if (screenWidth < 800) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text("ACCESO SOLO DESDE PC", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: bgBlack,
      body: Row(
        children: [
          // 1. SIDEBAR CON LOGO EN LA PARTE SUPERIOR IZQUIERDA
          _buildSidebar(),

          // 2. ÁREA DE CONTENIDO
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  Expanded(
                    child: _buildCurrentModule(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET SIDEBAR ---
  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: cardGrey,
        // CORRECCIÓN: Uso de withValues para evitar deprecated_member_use
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Alinea todo a la izquierda
        children: [
          // LOGO SUPERIOR IZQUIERDO
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
            child: Container(
              height: 80,
              width: 150,
              alignment: Alignment.centerLeft, // Asegura posición a la izquierda
              child: Image.asset(
                'assets/Logo.jpg',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => 
                  Icon(Icons.broken_image, color: vorteRed.withValues(alpha: 0.5), size: 40),
              ),
            ),
          ),
          
          // INFO DE USUARIO DEBAJO DEL LOGO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUserName, 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)
                ),
                Text(
                  "ADMINISTRADOR", 
                  style: TextStyle(color: vorteRed, fontSize: 9, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          const Divider(color: Colors.white10, indent: 20, endIndent: 20),
          const SizedBox(height: 10),

          // ITEMS DEL MENÚ
          _sidebarItem(0, Icons.dashboard_customize, "VARIABLES APP"),
          _sidebarItem(1, Icons.people_alt, "CLIENTES & LOGIN"),
          _sidebarItem(2, Icons.car_repair, "RECEPCIÓN"),
          _sidebarItem(3, Icons.video_library, "MULTIMEDIA YOUTUBE"),
          _sidebarItem(4, Icons.settings, "CONFIG. SERVIDOR"),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    bool isSelected = _activeTab == index;
    return ListTile(
      onTap: () => setState(() => _activeTab = index),
      leading: Icon(icon, color: isSelected ? vorteRed : Colors.grey),
      title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
      selected: isSelected,
      // CORRECCIÓN: Uso de withValues
      selectedTileColor: vorteRed.withValues(alpha: 0.1),
    );
  }

  // --- HEADER PRINCIPAL ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("SISTEMA DE CONTROL CENTRAL", 
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
            Text("PROYECTO SUPER VORTEC 5.3 - ESTADO: OPERATIVO", 
              style: TextStyle(color: successGreen, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ],
        ),
        _buildStatTile("USUARIOS ACTIVOS", "128", successGreen),
      ],
    );
  }

  Widget _buildCurrentModule() {
    switch (_activeTab) {
      case 0: return _moduleVariables();
      default: return const Center(child: Text("MÓDULO EN CONSTRUCCIÓN", style: TextStyle(color: Colors.white24)));
    }
  }

  Widget _moduleVariables() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 1.8,
      children: [
        _variableEditor("ESTADO DE REPARACIÓN", "En Proceso", successGreen),
        _variableEditor("TIEMPO DE GARANTÍA", "3 Meses", vorteRed),
      ],
    );
  }

  Widget _variableEditor(String title, String currentVal, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(currentVal, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              // CORRECCIÓN: Uso de withValues
              backgroundColor: color.withValues(alpha: 0.2), 
              foregroundColor: color
            ),
            onPressed: () {}, 
            child: const Text("CAMBIAR VARIABLE")
          )
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: cardGrey, 
        border: Border.all(color: Colors.white10), 
        borderRadius: BorderRadius.circular(5)
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9)),
          Text(val, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}