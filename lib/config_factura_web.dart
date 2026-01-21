import 'package:flutter/material.dart';

class ConfigFacturaWeb extends StatefulWidget {
  const ConfigFacturaWeb({super.key});

  @override
  State<ConfigFacturaWeb> createState() => _ConfigFacturaWebState();
}

class _ConfigFacturaWebState extends State<ConfigFacturaWeb> {
  // Colores Corporativos
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // Controladores para los datos de la empresa
  final TextEditingController _ctrlNombreEmpresa = TextEditingController(text: "SUPER VORTEC 5.3");
  final TextEditingController _ctrlRifEmpresa = TextEditingController(text: "J-50123456-7");
  final TextEditingController _ctrlDireccion = TextEditingController(text: "Av. Principal con Calle Los Talleres, Caracas");
  final TextEditingController _ctrlTelefono = TextEditingController(text: "+58 212 555 1234");
  final TextEditingController _ctrlCorreo = TextEditingController(text: "servicios@supervortec.com");
  final TextEditingController _ctrlIva = TextEditingController(text: "16");

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: cardBlack,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                offset: const Offset(0, 15)
              )
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings_suggest, color: Colors.white, size: 28),
                  const SizedBox(width: 15),
                  const Text(
                    "CONFIGURACIÓN DE DATOS FISCALES",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                "Estos datos aparecerán automáticamente en el encabezado de cada PDF generado.",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 25),
                child: Divider(color: Colors.white10),
              ),

              // FORMULARIO DE DATOS DE EMPRESA
              Row(
                children: [
                  Expanded(child: _buildConfigField("Nombre de la Empresa", _ctrlNombreEmpresa, Icons.business)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildConfigField("RIF Jurídico", _ctrlRifEmpresa, Icons.badge)),
                ],
              ),
              const SizedBox(height: 20),
              _buildConfigField("Dirección Fiscal Completa", _ctrlDireccion, Icons.location_on, maxLines: 2),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildConfigField("Teléfono de Contacto", _ctrlTelefono, Icons.phone)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildConfigField("Correo Electrónico", _ctrlCorreo, Icons.email)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildConfigField("% IVA Aplicable", _ctrlIva, Icons.percent)),
                ],
              ),

              const SizedBox(height: 40),

              // BOTÓN DE GUARDADO
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("CONFIGURACIÓN ACTUALIZADA EXITOSAMENTE"), backgroundColor: Colors.green),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text("GUARDAR DATOS DE FACTURACIÓN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white, size: 20), // ICONO BLANCO
            filled: true,
            fillColor: inputFill,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: brandRed, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}