import 'package:flutter/material.dart';

class TiendaWebModule extends StatefulWidget {
  const TiendaWebModule({super.key});

  @override
  State<TiendaWebModule> createState() => _TiendaWebModuleState();
}

class _TiendaWebModuleState extends State<TiendaWebModule> {
  // Colores del ecosistema Super Vortec
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // Lista de publicaciones activas en la App
  final List<Map<String, dynamic>> _publicaciones = [
    {"id": "P001", "titulo": "Aceite Castrol 20W-50", "precio": 12.50, "estado": "Activo", "vistas": 145},
    {"id": "P002", "titulo": "Kit de Distribución Optra", "precio": 85.00, "estado": "Pausado", "vistas": 89},
    {"id": "P003", "titulo": "Limpiador de Inyectores", "precio": 8.00, "estado": "Activo", "vistas": 230},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- LADO IZQUIERDO: FORMULARIO DE NUEVA PUBLICACIÓN ---
          Expanded(
            flex: 2,
            child: _buildFormularioPublicacion(),
          ),
          const SizedBox(width: 30),
          
          // --- LADO DERECHO: LISTA DE CONTROL DE PUBLICACIONES ---
          Expanded(
            flex: 3,
            child: _buildListaPublicaciones(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioPublicacion() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("CREAR NUEVA PUBLICACIÓN", 
            style: TextStyle(color: brandRed, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 25),
          _buildInput("Título del Producto", Icons.shopping_bag_outlined),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildInput("Precio (\$)", Icons.attach_money)),
              const SizedBox(width: 15),
              Expanded(child: _buildInput("Categoría", Icons.category_outlined)),
            ],
          ),
          const SizedBox(height: 15),
          _buildInput("Descripción para la App", Icons.description_outlined, maxLines: 4),
          const SizedBox(height: 20),
          _buildUploadArea(),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white),
              onPressed: () {},
              child: const Text("SUBIR A LA APP", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: brandRed, size: 18),
            filled: true,
            fillColor: inputFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadArea() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload_outlined, color: Colors.white24),
          Text("Arrastra la imagen del producto aquí", style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildListaPublicaciones() {
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
          const Text("PUBLICACIONES EN VIVO", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildTablaControl(),
        ],
      ),
    );
  }

  Widget _buildTablaControl() {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.02)),
      columns: const [
        DataColumn(label: Text("PRODUCTO", style: TextStyle(color: Colors.white38, fontSize: 10))),
        DataColumn(label: Text("PRECIO", style: TextStyle(color: Colors.white38, fontSize: 10))),
        DataColumn(label: Text("ESTADO", style: TextStyle(color: Colors.white38, fontSize: 10))),
        DataColumn(label: Text("VISTAS", style: TextStyle(color: Colors.white38, fontSize: 10))),
        DataColumn(label: Text("ACCIONES", style: TextStyle(color: Colors.white38, fontSize: 10))),
      ],
      rows: _publicaciones.map((pub) {
        bool esActivo = pub['estado'] == "Activo";
        return DataRow(cells: [
          DataCell(Text(pub['titulo'], style: const TextStyle(color: Colors.white, fontSize: 12))),
          DataCell(Text("\$${pub['precio']}", style: const TextStyle(color: Colors.white70))),
          DataCell(Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: esActivo ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(pub['estado'], style: TextStyle(color: esActivo ? Colors.green : Colors.orange, fontSize: 10)),
          )),
          DataCell(Text("${pub['vistas']}", style: const TextStyle(color: Colors.white38))),
          DataCell(Row(
            children: [
              IconButton(icon: Icon(Icons.edit, size: 16, color: Colors.blue[300]), onPressed: () {}),
              IconButton(icon: Icon(esActivo ? Icons.pause : Icons.play_arrow, size: 16, color: Colors.white30), onPressed: () {}),
              IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red), onPressed: () {}),
            ],
          )),
        ]);
      }).toList(),
    );
  }
}