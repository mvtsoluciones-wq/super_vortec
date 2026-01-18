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

  // Paleta de Colores Industrial
  final Color bgBlack = const Color(0xFF000000);
  final Color cardGrey = const Color(0xFF111111);
  final Color vorteRed = const Color(0xFFD50000);
  final Color successGreen = const Color(0xFF00C853);

  // Función segura para abrir YouTube Studio
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
    
    // Bloqueo de escritorio
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
          // BARRA LATERAL
          _buildSidebar(),

          // ÁREA DE CONTENIDO
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

  // --- COMPONENTE: SIDEBAR ---
  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: cardGrey,
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          // LOGO IMPONENTE AGRANDADO
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
            child: Container(
              height: 180, // Tamaño aumentado según tu solicitud
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

          // TÍTULO DE SECCIÓN SOLICITADO
          const Padding(
            padding: EdgeInsets.fromLTRB(25, 20, 20, 10),
            child: Text(
              "OPCIONES DEL TALLER",
              style: TextStyle(
                color: Colors.white38, 
                fontSize: 11, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 1.5
              ),
            ),
          ),
          
          _sidebarItem(0, Icons.car_repair, "RECEPCIÓN DE VEHÍCULO"),
          _sidebarItem(1, Icons.dashboard_customize, "VARIABLES APP"),
          _sidebarItem(2, Icons.people_alt, "CLIENTES & LOGIN"),
          _sidebarItem(3, Icons.video_library, "MULTIMEDIA YOUTUBE"),
          _sidebarItem(4, Icons.settings, "CONFIG. SERVIDOR"),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    bool isSelected = _activeTab == index;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
      onTap: () => setState(() => _activeTab = index),
      leading: Icon(icon, color: isSelected ? vorteRed : Colors.grey),
      title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedTileColor: vorteRed.withValues(alpha: 0.1),
    );
  }

  // --- COMPONENTE: HEADER ---
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
    return const Center(child: Text("MÓDULO EN CONSTRUCCIÓN", style: TextStyle(color: Colors.white24)));
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
                  Expanded(child: _buildFormField(
                    "Correo Electrónico", 
                    Icons.email,
                    controller: _emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requerido';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Email inválido';
                      return null;
                    },
                  )),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildFormField("Cédula", Icons.badge, isNumber: true)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildFormField(
                    "Número de Teléfono", 
                    Icons.phone, 
                    isNumber: true,
                    controller: _phoneController,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requerido';
                      if (value.length < 10) return 'Mínimo 10 dígitos';
                      return null;
                    },
                  )),
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
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Link necesario';
                        if (!value.contains("youtube.com") && !value.contains("youtu.be")) return 'URL de YouTube no válida';
                        return null;
                      },
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("PROCESANDO INGRESO..."), backgroundColor: Colors.blue),
                      );
                    }
                  }, 
                  child: const Text("GUARDAR REGISTRO TÉCNICO", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- COMPONENTE: CAMPO DE FORMULARIO ---
  Widget _buildFormField(String label, IconData icon, {bool isNumber = false, int maxLines = 1, TextEditingController? controller, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator ?? (value) => value == null || value.isEmpty ? 'Requerido' : null,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: vorteRed.withValues(alpha: 0.6), size: 18),
            filled: true,
            fillColor: Colors.black,
            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: vorteRed, width: 2), borderRadius: BorderRadius.circular(8)),
            errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent), borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: cardGrey, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9)), Text(val, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold))]),
    );
  }
}