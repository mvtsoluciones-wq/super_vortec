import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- IMPORTACIONES DE MÓDULOS ---
import 'diagnostico_web.dart';
import 'presupuesto_web.dart';
import 'seguimiento_web.dart';
import 'clientes_web.dart';
import 'notificaciones_web.dart';
import 'tienda_web.dart';
import 'ofertas_web.dart';
import 'market_web.dart';
import 'facturacion_web.dart';
import 'inventario_web.dart';
import 'config_factura_web.dart'; 
import 'historial_web.dart';
import 'presupuesto_app.dart';
import 'tecnicos_web.dart';

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

  // --- CONTROLADORES ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController(); 
  final TextEditingController _brandController = TextEditingController(); 
  final TextEditingController _modelController = TextEditingController(); 
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _kmController = TextEditingController();
  final TextEditingController _obsController = TextEditingController();
  final TextEditingController _videoController = TextEditingController();

  // --- NUEVA FUNCIÓN: BUSCADOR DE CLIENTE RECURRENTE ---
  Future<void> _buscarClienteRecurrente() async {
    String cedula = _idController.text.trim();
    if (cedula.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ INGRESE UNA CÉDULA PARA BUSCAR"), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      var doc = await FirebaseFirestore.instance.collection('clientes').doc(cedula).get();
      if (doc.exists) {
        var data = doc.data()!;
        setState(() {
          _nameController.text = data['nombre'] ?? "";
          _emailController.text = data['email'] ?? "";
          _phoneController.text = data['telefono'] ?? "";
          _addressController.text = data['direccion'] ?? "";
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ DATOS DEL CLIENTE RECUPERADOS"), backgroundColor: Colors.blueAccent),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ℹ️ CLIENTE NO REGISTRADO (NUEVO)"), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      debugPrint("Error al buscar cliente: $e");
    }
  }

  Future<void> _guardarRegistroEnBaseDeDatos() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ ERROR: TODOS LOS CAMPOS SON OBLIGATORIOS"), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFD50000))),
    );

    try {
      String clienteId = _idController.text.trim();
      String placa = _plateController.text.trim().toUpperCase();

      // --- REGISTRO/ACTUALIZACIÓN DE CLIENTE (MERGE: TRUE) ---
      await FirebaseFirestore.instance.collection('clientes').doc(clienteId).set({
        'nombre': _nameController.text.trim().toUpperCase(),
        'email': _emailController.text.trim().toLowerCase(),
        'telefono': _phoneController.text.trim(),
        'cedula': clienteId,
        'direccion': _addressController.text.trim().toUpperCase(),
        'ultima_visita': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // --- REGISTRO DEL VEHÍCULO ---
      await FirebaseFirestore.instance.collection('vehiculos').doc(placa).set({
        'placa': placa,
        'marca': _brandController.text.trim().toUpperCase(),
        'modelo': _modelController.text.trim().toUpperCase(),
        'color': _colorController.text.trim().toUpperCase(),
        'anio': _yearController.text.trim(),
        'km': _kmController.text.trim(),
        'observaciones_ingreso': _obsController.text.trim(),
        'video_recepcion': _videoController.text.trim(),
        'propietario_id': clienteId,
        'en_taller': true,
        'fecha_ingreso': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context); 

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ VEHÍCULO VINCULADO AL CLIENTE"), backgroundColor: Colors.green),
      );

      // Limpieza selectiva: se limpian datos del vehículo, pero se mantienen los del cliente
      _plateController.clear();
      _brandController.clear();
      _modelController.clear();
      _colorController.clear();
      _yearController.clear();
      _kmController.clear();
      _obsController.clear();
      _videoController.clear();
      
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ ERROR DE CONEXIÓN: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _launchYouTubeStudio() async {
    final Uri url = Uri.parse('https://studio.youtube.com/');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir YouTube Studio")),
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
                  _buildHeader(), 
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
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  // --- SECCIÓN DEL LOGO MODIFICADA ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(25, 80, 25, 50), // Aumentado padding para que respire
                    child: Center(
                      child: Transform.scale(
                        scale: 4.0, // LOGO AGRANDADO (Ajusta este valor según prefieras)
                        child: Image.asset(
                          'assets/weblogo.jpg',
                          height: 100, // Altura base
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.directions_car, color: brandRed, size: 60),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Espacio extra tras el logo escalado
                  _buildSectionTitle("OPCIONES DEL TALLER"),
                  _sidebarItem(0, Icons.car_repair_rounded, "RECEPCIÓN"),
                  _sidebarItem(1, Icons.analytics_outlined, "DIAGNÓSTICO"),
                  _sidebarItem(2, Icons.gps_fixed_rounded, "SEGUIMIENTO"),
                  _sidebarItem(3, Icons.person_search_rounded, "CLIENTES"),
                  _sidebarItem(11, Icons.history_edu_rounded, "HISTORIAL"),
                  _sidebarItem(13, Icons.description_rounded, "PRESUPUESTOS APP"),
                  _buildDivider(),
                  _buildSectionTitle("HERRAMIENTAS"),
                  _sidebarItem(4, Icons.notifications_active_outlined, "NOTIFICACIÓN"),
                  _sidebarItem(5, Icons.storefront_rounded, "TIENDA"),
                  _sidebarItem(6, Icons.local_fire_department_rounded, "OFERTAS"),
                  _sidebarItem(7, Icons.hub_outlined, "MARKET"),
                  _buildDivider(),
                  _buildSectionTitle("ADMINISTRACIÓN"),
                  _sidebarItem(8, Icons.account_balance_wallet_outlined, "FACTURACIÓN"),
                  _sidebarItem(12, Icons.settings_suggest_rounded, "CONFIG. FISCAL"),
                  _sidebarItem(9, Icons.request_quote_outlined, "PRESUPUESTOS"),
                  _sidebarItem(10, Icons.inventory_2_outlined, "INVENTARIO"),
                  _sidebarItem(14, Icons.engineering_rounded, "TÉCNICOS"),
                ],
              ),
            ),
          ),
          _buildDivider(),
          ListTile(
            onTap: () async => await FirebaseAuth.instance.signOut(),
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            title: const Text("CERRAR SESIÓN", style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    bool isSelected = _activeTab == index;
    return ListTile(
      onTap: () => setState(() => _activeTab = index),
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white38, size: 20),
      title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedTileColor: brandRed.withValues(alpha: 0.15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("JMendez Performance", style: TextStyle(color: Colors.white24, fontSize: 12, letterSpacing: 4, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Row(
          children: [
            const Text(
              "SISTEMA DE CONTROL",
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(width: 15),
            Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            const Text("ONLINE", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentModule() {
    switch (_activeTab) {
      case 0: return _moduleRecepcionVehiculo();
      case 1: return const DiagnosticoWebModule();
      case 2: return const SeguimientoWebModule();
      case 3: return const ClientesWebModule();
      case 4: return const NotificacionesWebModule();
      case 5: return const TiendaWebModule();
      case 6: return const OfertasWebModule();
      case 7: return const MarketWebModule();
      case 8: return const FacturacionWebModule();
      case 12: return const ConfigFacturaWeb(); 
      case 9: return const PresupuestoWebModule();
      case 10: return const InventarioWebModule();
      case 11: return const HistorialWebModule();
      case 13: return const PresupuestoAppModule();
      case 14: return const TecnicosWebModule ();
     
      default:
        return const Center(child: Icon(Icons.construction_rounded, color: Colors.white10, size: 150));
    }
  }

  Widget _moduleRecepcionVehiculo() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
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
                const Text("REGISTRO DE INGRESO TÉCNICO", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 35),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        "Cédula / ID", 
                        Icons.badge_outlined, 
                        isNumber: true, 
                        controller: _idController,
                        suffix: IconButton(
                          icon: const Icon(Icons.search, color: Colors.blueAccent),
                          onPressed: _buscarClienteRecurrente,
                          tooltip: "Buscar Cliente",
                        )
                      )
                    ),
                    const SizedBox(width: 25),
                    Expanded(child: _buildFormField("Propietario", Icons.person_outline, controller: _nameController)),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(child: _buildFormField("E-mail", Icons.alternate_email_rounded, controller: _emailController)),
                    const SizedBox(width: 25),
                    Expanded(child: _buildFormField("Teléfono Móvil", Icons.smartphone_rounded, isNumber: true, controller: _phoneController)),
                  ],
                ),
                const SizedBox(height: 25),
                _buildFormField("Dirección de Habitación", Icons.location_on_outlined, controller: _addressController),
                
                const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Divider(color: Colors.white10)),
                
                Row(
                  children: [
                    Expanded(child: _buildFormField("Marca", Icons.factory_outlined, controller: _brandController)),
                    const SizedBox(width: 25),
                    Expanded(child: _buildFormField("Modelo", Icons.directions_car_filled, controller: _modelController)),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(child: _buildFormField("Placa / Matrícula", Icons.tag, controller: _plateController)),
                    const SizedBox(width: 25),
                    Expanded(child: _buildFormField("Color", Icons.color_lens_outlined, controller: _colorController)),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(child: _buildFormField("Año", Icons.event_note_rounded, isNumber: true, controller: _yearController)),
                    const SizedBox(width: 25),
                    Expanded(child: _buildFormField("Kilometraje (Km)", Icons.speed_rounded, isNumber: true, controller: _kmController)),
                  ],
                ),
                const SizedBox(height: 25),
                _buildFormField("Descripcion de falla", Icons.edit_note_rounded, maxLines: 3, controller: _obsController),
                const SizedBox(height: 35),
                _buildVideoCard(),
                const SizedBox(height: 40),
                _buildFinalButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(String label, IconData icon, {bool isNumber = false, int maxLines = 1, TextEditingController? controller, Widget? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          textInputAction: TextInputAction.next,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return "Falta llenar: $label";
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white, size: 20), 
            suffixIcon: suffix, 
            filled: true,
            fillColor: inputFill,
            errorStyle: const TextStyle(color: Colors.orangeAccent),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: brandRed, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.orangeAccent, width: 1)),
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
              const Icon(Icons.video_library_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Text("VIDEO RECEPCION DEL VEHICULO", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
            validator: (val) {
               if (val == null || val.trim().isEmpty) return "⚠️ Agregue link de video de recepción";
               return null;
            },
            decoration: InputDecoration(
              hintText: "URL de YouTube (OBLIGATORIO)",
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: deepBlack,
              errorStyle: const TextStyle(color: Colors.orangeAccent),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.orangeAccent, width: 1)),
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
        onPressed: _guardarRegistroEnBaseDeDatos,
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