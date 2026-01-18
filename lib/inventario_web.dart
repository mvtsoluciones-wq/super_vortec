import 'package:flutter/material.dart';

class InventarioWebModule extends StatefulWidget {
  const InventarioWebModule({super.key});

  @override
  State<InventarioWebModule> createState() => _InventarioWebModuleState();
}

class _InventarioWebModuleState extends State<InventarioWebModule> {
  // Colores corporativos
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // Datos de prueba: Inventario de repuestos
  final List<Map<String, dynamic>> _productos = [
    {"sku": "REP-001", "nombre": "Kit Distribución Optra", "stock": 5, "minimo": 3, "costo": 45.0, "venta": 85.0},
    {"sku": "REP-002", "nombre": "Pastillas Freno Tahoe", "stock": 2, "minimo": 5, "costo": 30.0, "venta": 65.0},
    {"sku": "REP-003", "nombre": "Filtro Aceite PH3387", "stock": 24, "minimo": 10, "costo": 3.5, "venta": 8.0},
    {"sku": "REP-004", "nombre": "Bomba Agua Silverado", "stock": 0, "minimo": 2, "costo": 40.0, "venta": 95.0},
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
          _buildQuickStats(),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FORMULARIO AGREGAR PRODUCTO
              Expanded(flex: 1, child: _buildAddProductForm()),
              const SizedBox(width: 30),
              // TABLA DE PRODUCTOS
              Expanded(flex: 2, child: _buildInventoryTable()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("GESTIÓN DE ALMACÉN", 
              style: TextStyle(color: brandRed, fontWeight: FontWeight.w900, fontSize: 18)),
            const Text("Control de existencias y precios de reposición", 
              style: TextStyle(color: Colors.white24, fontSize: 10)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download, size: 16),
          label: const Text("EXPORTAR EXCEL"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statCard("Total Items", "154", Icons.inventory_2),
        const SizedBox(width: 20),
        _statCard("Stock Crítico", "12", Icons.warning_amber_rounded, color: Colors.orange),
        const SizedBox(width: 20),
        _statCard("Valor Inventario", "\$4,250.00", Icons.account_balance_wallet, color: brandRed),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.blue, size: 28),
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
      ),
    );
  }

  Widget _buildAddProductForm() {
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
          const Text("NUEVO REGISTRO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildInput("Nombre del Repuesto", Icons.label_important_outline),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildInput("Costo", Icons.arrow_downward)),
              const SizedBox(width: 10),
              Expanded(child: _buildInput("Venta", Icons.arrow_upward)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildInput("Existencia", Icons.numbers)),
              const SizedBox(width: 10),
              Expanded(child: _buildInput("Mínimo", Icons.notifications_none)),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white),
              onPressed: () {},
              child: const Text("GUARDAR EN ALMACÉN"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextField(
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: brandRed, size: 16),
            filled: true,
            fillColor: inputFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryTable() {
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
          const Text("LISTADO DE EXISTENCIAS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          DataTable(
            columnSpacing: 20,
            headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.02)),
            columns: const [
              DataColumn(label: Text("SKU", style: TextStyle(color: Colors.white38, fontSize: 10))),
              DataColumn(label: Text("REPUESTO", style: TextStyle(color: Colors.white38, fontSize: 10))),
              DataColumn(label: Text("STOCK", style: TextStyle(color: Colors.white38, fontSize: 10))),
              DataColumn(label: Text("VENTA", style: TextStyle(color: Colors.white38, fontSize: 10))),
              DataColumn(label: Text("ACCIÓN", style: TextStyle(color: Colors.white38, fontSize: 10))),
            ],
            rows: _productos.map((p) {
              bool esCritico = p['stock'] <= p['minimo'];
              return DataRow(cells: [
                DataCell(Text(p['sku'], style: const TextStyle(color: Colors.white54, fontSize: 11))),
                DataCell(Text(p['nombre'], style: const TextStyle(color: Colors.white, fontSize: 12))),
                DataCell(_stockBadge(p['stock'], esCritico)),
                DataCell(Text("\$${p['venta']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                DataCell(Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.white24, size: 16), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16), onPressed: () {}),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _stockBadge(int stock, bool esCritico) {
    Color color = stock == 0 ? Colors.red : (esCritico ? Colors.orange : Colors.green);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
      child: Text("$stock", style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}