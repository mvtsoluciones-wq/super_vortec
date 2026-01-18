import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para FilteringTextInputFormatter
import 'package:url_launcher/url_launcher.dart';

class AdminControlPanel extends StatefulWidget {
  const AdminControlPanel({super.key});

  @override
  State<AdminControlPanel> createState() => _AdminControlPanelState();
}

class _AdminControlPanelState extends State<AdminControlPanel> {
  int _activeTab = 0;
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _videoController = TextEditingController();

  final Color bgBlack = const Color(0xFF000000);
  final Color cardGrey = const Color(0xFF111111);
  final Color vorteRed = const Color(0xFFD50000);
  final Color successGreen = const Color(0xFF00C853);

  Future<void> _launchYouTubeStudio() async {
    final Uri url = Uri.parse('https://studio.youtube.com/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 800) {
      return const Scaffold(
        backgroundColor: Colors.black, 
        body: Center(child: Text("ACCESO SOLO DESDE PC", style: TextStyle(color: Colors.white)))
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  Expanded(child: _buildCurrentModule()),
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
        color: cardGrey,
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 40, 10, 20),
            child: Container(
              height: 220, width: 260,
              alignment: Alignment.centerLeft, 
              child: Image.asset('assets/Logo.jpg', fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: vorteRed.withValues(alpha: 0.5), size: 50)),
            ),
          ),
          const Divider(color: Colors.white10, indent: 20, endIndent: 20),
          _sidebarItem(0, Icons.car_repair, "RECEPCIÓN DE VEHÍCULO"),
          _sidebarItem(1, Icons.dashboard_customize, "VARIABLES APP"),
          _sidebarItem(2, Icons.people_alt, "CLIENTES & LOGIN"),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    bool isSelected = _activeTab == index;
    return ListTile(
      onTap: () => setState(() => _activeTab = index),
      leading: Icon(icon, color: isSelected ? vorteRed : Colors.grey),
      title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedTileColor: vorteRed.withValues(alpha: 0.1),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("RECEPCIÓN DE VEHÍCULO", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
        _buildStatTile("ESTADO", "MODO MANUAL", vorteRed),
      ],
    );
  }

  Widget _buildCurrentModule() {
    if (_activeTab == 0) return _moduleRecepcionVehiculo();
    return const Center(child: Text("MÓDULO EN CONSTRUCCIÓN", style: TextStyle(color: Colors.white24)));
  }

  Widget _moduleRecepcionVehiculo() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(color: cardGrey, borderRadius: BorderRadius.circular(15)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("DATOS GENERALES", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
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
                  // CAMPO TELÉFONO ACTUALIZADO: NO PERMITE LETRAS
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
              const SizedBox(height: 30),
              const Text("VEHÍCULO", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
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
              _buildFormField("Descripción de la Falla", Icons.report_problem, maxLines: 3),
              const SizedBox(height: 40),
              
              const Text("EVIDENCIA EN VIDEO", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: vorteRed.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.link, color: Colors.grey),
                        const SizedBox(width: 10),
                        const Expanded(child: Text("PEGA EL ENLACE DE YOUTUBE AQUÍ", style: TextStyle(color: Colors.grey, fontSize: 12))),
                        TextButton.icon(
                          onPressed: _launchYouTubeStudio,
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text("ABRIR YOUTUBE STUDIO"),
                          style: TextButton.styleFrom(foregroundColor: vorteRed),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _videoController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "https://www.youtube.com/watch?v=...",
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                        filled: true,
                        fillColor: cardGrey,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Debes agregar el video de evidencia';
                        if (!value.contains("youtube.com") && !value.contains("youtu.be")) {
                          return 'El link debe ser de YouTube';
                        }
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
                  style: ElevatedButton.styleFrom(backgroundColor: successGreen, foregroundColor: Colors.white),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("REGISTRO EXITOSO"), backgroundColor: Colors.green),
                      );
                    }
                  }, 
                  child: const Text("GUARDAR REGISTRO DE ENTRADA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(String label, IconData icon, {bool isNumber = false, int maxLines = 1, TextEditingController? controller, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FUENTE DE LAS LETRAS QUE IDENTIFICAN LOS CAMPOS AUMENTADA (De 10 a 13)
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator ?? (value) => value == null || value.isEmpty ? 'Requerido' : null,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          // RESTRICCIÓN FÍSICA DE NÚMEROS SI isNumber ES TRUE
          inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey, size: 18),
            filled: true,
            fillColor: Colors.black,
            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: vorteRed), borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: cardGrey, borderRadius: BorderRadius.circular(5)),
      child: Column(children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9)), Text(val, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold))]),
    );
  }
}