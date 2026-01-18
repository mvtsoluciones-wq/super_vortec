import 'package:flutter/material.dart';

class SeguimientoWebModule extends StatefulWidget {
  const SeguimientoWebModule({super.key});

  @override
  State<SeguimientoWebModule> createState() => _SeguimientoWebModuleState();
}

class _SeguimientoWebModuleState extends State<SeguimientoWebModule> {
  // --- VARIABLES DE ESTADO ---
  double _progreso = 0.2; // 0.0 a 1.0
  String _estadoActual = "RECEPCIÓN";
  
  // Colores corporativos
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // Lista de estados para el Stepper o Barra de progreso
  final List<Map<String, dynamic>> _estados = [
    {"label": "RECEPCIÓN", "icon": Icons.assignment_turned_in, "val": 0.1},
    {"label": "DIAGNÓSTICO", "icon": Icons.search, "val": 0.3},
    {"label": "REPARACIÓN", "icon": Icons.build, "val": 0.6},
    {"label": "PRUEBAS", "icon": Icons.speed, "val": 0.8},
    {"label": "LISTO", "icon": Icons.check_circle, "val": 1.0},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          _buildProgressCard(),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildEvidenciaFotos()),
              const SizedBox(width: 30),
              Expanded(flex: 1, child: _buildLogActividades()),
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
            Text("SEGUIMIENTO DE REPARACIÓN", style: TextStyle(color: brandRed, fontWeight: FontWeight.w900, fontSize: 18)),
            const Text("Control de flujo de trabajo en tiempo real", style: TextStyle(color: Colors.white24, fontSize: 10)),
          ],
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: brandRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: brandRed.withValues(alpha: 0.3)),
      ),
      child: Text(_estadoActual, style: TextStyle(color: brandRed, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _estados.map((e) {
              bool isDone = _progreso >= e['val'];
              return Column(
                children: [
                  Icon(e['icon'], color: isDone ? brandRed : Colors.white10, size: 30),
                  const SizedBox(height: 8),
                  Text(e['label'], style: TextStyle(color: isDone ? Colors.white : Colors.white10, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progreso,
              backgroundColor: inputFill,
              color: brandRed,
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenciaFotos() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("EVIDENCIA FOTOGRÁFICA", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_a_photo, size: 16),
                label: const Text("SUBIR FOTO"),
                style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Cuadrícula de fotos (Simulada)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: inputFill,
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: NetworkImage("https://via.placeholder.com/150"),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogActividades() {
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
          const Text("BITÁCORA", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _logItem("Vehículo ingresado al elevador", "10:30 AM"),
          _logItem("Desarmado de culata iniciado", "11:45 AM"),
          _logItem("Limpieza de inyectores completa", "02:15 PM"),
          const SizedBox(height: 20),
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: "Agregar comentario...",
              hintStyle: const TextStyle(color: Colors.white10),
              filled: true,
              fillColor: inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              suffixIcon: IconButton(icon: const Icon(Icons.send, color: Colors.red, size: 18), onPressed: () {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logItem(String texto, String hora) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: const TextStyle(color: Colors.white70, fontSize: 11))),
          Text(hora, style: const TextStyle(color: Colors.white10, fontSize: 10)),
        ],
      ),
    );
  }
}