import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:url_launcher/url_launcher.dart';

class AdminControlPanel extends StatefulWidget {
  const AdminControlPanel({super.key});

  @override
  State<AdminControlPanel> createState() => _AdminControlPanelState();
}

class _AdminControlPanelState extends State<AdminControlPanel> {
  int _activeTab = 0;
  final _formKey = GlobalKey<FormState>();

  // Controladores de Texto
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _videoController = TextEditingController();

  // Colores Super Vortec
  final Color bgBlack = const Color(0xFF000000);
  final Color cardGrey = const Color(0xFF111111);
  final Color vorteRed = const Color(0xFFD50000);
  final Color successGreen = const Color(0xFF00C853);

  Future<void> _launchYouTubeStudio() async {
    final Uri url = Uri.parse('https://studio.youtube.com/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir el navegador")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 800) {
      return const Scaffold(
        backgroundColor: Colors.black, 
        body: Center(child: Text("ACCESO RESTRINGIDO A PC", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
      );
    }

    return Scaffold(
      backgroundColor: bgBlack,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(35),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: _buildCurrentModule(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SIDEBAR ORGANIZADO POR SECCIONES ---
  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: cardGrey,
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: SingleChildScrollView( // Permite scroll si el menú es muy largo
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            // LOGO
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
              child: Container(
                height: 180,
                width: double.infinity,
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/weblogo.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => 
                    Icon(Icons.broken_image, color: vorteRed.withValues(alpha: 0.2), size: 60),
                ),
              ),
            ),

            const Divider(color: Colors.white10, indent: 20, endIndent: 20),

            // SECCIÓN 1: OPCIONES DEL TALLER
            _buildSectionTitle("OPCIONES DEL TALLER"),
            _sidebarItem(0, Icons.car_repair, "RECEPCIÓN DE VEHÍCULO"),
            _sidebarItem(1, Icons.biotech, "DIAGNÓSTICO"), // Nueva
            _sidebarItem(2, Icons.track_changes, "SEGUIMIENTO"), // Nueva
            _sidebarItem(3, Icons.people_alt, "CLIENTES & LOGIN"),

            const SizedBox(height: 20),
            const Divider(color: Colors.white10, indent: 20, endIndent: 20),

            // SECCIÓN 2: HERRAMIENTAS
            _buildSectionTitle("HERRAMIENTAS"),
            _sidebarItem(4, Icons.notifications, "NOTIFICACIÓN"),
            _sidebarItem(5, Icons.storefront, "TIENDA"),
            _sidebarItem(6, Icons.local_offer, "OFERTAS"),
            _sidebarItem(7, Icons.shopping_bag, "MARKET"),

            const SizedBox(height: 20),
            const Divider(color: Colors.white10, indent: 20, endIndent: 20),

            // SECCIÓN 3: ADMINISTRACIÓN
            _buildSectionTitle("ADMINISTRACIÓN"),
            _sidebarItem(8, Icons.receipt_long, "FACTURACIÓN"),
            _sidebarItem(9, Icons.description, "PRESUPUESTOS"),
            _sidebarItem(10, Icons.inventory_2, "INVENTARIO"),
            _sidebarItem(11, Icons.shopping_cart, "COMPRAS"),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper para títulos de sección
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 15, 20, 10),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    bool isSelected = _activeTab == index;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
      onTap: () => setState(() => _activeTab = index),
      leading: Icon(icon, color: isSelected ? vorteRed : Colors.grey, size: 20),
      title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedTileColor: vorteRed.withValues(alpha: 0.1),
      dense: true, // Hace el menú más compacto para que quepan todas las opciones
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("SISTEMA DE CONTROL", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
        _buildStatTile("MODO", "ADMINISTRADOR", vorteRed),
      ],
    );
  }

  Widget _buildCurrentModule() {
    if (_activeTab == 0) return _moduleRecepcionVehiculo();
    return Center(child: Text("MÓDULO ${_activeTab.toString()} EN CONSTRUCCIÓN", style: const TextStyle(color: Colors.white24)));
  }

  // --- MÓDULO: RECEPCIÓN DE VEHÍCULO ---
  Widget _moduleRecepcionVehiculo() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(35),
          decoration: BoxDecoration(
            color: cardGrey, 
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.assignment_add, color: Colors.white70),
                  SizedBox(width: 10),
                  Text("NUEVO INGRESO TÉCNICO", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 30),
              
              Row(
                children: [
                  Expanded(child: _buildFormField("Nombre y Apellido", Icons.person)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildFormField("Correo Electrónico", Icons.email, controller: _emailController)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildFormField("Cédula", Icons.badge, isNumber: true)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildFormField("Teléfono", Icons.phone, isNumber: true, controller: _phoneController)),
                ],
              ),
              
              const Padding(padding: EdgeInsets.symmetric(vertical: 25), child: Divider(color: Colors.white10)),

              Row(
                children: [
                  Expanded(child: _buildFormField("Placa", Icons.directions_car)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildFormField("Color", Icons.palette)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildFormField("Año", Icons.calendar_today, isNumber: true)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildFormField("Kilometraje", Icons.speed, isNumber: true)),
                ],
              ),
              const SizedBox(height: 20),
              _buildFormField("Descripción de la Falla", Icons.build_circle_outlined, maxLines: 3),
              const SizedBox(height: 35),
              
              // SECCIÓN DE VIDEO
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: vorteRed.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.videocam_outlined, color: Colors.grey, size: 18),
                        const SizedBox(width: 10),
                        const Text("LINK EVIDENCIA YOUTUBE", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _launchYouTubeStudio,
                          icon: const Icon(Icons.open_in_new, size: 14),
                          label: const Text("SUBIR VIDEO"),
                          style: TextButton.styleFrom(foregroundColor: vorteRed, textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _videoController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Pegue la URL del video aquí",
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.1)),
                        filled: true,
                        fillColor: Colors.black,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successGreen, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("GUARDANDO...")));
                    }
                  }, 
                  child: const Text("GUARDAR REGISTRO TÉCNICO", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(String label, IconData icon, {bool isNumber = false, int maxLines = 1, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: vorteRed.withValues(alpha: 0.6), size: 18),
            filled: true,
            fillColor: Colors.black,
            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: vorteRed, width: 2), borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: cardGrey, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9)), Text(val, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold))]),
    );
  }
}