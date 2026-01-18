import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:url_launcher/url_launcher.dart';
import 'diagnostico_web.dart';

class AdminControlPanel extends StatefulWidget {
  const AdminControlPanel({super.key});

  @override
  State<AdminControlPanel> createState() => _AdminControlPanelState();
}

class _AdminControlPanelState extends State<AdminControlPanel> {
  int _activeTab = 0;
  final _formKey = GlobalKey<FormState>();

  // --- PALETA DE COLORES ---
  final Color brandRed = const Color(0xFFD50000); 
  final Color deepBlack = const Color(0xFF000000);
  final Color mediumGrey = const Color(0xFF454D55); 
  final Color cardBlack = const Color(0xFF101010);  
  final Color inputFill = const Color(0xFF1E1E1E); 

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _videoController = TextEditingController();

  Future<void> _launchYouTubeStudio() async {
    final Uri url = Uri.parse('https://studio.youtube.com/');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir el enlace")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 800) {
      return Scaffold(
        backgroundColor: deepBlack,
        body: const Center(child: Text("ACCESO SOLO PC", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: mediumGrey,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(), // Encabezado con sombra y borde
                  const SizedBox(height: 30),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 950),
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

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: deepBlack,
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15)],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 60, 25, 30),
              child: Image.asset(
                'assets/weblogo.jpg',
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.directions_car, color: brandRed, size: 60),
              ),
            ),
            _buildSectionTitle("OPCIONES DEL TALLER"),
            _sidebarItem(0, Icons.car_repair_rounded, "RECEPCIÓN"),
            _sidebarItem(1, Icons.analytics_outlined, "DIAGNÓSTICO"),
            _sidebarItem(2, Icons.gps_fixed_rounded, "SEGUIMIENTO"),
            _sidebarItem(3, Icons.person_search_rounded, "CLIENTES"),
            _buildDivider(),
            _buildSectionTitle("HERRAMIENTAS"),
            _sidebarItem(4, Icons.notifications_active_outlined, "NOTIFICACIÓN"),
            _sidebarItem(5, Icons.storefront_rounded, "TIENDA"),
            _sidebarItem(6, Icons.local_fire_department_rounded, "OFERTAS"),
            _sidebarItem(7, Icons.hub_outlined, "MARKET"),
            _buildDivider(),
            _buildSectionTitle("ADMINISTRACIÓN"),
            _sidebarItem(8, Icons.account_balance_wallet_outlined, "FACTURACIÓN"),
            _sidebarItem(9, Icons.request_quote_outlined, "PRESUPUESTOS"),
            _sidebarItem(10, Icons.inventory_2_outlined, "INVENTARIO"),
            _sidebarItem(11, Icons.shopping_cart_checkout_rounded, "COMPRAS"),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    bool isSelected = _activeTab == index;
    return ListTile(
      onTap: () => setState(() => _activeTab = index),
      leading: Icon(icon, color: isSelected ? brandRed : Colors.white38, size: 20),
      title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedTileColor: brandRed.withValues(alpha: 0.15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
    );
  }

  // --- HEADER: SISTEMA DE CONTROL CON BORDE Y SOMBRA ---
  Widget _buildHeader() {
    return Stack(
      children: [
        // Sombra y Borde del Texto
        Text(
          "SISTEMA DE CONTROL",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.black, // Borde Negro
          ),
        ),
        // Texto Principal Blanco con Sombra Proyectada
        const Text(
          "SISTEMA DE CONTROL",
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black54,
                offset: Offset(4.0, 4.0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentModule() {
    // Este switch decide qué archivo mostrar según la pestaña activa
  switch (_activeTab) {
    case 0:
      return _moduleRecepcionVehiculo(); // Pestaña de Recepción
    case 1:
      return const DiagnosticoWebModule(); // <--- Aquí usamos el nuevo archivo
    default:
      // Para todas las demás pestañas que aún no creamos
      return const Center(
        child: Icon(Icons.construction_rounded, color: Colors.white10, size: 150),
      );
  }
}

  Widget _moduleRecepcionVehiculo() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: cardBlack, 
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 15))],
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("REGISTRO DE INGRESO TÉCNICO", style: TextStyle(color: brandRed, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 35),
              Row(
                children: [
                  Expanded(child: _buildFormField("Propietario", Icons.person_outline)),
                  const SizedBox(width: 25),
                  Expanded(child: _buildFormField("E-mail", Icons.alternate_email_rounded, controller: _emailController)),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(child: _buildFormField("Cédula / ID", Icons.badge_outlined, isNumber: true)),
                  const SizedBox(width: 25),
                  Expanded(child: _buildFormField("Teléfono Móvil", Icons.smartphone_rounded, isNumber: true, controller: _phoneController)),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Divider(color: Colors.white10)),
              Row(
                children: [
                  Expanded(child: _buildFormField("Placa / Matrícula", Icons.tag)),
                  const SizedBox(width: 25),
                  Expanded(child: _buildFormField("Color", Icons.color_lens_outlined)),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(child: _buildFormField("Año", Icons.event_note_rounded, isNumber: true)),
                  const SizedBox(width: 25),
                  Expanded(child: _buildFormField("Kilometraje (Km)", Icons.speed_rounded, isNumber: true)),
                ],
              ),
              const SizedBox(height: 25),
              _buildFormField("Observaciones Técnicas", Icons.edit_note_rounded, maxLines: 3),
              const SizedBox(height: 35),
              _buildVideoCard(),
              const SizedBox(height: 40),
              _buildFinalButton(),
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
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: brandRed, size: 20),
            filled: true,
            fillColor: inputFill,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: brandRed, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.video_library_rounded, color: brandRed, size: 20),
              const SizedBox(width: 12),
              const Text("EVIDENCIA MULTIMEDIA", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _launchYouTubeStudio,
                icon: const Icon(Icons.upload_rounded, size: 14),
                label: const Text("YOUTUBE STUDIO"),
                style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _videoController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: "URL de YouTube",
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: deepBlack,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandRed, 
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 10,
        ),
        onPressed: () { if (_formKey.currentState!.validate()) {} },
        child: const Text("GUARDAR REGISTRO TÉCNICO", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ),
    );
  }

  Widget _buildDivider() => const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: Colors.white10, indent: 20, endIndent: 20));
  
  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(25, 15, 20, 10), 
    child: Text(title, style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5))
  );
}