import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

// --- CLASE DE DATOS GLOBAL ---
class ConfigFactura {
  static String nombreEmpresa = "MENDEZ Y VEGAS TELECOMUNICACIONES C.A.";
  static String rifEmpresa = "J-29799471-8";
  static String direccionEmpresa = "Av. Trujillo, Edif. Bloque 2, Letra B, Piso 2, Caracas";
  static String telefonoEmpresa = "(0212) 639.04.57";
  static String correoEmpresa = "mvtsoluciones@gmail.com";
  static String ivaPorcentaje = "16";
  static String logoPath = "assets/weblogo.jpg"; // Ruta por defecto para assets
  
  // Variable para almacenar los bytes del logo cargado dinámicamente
  static Uint8List? logoBytes; 
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
  
  Uint8List? _logoBytesSeleccionado;

  @override
  void initState() {
    super.initState();
    _ctrlNombreEmpresa = TextEditingController(text: ConfigFactura.nombreEmpresa);
    _ctrlRifEmpresa = TextEditingController(text: ConfigFactura.rifEmpresa);
    _ctrlDireccion = TextEditingController(text: ConfigFactura.direccionEmpresa);
    _ctrlTelefono = TextEditingController(text: ConfigFactura.telefonoEmpresa);
    _ctrlCorreo = TextEditingController(text: ConfigFactura.correoEmpresa);
    _ctrlIva = TextEditingController(text: ConfigFactura.ivaPorcentaje);
    _logoBytesSeleccionado = ConfigFactura.logoBytes;
  }

  // --- FUNCIÓN PARA CARGAR EL LOGO ---
  Future<void> _seleccionarLogo() async {
    // NOTA: Asegúrate de que 'file_picker' esté correctamente instalado y configurado.
    // En web, esto debería abrir el diálogo de selección del navegador sin problemas.
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.first.bytes != null) {
      setState(() {
        // En web, usamos los 'bytes' del archivo seleccionado
        _logoBytesSeleccionado = result.files.first.bytes;
      });
    }
  }

  void _guardarConfiguracion() {
    setState(() {
      ConfigFactura.nombreEmpresa = _ctrlNombreEmpresa.text;
      ConfigFactura.rifEmpresa = _ctrlRifEmpresa.text;
      ConfigFactura.direccionEmpresa = _ctrlDireccion.text;
      ConfigFactura.telefonoEmpresa = _ctrlTelefono.text;
      ConfigFactura.correoEmpresa = _ctrlCorreo.text;
      ConfigFactura.ivaPorcentaje = _ctrlIva.text;
      ConfigFactura.logoBytes = _logoBytesSeleccionado; // Guardamos la selección en la config global
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("CONFIGURACIÓN Y LOGO ACTUALIZADOS"),
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
          // Se eliminó el padding interno fijo para manejarlo dentro del scroll si es necesario
          decoration: BoxDecoration(
            color: cardBlack,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5), 
                blurRadius: 30,
                offset: const Offset(0, 15),
              )
            ]
          ),
          // SOLUCIÓN AL OVERFLOW: Usar SingleChildScrollView para permitir el desplazamiento
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40), // Padding aplicado dentro del scroll
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Encabezado sin la previsualización pequeña antigua
                const Row(
                  children: [
                    Icon(Icons.settings_suggest, color: Colors.white, size: 32),
                    SizedBox(width: 15),
                    Text(
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
                const Padding(padding: EdgeInsets.symmetric(vertical: 25), child: Divider(color: Colors.white10)),

                // --- NUEVA SECCIÓN DE CARGA DE LOGO REDISEÑADA ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Área de visualización (Cuadrícula)
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: inputFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                        image: _logoBytesSeleccionado != null
                            ? DecorationImage(
                                image: MemoryImage(_logoBytesSeleccionado!),
                                fit: BoxFit.contain, // Ajusta la imagen dentro del cuadro
                              )
                            : null,
                      ),
                      child: _logoBytesSeleccionado == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, color: Colors.white24, size: 40),
                                const SizedBox(height: 10),
                                const Text(
                                  "Sin Logo",
                                  style: TextStyle(color: Colors.white24, fontSize: 12),
                                ),
                              ],
                            )
                          : null,
                    ),
                    const SizedBox(width: 30),
                    // 2. Información y Botón de Carga
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "LOGO DEL DOCUMENTO",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Este logo se utilizará en el encabezado de los presupuestos, órdenes de trabajo y facturas generadas por el sistema.",
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Formatos permitidos: PNG, JPG.",
                            style: TextStyle(color: Colors.white24, fontSize: 12),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _seleccionarLogo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.upload_file),
                            label: const Text("SUBIR IMAGEN", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // --------------------------------------------------

                const SizedBox(height: 35), // Espacio aumentado

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
                // Botón inferior sin overflow
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _guardarConfiguracion,
                    style: ElevatedButton.styleFrom(backgroundColor: brandRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    icon: const Icon(Icons.save_as_rounded),
                    label: const Text("GUARDAR Y SINCRONIZAR DATOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white70, size: 20),
            filled: true, fillColor: inputFill,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: brandRed, width: 2)),
          ),
        ),
      ],
    );
  }
}