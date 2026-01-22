import 'package:flutter/material.dart';

class InventarioWebModule extends StatefulWidget {
  const InventarioWebModule({super.key});

  @override
  State<InventarioWebModule> createState() => _InventarioWebModuleState();
}

class _InventarioWebModuleState extends State<InventarioWebModule> {
  // Estilo Super Vortec
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // --- CONTROLADORES PARA NUEVOS PRODUCTOS ---
  final TextEditingController _ctrlNombreProd = TextEditingController();
  final TextEditingController _ctrlPrecioProd = TextEditingController();
  final TextEditingController _ctrlStockProd = TextEditingController();

  // --- BASE DE DATOS DE INVENTARIO (Estado Local) ---
  final List<Map<String, dynamic>> _inventario = [
    {"nombre": "CÁMARA DOMO 1080P", "precio": 45.00, "stock": 25, "minimo": 5},
    {"nombre": "DVR 4 CANALES", "precio": 85.50, "stock": 4, "minimo": 5}, // Alerta
    {"nombre": "DISCO DURO 1TB", "precio": 60.00, "stock": 15, "minimo": 3},
    {"nombre": "MANTENIMIENTO CCTV", "precio": 240671.85, "stock": 999, "minimo": 0},
  ];

  void _agregarProducto() {
    if (_ctrlNombreProd.text.isEmpty) return;
    setState(() {
      _inventario.add({
        "nombre": _ctrlNombreProd.text.toUpperCase(),
        "precio": double.tryParse(_ctrlPrecioProd.text) ?? 0.0,
        "stock": int.tryParse(_ctrlStockProd.text) ?? 0,
        "minimo": 5,
      });
      _ctrlNombreProd.clear();
      _ctrlPrecioProd.clear();
      _ctrlStockProd.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResumenCards(),
          const SizedBox(height: 30),
          _buildFormularioNuevo(),
          const SizedBox(height: 30),
          _buildTablaInventario(),
        ],
      ),
    );
  }

  // --- WIDGETS DE LA INTERFAZ ---

  Widget _buildResumenCards() {
    int totalProds = _inventario.length;
    int bajoStock = _inventario.where((p) => p['stock'] <= p['minimo']).length;

    return Row(
      children: [
        _infoCard("PRODUCTOS TOTALES", totalProds.toString(), Icons.inventory_2),
        const SizedBox(width: 20),
        _infoCard("ALERTA STOCK BAJO", bajoStock.toString(), Icons.warning_amber_rounded, color: Colors.orange),
      ],
    );
  }

  Widget _infoCard(String title, String value, IconData icon, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
        child: Row(
          children: [
            Icon(icon, color: color ?? brandRed, size: 30),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioNuevo() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("REGISTRAR NUEVO PRODUCTO / ENTRADA", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(flex: 3, child: _inputField("Nombre del Producto", _ctrlNombreProd)),
              const SizedBox(width: 10),
              Expanded(flex: 1, child: _inputField("Precio \$", _ctrlPrecioProd)),
              const SizedBox(width: 10),
              Expanded(flex: 1, child: _inputField("Stock Inicial", _ctrlStockProd)),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _agregarProducto,
                style: ElevatedButton.styleFrom(backgroundColor: brandRed, minimumSize: const Size(60, 55)),
                child: const Icon(Icons.add, color: Colors.white),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTablaInventario() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("LISTADO DE EXISTENCIAS", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          DataTable(
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text("PRODUCTO", style: TextStyle(color: Colors.white38))),
              DataColumn(label: Text("STOCK", style: TextStyle(color: Colors.white38))),
              DataColumn(label: Text("PRECIO \$", style: TextStyle(color: Colors.white38))),
              DataColumn(label: Text("ESTADO", style: TextStyle(color: Colors.white38))),
            ],
            rows: _inventario.map((p) {
              bool bajoStock = p['stock'] <= p['minimo'];
              return DataRow(cells: [
                DataCell(Text(p['nombre'], style: const TextStyle(color: Colors.white, fontSize: 12))),
                DataCell(Text(p['stock'].toString(), style: const TextStyle(color: Colors.white))),
                DataCell(Text("\$${p['precio']}", style: const TextStyle(color: Colors.white))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bajoStock ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5)
                  ),
                  child: Text(bajoStock ? "RECOMPRAR" : "OK", style: TextStyle(color: bajoStock ? Colors.orange : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                )),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}