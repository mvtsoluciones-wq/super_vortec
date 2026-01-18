import 'package:flutter/material.dart';

class SeguimientoWebModule extends StatefulWidget {
  const SeguimientoWebModule({super.key});

  @override
  State<SeguimientoWebModule> createState() => _SeguimientoWebModuleState();
}

class _SeguimientoWebModuleState extends State<SeguimientoWebModule> {
  // --- VARIABLES DINÁMICAS (Ya no darán advertencia de 'final') ---
  double _progreso = 0.1; 
  String _estadoActual = "RECEPCIÓN";
  
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // Lista de estados para la lógica de la barra
  final List<Map<String, dynamic>> _estados = [
    {"label": "RECEPCIÓN", "icon": Icons.assignment_turned_in, "val": 0.1},
    {"label": "DIAGNÓSTICO", "icon": Icons.search, "val": 0.3},
    {"label": "REPARACIÓN", "icon": Icons.build, "val": 0.6},
    {"label": "PRUEBAS", "icon": Icons.speed, "val": 0.8},
    {"label": "LISTO", "icon": Icons.check_circle, "val": 1.0},
  ];

  // Función para actualizar el estado y el progreso
  void _cambiarEstado(String nuevoEstado, double nuevoProgreso) {
    setState(() {
      _estadoActual = nuevoEstado;
      _progreso = nuevoProgreso;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          _buildControlButtons(), // Panel para interactuar con el estado
          const SizedBox(height: 30),
          _buildProgressVisualizer(), // Barra de progreso y pasos
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
            Text("FLUJO DE TRABAJO", style: TextStyle(color: brandRed, fontWeight: FontWeight.w900, fontSize: 18)),
            const Text("Actualiza el avance del vehículo para el cliente", style: TextStyle(color: Colors.white24, fontSize: 10)),
          ],
        ),
        _statusBadge(),
      ],
    );
  }

  Widget _statusBadge() {
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

  Widget _buildControlButtons() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _estados.map((e) {
        bool isActive = _estadoActual == e['label'];
        return ElevatedButton.icon(
          onPressed: () => _cambiarEstado(e['label'], e['val']),
          icon: Icon(e['icon'], size: 16),
          label: Text(e['label']),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? brandRed : inputFill,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressVisualizer() {
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
              bool isFinished = _progreso >= e['val'];
              return Column(
                children: [
                  Icon(e['icon'], color: isFinished ? brandRed : Colors.white10, size: 30),
                  const SizedBox(height: 8),
                  Text(e['label'], style: TextStyle(color: isFinished ? Colors.white : Colors.white10, fontSize: 10, fontWeight: FontWeight.bold)),
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
}