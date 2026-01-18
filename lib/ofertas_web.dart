import 'package:flutter/material.dart';

class OfertasWebModule extends StatefulWidget {
  const OfertasWebModule({super.key});

  @override
  State<OfertasWebModule> createState() => _OfertasWebModuleState();
}

class _OfertasWebModuleState extends State<OfertasWebModule> {
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  final List<Map<String, dynamic>> _ofertas = [
    {
      "titulo": "SUPER COMBO TUNING", 
      "descripcion": "Limpieza de inyectores + Escaneo gratis", 
      "descuento": "15%", 
      "expira": "2026-02-01",
      "clicks": 452,
      "color": Colors.orangeAccent
    },
    {
      "titulo": "BLACK FRIDAY VORTEC", 
      "descripcion": "Todo en frenos a mitad de precio", 
      "descuento": "50%", 
      "expira": "2026-01-30",
      "clicks": 1205,
      "color": Colors.purpleAccent
    },
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildFormularioOferta()),
              const SizedBox(width: 30),
              Expanded(flex: 3, child: _buildListaOfertas()),
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
        Text("GESTIÓN DE OFERTAS Y PROMOS", 
          style: TextStyle(color: brandRed, fontWeight: FontWeight.w900, fontSize: 18)),
        const Text("Configura los banners y descuentos que aparecen al abrir la App", 
          style: TextStyle(color: Colors.white24, fontSize: 10)),
      ],
    );
  }

  Widget _buildFormularioOferta() {
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
          Text("NUEVA PROMOCIÓN", style: TextStyle(color: brandRed, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 25),
          _buildInput("Nombre de la Promo", Icons.campaign_outlined),
          const SizedBox(height: 15),
          _buildInput("Descripción Corta", Icons.short_text),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildInput("% Descuento", Icons.percent)),
              const SizedBox(width: 15),
              Expanded(child: _buildInput("Vence el", Icons.calendar_today_outlined)),
            ],
          ),
          const SizedBox(height: 20),
          _buildColorSelector(),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white),
              onPressed: () {},
              child: const Text("LANZAR OFERTA A LA APP", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, IconData icon) {
    return TextField(
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: brandRed, size: 18),
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildColorSelector() {
    return Row(
      children: [
        const Text("Color del Banner:", style: TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(width: 10),
        _colorDot(Colors.red),
        _colorDot(Colors.orange),
        _colorDot(Colors.purple),
        _colorDot(Colors.blue),
      ],
    );
  }

  Widget _colorDot(Color color) => Container(
    margin: const EdgeInsets.only(right: 8),
    width: 20, height: 20,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _buildListaOfertas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("OFERTAS EN CURSO", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ..._ofertas.map((o) => _buildOfertaCard(o)),
      ],
    );
  }

  Widget _buildOfertaCard(Map<String, dynamic> oferta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(12),
        // SOLUCIÓN AL ERROR: Acceso correcto a BorderSide
        border: Border(
          left: BorderSide(color: oferta['color'], width: 5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(oferta['titulo'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(oferta['descripcion'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.touch_app, color: brandRed, size: 14),
                    const SizedBox(width: 5),
                    Text("${oferta['clicks']} interesados", style: TextStyle(color: brandRed, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(oferta['descuento'], style: TextStyle(color: oferta['color'], fontSize: 24, fontWeight: FontWeight.w900)),
              const Text("DESC.", style: TextStyle(color: Colors.white24, fontSize: 10)),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white10), onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}