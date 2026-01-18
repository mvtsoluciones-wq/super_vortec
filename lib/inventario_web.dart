import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InventarioWebModule extends StatefulWidget {
  const InventarioWebModule({super.key});

  @override
  State<InventarioWebModule> createState() => _InventarioWebModuleState();
}

class _InventarioWebModuleState extends State<InventarioWebModule> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // --- DATOS DE PRUEBA ---
  final List<Map<String, dynamic>> _repuestos = [
    {"sku": "V-001", "nombre": "Kit Tiempos 5.3", "stock": 8, "precio": 120.0},
    {"sku": "V-003", "nombre": "Bomba de Aceite Melling", "stock": 3, "precio": 180.0},
  ];

  final List<Map<String, dynamic>> _servicios = [
    {"id": "S-001", "nombre": "Cambio de Aceite", "precio": 25.0},
    {"id": "S-002", "nombre": "Ajuste de Tren Delantero", "precio": 60.0},
  ];

  final List<Map<String, String>> _proveedores = [
    {"empresa": "Distribuidora GM", "contacto": "Carlos", "tel": "0412-1112233", "rubro": "Motores"},
    {"empresa": "Frenos Altamira", "contacto": "Ventas", "tel": "0424-9998877", "rubro": "Frenos"},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Ahora son 3 pestañas
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          
          // SELECTOR DE PESTAÑAS
          Container(
            width: 600,
            decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(10)),
            child: TabBar(
              controller: _tabController,
              indicatorColor: brandRed,
              labelColor: brandRed,
              unselectedLabelColor: Colors.white24,
              tabs: const [
                Tab(text: "REPUESTOS", icon: Icon(Icons.settings_input_component, size: 18)),
                Tab(text: "SERVICIOS", icon: Icon(Icons.handyman_outlined, size: 18)),
                Tab(text: "AGENDA PROV.", icon: Icon(Icons.contact_phone_outlined, size: 18)),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTablaRepuestos(),
                _buildTablaServicios(),
                _buildAgendaContactos(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("GESTIÓN INTEGRAL DE ALMACÉN", 
          style: TextStyle(color: brandRed, fontWeight: FontWeight.w900, fontSize: 18)),
        const Text("Control de stock y directorio de proveedores", 
          style: TextStyle(color: Colors.white24, fontSize: 10)),
      ],
    );
  }

  // --- MÓDULO DE AGENDA (Nuevo) ---
  Widget _buildAgendaContactos() {
    return _containerBase(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("DIRECTORIO DE PROVEEDORES", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: const Text("NUEVO CONTACTO"),
                style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 2.5,
            ),
            itemCount: _proveedores.length,
            itemBuilder: (context, index) => _contactCard(_proveedores[index]),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(Map<String, String> prov) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: brandRed.withValues(alpha: 0.1), child: Icon(Icons.business, color: brandRed)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(prov['empresa']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(prov['rubro']!, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                const SizedBox(height: 5),
                Text(prov['tel']!, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone_in_talk, color: Colors.white24),
            onPressed: () async {
              final Uri tel = Uri.parse('tel:${prov['tel']}');
              if (await canLaunchUrl(tel)) await launchUrl(tel);
            },
          )
        ],
      ),
    );
  }

  // --- WIDGETS DE TABLAS (Se mantienen de la versión anterior) ---
  Widget _buildTablaRepuestos() {
    return _containerBase(
      DataTable(
        columns: const [
          DataColumn(label: Text("SKU", style: TextStyle(color: Colors.white38))),
          DataColumn(label: Text("REPUESTO", style: TextStyle(color: Colors.white38))),
          DataColumn(label: Text("STOCK", style: TextStyle(color: Colors.white38))),
          DataColumn(label: Text("PRECIO", style: TextStyle(color: Colors.white38))),
        ],
        rows: _repuestos.map((item) => DataRow(cells: [
          DataCell(Text(item['sku'], style: const TextStyle(color: Colors.white54))),
          DataCell(Text(item['nombre'], style: const TextStyle(color: Colors.white))),
          DataCell(Text("${item['stock']}", style: TextStyle(color: item['stock'] < 5 ? Colors.orange : Colors.green))),
          DataCell(Text("\$${item['precio']}", style: const TextStyle(color: Colors.white))),
        ])).toList(),
      )
    );
  }

  Widget _buildTablaServicios() {
    return _containerBase(
      DataTable(
        columns: const [
          DataColumn(label: Text("ID", style: TextStyle(color: Colors.white38))),
          DataColumn(label: Text("SERVICIO", style: TextStyle(color: Colors.white38))),
          DataColumn(label: Text("TARIFA", style: TextStyle(color: Colors.white38))),
        ],
        rows: _servicios.map((item) => DataRow(cells: [
          DataCell(Text(item['id'], style: const TextStyle(color: Colors.white54))),
          DataCell(Text(item['nombre'], style: const TextStyle(color: Colors.white))),
          DataCell(Text("\$${item['precio']}", style: TextStyle(color: brandRed, fontWeight: FontWeight.bold))),
        ])).toList(),
      )
    );
  }

  Widget _containerBase(Widget child) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: SingleChildScrollView(child: child),
    );
  }
}