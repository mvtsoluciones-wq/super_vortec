import 'package:flutter/material.dart';

// --- CLASE DE DATOS GLOBAL ---
class ConfigFactura {
  static String nombreEmpresa = "MENDEZ Y VEGAS TELECOMUNICACIONES C.A.";
  static String rifEmpresa = "J-29799471-8";
  static String direccionEmpresa = "Av. Trujillo, Edif. Bloque 2, Letra B, Piso 2, Caracas";
  static String telefonoEmpresa = "(0212) 639.04.57";
  static String correoEmpresa = "mvtsoluciones@gmail.com";
  static String ivaPorcentaje = "16";
  static String logoPath = "assets/weblogo.jpg";
}

class ConfigFacturaWeb extends StatefulWidget {
  const ConfigFacturaWeb({super.key});

  @override
  State<ConfigFacturaWeb> createState() => _ConfigFacturaWebState();
}

class _ConfigFacturaWebState extends State<ConfigFacturaWeb> {
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  late TextEditingController _ctrlNombreEmpresa;
  late TextEditingController _ctrlRifEmpresa;
  late TextEditingController _ctrlDireccion;
  late TextEditingController _ctrlTelefono;
  late TextEditingController _ctrlCorreo;
  late TextEditingController _ctrlIva;

  @override
  void initState() {
    super.initState();
    _ctrlNombreEmpresa = TextEditingController(text: ConfigFactura.nombreEmpresa);
    _ctrlRifEmpresa = TextEditingController(text: ConfigFactura.rifEmpresa);
    _ctrlDireccion = TextEditingController(text: ConfigFactura.direccionEmpresa);
    _ctrlTelefono = TextEditingController(text: ConfigFactura.telefonoEmpresa);
    _ctrlCorreo = TextEditingController(text: ConfigFactura.correoEmpresa);
    _ctrlIva = TextEditingController(text: ConfigFactura.ivaPorcentaje);
  }

  void _guardarConfiguracion() {
    setState(() {
      ConfigFactura.nombreEmpresa = _ctrlNombreEmpresa.text;
      ConfigFactura.rifEmpresa = _ctrlRifEmpresa.text;
      ConfigFactura.direccionEmpresa = _ctrlDireccion.text;
      ConfigFactura.telefonoEmpresa = _ctrlTelefono.text;
      ConfigFactura.correoEmpresa = _ctrlCorreo.text;
      ConfigFactura.ivaPorcentaje = _ctrlIva.text;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("CONFIGURACIÓN FISCAL ACTUALIZADA"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 850),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: cardBlack,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                // CAMBIO AQUÍ: Se reemplazó .withOpacity(0.5) por .withValues(alpha: 0.5)
                color: Colors.black.withValues(alpha: 0.5), 
                blurRadius: 30,
                offset: const Offset(0, 15),
              )
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings_suggest, color: Colors.white, size: 32),
                  const SizedBox(width: 15),
                  const Text(
                    "CONFIGURACIÓN DE DATOS FISCALES",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                "Los cambios realizados aquí se reflejarán en el módulo de Facturación y en los PDFs.",
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 25),
                child: Divider(color: Colors.white10),
              ),
              Row(
                children: [
                  Expanded(child: _buildConfigField("Nombre o Razón Social", _ctrlNombreEmpresa, Icons.business)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildConfigField("RIF Jurídico", _ctrlRifEmpresa, Icons.badge)),
                ],
              ),
              const SizedBox(height: 20),
              _buildConfigField("Dirección Fiscal Completa", _ctrlDireccion, Icons.location_on, maxLines: 2),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(flex: 2, child: _buildConfigField("Teléfono", _ctrlTelefono, Icons.phone)),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _buildConfigField("Email", _ctrlCorreo, Icons.email)),
                  const SizedBox(width: 20),
                  Expanded(flex: 1, child: _buildConfigField("% IVA", _ctrlIva, Icons.percent)),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _guardarConfiguracion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                  icon: const Icon(Icons.save_as_rounded, color: Colors.white),
                  label: const Text("GUARDAR Y SINCRONIZAR DATOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white70, size: 20),
            filled: true,
            fillColor: inputFill,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: brandRed, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}