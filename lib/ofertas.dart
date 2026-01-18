import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OfferScreen extends StatelessWidget {
  const OfferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF121212);

    final List<Map<String, dynamic>> offers = [
      {
        "title": "Cambio de Aceite",
        "category": "MANTENIMIENTO",
        "discount": "20%",
        "description": "Incluye filtro y revisión de fluidos.",
        "validUntil": "18 Ene",
        "color": const Color(0xFFD50000), // Rojo Vortec
        "code": "OIL20",
      },
      {
        "title": "Escáner General",
        "category": "DIAGNÓSTICO",
        "discount": "FREE",
        "description": "Gratis al realizar la reparación.",
        "validUntil": "30 Ene",
        "color": const Color(0xFF2962FF), // Azul Intenso
        "code": "SCANFREE",
      },
      {
        "title": "Tren Delantero",
        "category": "MECÁNICA",
        "discount": "15%",
        "description": "Descuento en mano de obra.",
        "validUntil": "Hoy",
        "color": const Color(0xFFFF6D00), // Naranja
        "code": "TREN15",
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
        title: const Text("Mis Cupones", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: offers.length,
        itemBuilder: (context, index) {
          return _buildTicketCard(context, offers[index]);
        },
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, Map<String, dynamic> promo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      height: 160,
      child: Stack(
        children: [
          // CAPA BASE BLANCA (EL TICKET)
          Row(
            children: [
              // LADO IZQUIERDO (DESCUENTO - COLOR SÓLIDO)
              Container(
                width: 110,
                decoration: BoxDecoration(
                  color: promo['color'],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      promo['discount'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      "OFF",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2
                      ),
                    ),
                  ],
                ),
              ),
              
              // LADO DERECHO (INFORMACIÓN - BLANCO)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(25, 15, 15, 15),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4)
                            ),
                            child: Text(
                              promo['category'],
                              style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            promo['title'],
                            style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            promo['description'],
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Vence: ${promo['validUntil']}",
                            style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: promo['code']));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Código ${promo['code']} copiado"),
                                  backgroundColor: Colors.green,
                                )
                              );
                            },
                            child: const Text(
                              "USAR CUPÓN",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                decoration: TextDecoration.underline
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),

          // DECORACIÓN: MUESCAS Y LÍNEA PUNTEADA (EFECTO TICKET)
          Positioned(
            left: 100, // Justo entre los dos colores
            top: -10,
            bottom: -10,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // CÍRCULO NEGRO ARRIBA (Muesca)
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF121212), // Mismo color que el fondo de la pantalla
                    shape: BoxShape.circle,
                  ),
                ),
                // LÍNEA PUNTEADA
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Flex(
                        direction: Axis.vertical,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(10, (_) {
                          return Container(
                            width: 2,
                            height: 5,
                            color: Colors.grey[300],
                          );
                        }),
                      );
                    },
                  ),
                ),
                // CÍRCULO NEGRO ABAJO (Muesca)
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF121212), // Mismo color que el fondo de la pantalla
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}