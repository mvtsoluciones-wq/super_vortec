import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _selectedCategory = "Todos";
  final List<String> _categories = ["Todos", "Camionetas", "Sedán", "Deportivos", "4x4"];

  // DATOS DE VEHÍCULOS (Ahora con Historial y Múltiples Fotos)
  final List<Map<String, dynamic>> _vehicles = [
    {
      "id": "1",
      "title": "Chevrolet Silverado Z71",
      "price": 28500,
      "category": "Camionetas",
      "year": "2018",
      "km": "85.000",
      "color": "Negro",
      "transmission": "Automático",
      "location": "Caracas, VE",
      // 5 FOTOS DEL CARRO
      "images": [
        "https://images.unsplash.com/photo-1552519507-da3b142c6e3d?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1605218427368-35b86128a355?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1494976388531-d1058494cdd8?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1580273916550-e323be2ae537?auto=format&fit=crop&w=800&q=80",
      ],
      // HISTORIAL DE REPARACIONES EN EL TALLER
      "serviceHistory": [
        {"date": "10 Ene 2026", "service": "Cambio de Aceite y Filtro (Sintético)"},
        {"date": "15 Dic 2025", "service": "Reemplazo de Pastillas de Freno"},
        {"date": "02 Nov 2025", "service": "Limpieza de Inyectores y Cuerpo de Aceleración"},
        {"date": "20 Ago 2025", "service": "Servicio General de Tren Delantero"},
      ]
    },
    {
      "id": "2",
      "title": "Toyota Tacoma TRD",
      "price": 42000,
      "category": "4x4",
      "year": "2021",
      "km": "40.000",
      "color": "Arena",
      "transmission": "Automático",
      "location": "Valencia, VE",
      "images": [
        "https://images.unsplash.com/photo-1594502184342-28ef38138768?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1583121274602-3e2820c698d9?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1594502184342-28ef38138768?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1594502184342-28ef38138768?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1594502184342-28ef38138768?auto=format&fit=crop&w=800&q=80",
      ],
      "serviceHistory": [
        {"date": "05 Ene 2026", "service": "Instalación Kit de Suspensión"},
        {"date": "10 Dic 2025", "service": "Mantenimiento 40.000 KM (Fluidos y Filtros)"},
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF121212);
    const Color brandRed = Color(0xFFD50000);

    final displayList = _selectedCategory == "Todos"
        ? _vehicles
        : _vehicles.where((v) => v['category'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: bgDark,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contacta al taller para publicar y certificar tu vehículo.")));
        },
        backgroundColor: brandRed,
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text("Vender mi Carro", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Vehículos Certificados", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // FILTROS
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(child: Text(cat, style: TextStyle(color: isSelected ? Colors.black : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13))),
                  ),
                );
              },
            ),
          ),
          // LISTA DE CARROS
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                return _buildCarCard(context, displayList[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(BuildContext context, Map<String, dynamic> car) {
    return GestureDetector(
      onTap: () {
        // NAVEGAR AL DETALLE
        Navigator.push(context, MaterialPageRoute(builder: (context) => VehicleDetailScreen(car: car)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 25),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  child: Image.network(
                    car['images'][0], // Muestra la primera foto
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(10)),
                    child: Text("\$${car['price'].toString()}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                Positioned(
                  bottom: 15,
                  left: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFD50000), borderRadius: BorderRadius.circular(5)),
                    child: Text("VERIFICADO POR EL TALLER", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(car['title'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text("${car['year']} • ${car['transmission']} • ${car['km']} km", style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PANTALLA DE DETALLE DEL VEHÍCULO ---
class VehicleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> car;

  const VehicleDetailScreen({super.key, required this.car});

  Future<void> _contactSeller(BuildContext context) async {
    const String phoneNumber = "584125508533"; 
    final String message = "Hola, estoy interesado en el ${car['title']} publicado en la app.";
    final Uri url = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");
    try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch (e) {
      if(!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se pudo abrir WhatsApp")));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF121212);
    final List<String> images = car['images'];
    final List<Map<String, String>> history = car['serviceHistory'];

    return Scaffold(
      backgroundColor: bgDark,
      body: CustomScrollView(
        slivers: [
          // 1. APP BAR CON FOTO PRINCIPAL
          SliverAppBar(
            backgroundColor: bgDark,
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: PageView.builder( // CARRUSEL DE FOTOS
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Image.network(images[index], fit: BoxFit.cover);
                },
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
            ),
          ),

          // 2. CONTENIDO
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITULO Y PRECIO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(car['title'], style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                      Text("\$${car['price']}", style: const TextStyle(color: Color(0xFFD50000), fontSize: 24, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // FICHA TÉCNICA (GRID)
                  const Text("FICHA TÉCNICA", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSpecItem(Icons.calendar_today, "Año", car['year']),
                        _buildSpecItem(Icons.speed, "Km", car['km']),
                        _buildSpecItem(Icons.settings, "Caja", car['transmission']),
                        _buildSpecItem(Icons.palette, "Color", car['color']),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // HISTORIAL DE TALLER (VALOR AGREGADO)
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.blueAccent),
                      const SizedBox(width: 10),
                      const Text("HISTORIAL EN EL TALLER", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text("Mantenimientos verificados por nosotros.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 15),

                  // LISTA DE SERVICIOS
                  ...history.map((service) => Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      border: Border(left: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.5), width: 4)),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service['date']!, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 5),
                        Text(service['service']!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  )),

                  const SizedBox(height: 80), // Espacio para el botón flotante
                ],
              ),
            ),
          ),
        ],
      ),
      // BOTÓN DE COMPRA
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        height: 55,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: () => _contactSeller(context),
          icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
          label: const Text("ME INTERESA ESTE VEHÍCULO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}