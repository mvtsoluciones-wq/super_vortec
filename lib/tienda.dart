import 'package:flutter/material.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  // ESTADO
  String _selectedCategory = "Todo";
  final List<Map<String, dynamic>> _cart = [];

  // DATOS DE PRODUCTOS (Simulados)
  final List<Map<String, dynamic>> _allProducts = [
    {
      "id": "1",
      "name": "Aceite 5W30 Dexos",
      "brand": "AC Delco",
      "price": 12.00,
      "category": "Aceites",
      "image": "https://m.media-amazon.com/images/I/61s+4+-+L._AC_SX679_.jpg", // Link ejemplo
      "rating": 4.8,
    },
    {
      "id": "2",
      "name": "Filtro de Aceite",
      "brand": "Wix Filters",
      "price": 8.50,
      "category": "Filtros",
      "image": "", 
      "rating": 4.5,
    },
    {
      "id": "3",
      "name": "Pastillas de Freno",
      "brand": "Bosch Ceramic",
      "price": 45.00,
      "category": "Frenos",
      "image": "",
      "rating": 4.9,
    },
    {
      "id": "4",
      "name": "Bujía Iridium",
      "brand": "NGK",
      "price": 12.00,
      "category": "Eléctrico",
      "image": "",
      "rating": 4.7,
    },
    {
      "id": "5",
      "name": "Kit Limpieza Motor",
      "brand": "SuperClean",
      "price": 25.00,
      "category": "Limpieza",
      "image": "",
      "rating": 4.2,
    },
    {
      "id": "6",
      "name": "Refrigerante 50/50",
      "brand": "Prestone",
      "price": 18.00,
      "category": "Fluidos",
      "image": "",
      "rating": 4.6,
    },
  ];

  final List<String> _categories = ["Todo", "Aceites", "Frenos", "Eléctrico", "Filtros", "Limpieza"];

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF121212);
    const Color brandRed = Color(0xFFD50000);

    // Filtrar productos
    final displayProducts = _selectedCategory == "Todo"
        ? _allProducts
        : _allProducts.where((p) => p['category'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: bgDark,
      // BOTÓN FLOTANTE DEL CARRITO
      floatingActionButton: _cart.isNotEmpty 
        ? FloatingActionButton.extended(
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ir al Checkout (Próximamente)")));
            },
            backgroundColor: brandRed,
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            label: Text("${_cart.length} | \$${_calculateTotal()}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        : null,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Tienda de Repuestos", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. FILTROS DE CATEGORÍA
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
                      color: isSelected ? brandRed : const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? brandRed : Colors.white12),
                    ),
                    child: Center(
                      child: Text(
                        cat, 
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[400], 
                          fontWeight: FontWeight.bold,
                          fontSize: 12
                        )
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. GRID DE PRODUCTOS
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 columnas
                childAspectRatio: 0.75, // Relación de aspecto (Alto vs Ancho)
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: displayProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(displayProducts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGEN
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white, // Fondo blanco para que resalte el producto
                borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.oil_barrel, size: 50, color: Colors.grey[400]), // Placeholder si no hay imagen
                    // Aquí iría: Image.network(product['image'])
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(5)),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 10),
                          const SizedBox(width: 4),
                          Text(product['rating'].toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          
          // INFO
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product['brand'], style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        product['name'], 
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("\$${product['price'].toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _cart.add(product);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${product['name']} agregado"),
                              duration: const Duration(milliseconds: 800),
                              backgroundColor: const Color(0xFFD50000),
                            )
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: const Color(0xFFD50000), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  String _calculateTotal() {
    double total = 0;
    for (var item in _cart) {
      total += item['price'];
    }
    return total.toStringAsFixed(2);
  }
}