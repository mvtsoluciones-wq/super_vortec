import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io'; // Necesario para manejo de archivos locales
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart'; // Librería de almacenamiento local

// --- CLASE DE DATOS GLOBAL ---
class ConfigFactura {
  static String nombreEmpresa = "MENDEZ Y VEGAS TELECOMUNICACIONES C.A.";
  static String rifEmpresa = "J-29799471-8";
  static String direccionEmpresa = "Av. Trujillo, Edif. Bloque 2, Letra B, Piso 2, Caracas";
  static String telefonoEmpresa = "(0212) 639.04.57";
  static String correoEmpresa = "mvtsoluciones@gmail.com";
  static String ivaPorcentaje = "16";
  static String logoPath = "assets/weblogo.jpg";
  
  static String? logoBase64; 
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
  bool _isLoading = true;

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

    _cargarConfiguracionDesdeDB(); 
  }

  // --- NUEVA FUNCIÓN: GUARDAR FÍSICAMENTE EN EL DISCO DURO ---
  Future<void> _guardarLogoLocalmente(Uint8List bytes) async {
    try {
      final directorio = await getApplicationDocumentsDirectory();
      final archivoLocal = File('${directorio.path}/logo_taller_vortec.png');
      await archivoLocal.writeAsBytes(bytes);
      debugPrint("Caché local actualizado en: ${archivoLocal.path}");
    } catch (e) {
      debugPrint("Error guardando caché local: $e");
    }
  }

  // --- NUEVA FUNCIÓN: BUSCAR LOGO EN EL DISCO DURO ANTES QUE EN LA NUBE ---
  Future<void> _intentarCargarLogoLocal() async {
    try {
      final directorio = await getApplicationDocumentsDirectory();
      final archivoLocal = File('${directorio.path}/logo_taller_vortec.png');
      if (await archivoLocal.exists()) {
        final bytes = await archivoLocal.readAsBytes();
        setState(() {
          _logoBytesSeleccionado = bytes;
          ConfigFactura.logoBytes = bytes;
          ConfigFactura.logoBase64 = base64Encode(bytes);
        });
        debugPrint("Logo cargado desde memoria local (Instantáneo)");
      }
    } catch (e) {
      debugPrint("Error cargando caché local: $e");
    }
  }

  Future<void> _cargarConfiguracionDesdeDB() async {
    // Primero intentamos la carga rápida local
    await _intentarCargarLogoLocal();

    try {
      var doc = await FirebaseFirestore.instance.collection('configuracion').doc('factura').get();
      if (doc.exists) {
        var data = doc.data()!;
        setState(() {
          _ctrlNombreEmpresa.text = data['nombreEmpresa'] ?? ConfigFactura.nombreEmpresa;
          _ctrlRifEmpresa.text = data['rifEmpresa'] ?? ConfigFactura.rifEmpresa;
          _ctrlDireccion.text = data['direccion'] ?? ConfigFactura.direccionEmpresa;
          _ctrlTelefono.text = data['telefono'] ?? ConfigFactura.telefonoEmpresa;
          _ctrlCorreo.text = data['email'] ?? ConfigFactura.correoEmpresa;
          _ctrlIva.text = data['iva'] ?? ConfigFactura.ivaPorcentaje;
          
          if (data['logoBase64'] != null) {
            ConfigFactura.logoBase64 = data['logoBase64'];
            Uint8List bytesDecodificados = base64Decode(data['logoBase64']);
            _logoBytesSeleccionado = bytesDecodificados;
            ConfigFactura.logoBytes = bytesDecodificados;
            
            // Actualizamos la copia local para que la próxima vez sea instantáneo
            _guardarLogoLocalmente(bytesDecodificados);
          }
        });
      }
    } catch (e) {
      debugPrint("Error al cargar config: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _seleccionarLogo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.first.bytes != null) {
      if (result.files.first.size > 2000000) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ LA IMAGEN ES MUY PESADA. USA EL LOGO REDIMENSIONADO."), backgroundColor: Colors.orange),
        );
      }
      setState(() {
        _logoBytesSeleccionado = result.files.first.bytes;
      });
    }
  }

  void _guardarConfiguracion() async {
    String? base64Image;

    if (_logoBytesSeleccionado != null) {
      String tempBase64 = base64Encode(_logoBytesSeleccionado!);
      
      if (tempBase64.length > 1000000) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ ERROR: LOGO MUY GRANDE PARA LA NUBE."), backgroundColor: Colors.red),
        );
        return; 
      }
      base64Image = tempBase64;
      // Guardamos localmente para velocidad instantánea
      await _guardarLogoLocalmente(_logoBytesSeleccionado!);
    }

    try {
      await FirebaseFirestore.instance.collection('configuracion').doc('factura').set({
        'nombreEmpresa': _ctrlNombreEmpresa.text,
        'rifEmpresa': _ctrlRifEmpresa.text,
        'direccion': _ctrlDireccion.text,
        'telefono': _ctrlTelefono.text,
        'email': _ctrlCorreo.text,
        'iva': _ctrlIva.text,
        'logoBase64': base64Image, 
      }, SetOptions(merge: true));

      setState(() {
        ConfigFactura.nombreEmpresa = _ctrlNombreEmpresa.text;
        ConfigFactura.logoBytes = _logoBytesSeleccionado;
        ConfigFactura.logoBase64 = base64Image;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ DATOS SINCRONIZADOS (NUBE Y LOCAL)"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ ERROR AL GUARDAR: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD50000)));
    }

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 850),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  "Los cambios se guardan localmente para carga rápida de PDFs y en la nube para respaldo.",
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 25), child: Divider(color: Colors.white10)),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150, height: 150,
                      decoration: BoxDecoration(
                        color: inputFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                        image: _logoBytesSeleccionado != null
                            ? DecorationImage(image: MemoryImage(_logoBytesSeleccionado!), fit: BoxFit.contain)
                            : null,
                      ),
                      child: _logoBytesSeleccionado == null
                          ? const Icon(Icons.add_photo_alternate_outlined, color: Colors.white24, size: 40)
                          : null,
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("LOGO DEL TALLER", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          const Text("Se guardará una copia en esta PC para que los presupuestos carguen al instante.", style: TextStyle(color: Colors.white54, fontSize: 13)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _seleccionarLogo,
                            style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white),
                            icon: const Icon(Icons.upload_file),
                            label: const Text("SUBIR IMAGEN"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 35),

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
                  width: double.infinity, height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _guardarConfiguracion,
                    style: ElevatedButton.styleFrom(backgroundColor: brandRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    icon: const Icon(Icons.cloud_sync),
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
          controller: controller, maxLines: maxLines,
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