import 'package:flutter/material.dart';

class MarketWebModule extends StatefulWidget {
  const MarketWebModule({super.key});

  @override
  State<MarketWebModule> createState() => _MarketWebModuleState();
}

class _MarketWebModuleState extends State<MarketWebModule> {
  // Colores corporativos
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // Lista simulada de publicaciones de terceros en el Market
  final List<Map<String, dynamic>> _publicacionesMarket = [
    {
      "vendedor": "Repuestos El Chamo",
      "producto": "Motor 5.3 Vortec Usado",
      "precio": 1200.0,
      "estado": "Pendiente",
      "fecha": "2026-01-15"
    },
    {
      "vendedor": "Distribuidora Norte",
      "producto": "Lote Bujías NGK (50 unid)",
      "precio": 150.0,
      "estado": "Aprobado",
      "fecha": "2026-01-18"
    },
    {
      "vendedor": "Pedro Mecánico",
      "producto": "Escáner Launch X431",
      "precio": 450.0,
      "estado": "Aprobado",
      "fecha": "2026-01-10"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PANEL DE ESTADÍSTICAS RÁPIDAS
              Expanded(flex: 1, child: _buildStatPanel()),
              const SizedBox(width: 30),
              // TABLA DE MODERACIÓN
              Expanded(flex: 3, child: _buildModerationTable()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("ADMINISTRACIÓN DEL MARKETPLACE", 
          style: TextStyle(color: brandRed, fontWeight: FontWeight.w900, fontSize: 18)),
        const Text("Modera y controla las publicaciones de terceros en la App", 
          style: TextStyle(color: Colors.white24, fontSize: 10)),
      ],
    );
  }

  Widget _buildStatPanel() {
    return Column(
      children: [
        _statCard("Total Publicaciones", "1,240", Icons.storefront),
        const SizedBox(height: 15),
        _statCard("Por Aprobar", "12", Icons.pending_actions, color: Colors.orange),
        const SizedBox(height: 15),
        _statCard("Reportes/Denuncias", "2", Icons.report_problem, color: brandRed),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.blue, size: 24),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildModerationTable() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SOLICITUDES DE PUBLICACIÓN", 
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildDataTable(),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.02)),
      columns: const [
        DataColumn(label: Text("VENDEDOR", style: TextStyle(color: Colors.white38, fontSize: 10))),
        DataColumn(label: Text("PRODUCTO", style: TextStyle(color: Colors.white38, fontSize: 10))),
        DataColumn(label: Text("PRECIO", style: TextStyle(color: Colors.white38, fontSize: 10))),
        DataColumn(label: Text("ESTADO", style: TextStyle(color: Colors.white38, fontSize: 10))),
        DataColumn(label: Text("ACCIONES", style: TextStyle(color: Colors.white38, fontSize: 10))),
      ],
      rows: _publicacionesMarket.map((pub) {
        bool esPendiente = pub['estado'] == "Pendiente";
        return DataRow(cells: [
          DataCell(Text(pub['vendedor'], style: const TextStyle(color: Colors.white, fontSize: 12))),
          DataCell(Text(pub['producto'], style: const TextStyle(color: Colors.white70, fontSize: 12))),
          DataCell(Text("\$${pub['precio']}", style: const TextStyle(color: Colors.white70))),
          DataCell(_statusBadge(pub['estado'])),
          DataCell(Row(
            children: [
              if (esPendiente)
                IconButton(icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 18), onPressed: () {}),
              IconButton(icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.blue, size: 18), onPressed: () {}),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), onPressed: () {}),
            ],
          )),
        ]);
      }).toList(),
    );
  }

  Widget _statusBadge(String status) {
    Color c = status == "Aprobado" ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
      child: Text(status, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}