import 'package:flutter/material.dart';

class OfferScreen extends StatelessWidget {
  const OfferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF121212);

    // DATOS DE OFERTAS
    final List<Map<String, dynamic>> offers = [
      {
        "title": "Cambio de Aceite Full Sintético",
        "discount": "20%",
        "description": "Incluye filtro de aceite y revisión de 15 puntos de seguridad.",
        "validUntil": "18 Ene",
        "color1": const Color(0xFF8E2DE2), // Degradado Morado
        "color2": const Color(0xFF4A00E0),
        "code": "OIL20",
      },
      {
        "title": "Diagnóstico Computarizado",
        "discount": "GRATIS",
        "description": "Al realizar cualquier reparación mayor a \$100 en el taller.",
        "validUntil": "30 Ene",
        "color1": const Color(0xFFF12711), // Degradado Rojo Naranja
        "color2": const Color(0xFFF5AF19),
        "code": "SCANFREE",
      },
      {
        "title": "Alineación y Balanceo",
        "discount": "2x1",
        "description": "Paga el eje delantero y te regalamos el trasero. Solo camionetas.",
        "validUntil": "Hoy",
        "color1": const Color(0xFF11998e), // Degradado Verde
        "color2": const Color(0xFF38ef7d),
        "code": "ALIEN2X1",
      },
    ];

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Ofertas y Promociones", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final promo = offers[index];
          return _buildCouponCard(context, promo);
        },
      ),
    );
  }

  Widget _buildCouponCard(BuildContext context, Map<String, dynamic> promo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [promo['color1'], promo['color2']],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: promo['color1'].withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Stack(
        children: [
          // CÍRCULOS DECORATIVOS DE FONDO (Marca de agua)
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.local_offer, size: 150, color: Colors.white.withOpacity(0.1)),
          ),
          
          // CONTENIDO
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        "Válido hasta: ${promo['validUntil']}", 
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          promo['discount'], 
                          style: const TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.w900, height: 1)
                        ),
                        const SizedBox(width: 5),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 5),
                          child: Text("OFF", style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      promo['title'], 
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        promo['description'], 
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 15),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("¡Cupón ${promo['code']} canjeado!"),
                            backgroundColor: Colors.green,
                          )
                        );
                      }, 
                      child: const Text("CANJEAR", style: TextStyle(fontWeight: FontWeight.bold))
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}