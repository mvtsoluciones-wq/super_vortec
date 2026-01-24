import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientesWebModule extends StatefulWidget {
  const ClientesWebModule({super.key});

  @override
  State<ClientesWebModule> createState() => _ClientesWebModuleState();
}

class _ClientesWebModuleState extends State<ClientesWebModule> {
  String _searchQuery = "";
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);

  // --- 1. FUNCIÓN: ABRIR WHATSAPP (CON LIMPIEZA DE NÚMERO) ---
  Future<void> _abrirWhatsApp(String telefono, String nombre) async {
    String numeroLimpio = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Formateo para Venezuela si el número es local
    if (numeroLimpio.startsWith('0')) {
      numeroLimpio = '58${numeroLimpio.substring(1)}';
    } else if (numeroLimpio.length == 10) {
      numeroLimpio = '58$numeroLimpio';
    }

    final String mensaje = "Hola $nombre, te saludamos de JMendez Performance. ";
    final Uri url = Uri.parse("https://api.whatsapp.com/send?phone=$numeroLimpio&text=${Uri.encodeComponent(mensaje)}");

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir WhatsApp")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al conectar: $e")),
      );
    }
  }

  // --- 2. ELIMINAR REGISTRO COMPLETO ---
  Future<void> _eliminarCliente(String cedula, String nombre) async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBlack,
        title: const Text("¿ELIMINAR REGISTRO?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("Se borrarán los datos de $nombre y sus vehículos asociados."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("BORRAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        var vehiculosQuery = await FirebaseFirestore.instance.collection('vehiculos').where('propietario_id', isEqualTo: cedula).get();
        for (var doc in vehiculosQuery.docs) { await doc.reference.delete(); }
        await FirebaseFirestore.instance.collection('clientes').doc(cedula).delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("REGISTRO ELIMINADO")));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // --- 3. GESTIONAR ACCESO APP ---
  Future<void> _gestionarAcceso(Map<String, dynamic> data, bool estadoActual) async {
    String email = data['email'].toString().trim();
    String clave = data['cedula'].toString().replaceAll(RegExp(r'[^0-9]'), '').trim();
    
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (c) => const Center(child: CircularProgressIndicator(color: Color(0xFFD50000)))
    );

    try {
      if (!estadoActual) {
        try { await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: clave); } 
        on FirebaseAuthException catch (e) { if (e.code != 'email-already-in-use') rethrow; }
        await FirebaseFirestore.instance.collection('clientes').doc(data['cedula']).update({'acceso_app': true, 'rol': 'cliente'});
      } else {
        await FirebaseFirestore.instance.collection('clientes').doc(data['cedula']).update({'acceso_app': false});
      }
      
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showSuccessDialog(!estadoActual ? "ACCESO HABILITADO" : "ACCESO SUSPENDIDO", "Configuración de acceso actualizada.");
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // --- 4. EDICIÓN MAESTRA ---
  void _editMasterData(Map<String, dynamic> clientData) async {
    var vehiculoQuery = await FirebaseFirestore.instance.collection('vehiculos').where('propietario_id', isEqualTo: clientData['cedula']).get();
    if (vehiculoQuery.docs.isEmpty) return;
    if (!mounted) return;
    
    var vDoc = vehiculoQuery.docs.first;
    var vData = vDoc.data();

    final TextEditingController editNombre = TextEditingController(text: clientData['nombre']);
    final TextEditingController editCedula = TextEditingController(text: clientData['cedula']);
    final TextEditingController editEmail = TextEditingController(text: clientData['email']);
    final TextEditingController editTel = TextEditingController(text: clientData['telefono']);
    final TextEditingController editDir = TextEditingController(text: clientData['direccion'] ?? "");
    final TextEditingController editPlaca = TextEditingController(text: vDoc.id);
    final TextEditingController editMarca = TextEditingController(text: vData['marca']);
    final TextEditingController editModelo = TextEditingController(text: vData['modelo']);
    final TextEditingController editColor = TextEditingController(text: vData['color']);
    final TextEditingController editAnio = TextEditingController(text: vData['anio'].toString());
    final TextEditingController editKM = TextEditingController(text: vData['km'].toString());

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardBlack,
          title: const Text("MODIFICAR REGISTRO", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSectionLabel("PERFIL DEL CLIENTE"),
                  Row(children: [Expanded(child: _buildEditField("NOMBRE", editNombre, Icons.person)), const SizedBox(width: 15), Expanded(child: _buildEditField("CÉDULA", editCedula, Icons.badge))]),
                  Row(children: [Expanded(child: _buildEditField("CORREO", editEmail, Icons.email)), const SizedBox(width: 15), Expanded(child: _buildEditField("TELÉFONO", editTel, Icons.phone))]),
                  _buildEditField("DIRECCIÓN", editDir, Icons.location_on),
                  const SizedBox(height: 30),
                  _buildSectionLabel("FICHA DEL VEHÍCULO"),
                  Row(children: [Expanded(child: _buildEditField("PLACA", editPlaca, Icons.pin)), const SizedBox(width: 15), Expanded(child: _buildEditField("MARCA", editMarca, Icons.factory))]),
                  Row(children: [Expanded(child: _buildEditField("MODELO", editModelo, Icons.directions_car)), const SizedBox(width: 15), Expanded(child: _buildEditField("COLOR", editColor, Icons.color_lens))]),
                  Row(children: [Expanded(child: _buildEditField("AÑO", editAnio, Icons.calendar_today)), const SizedBox(width: 15), Expanded(child: _buildEditField("KM ACTUAL", editKM, Icons.speed))]),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("CANCELAR")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brandRed),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogContext);

                String oldCedula = clientData['cedula'];
                String newCedula = editCedula.text.trim();
                String oldPlaca = vDoc.id;
                String newPlaca = editPlaca.text.trim().toUpperCase();

                Map<String, dynamic> cObj = {
                  'nombre': editNombre.text.trim().toUpperCase(),
                  'cedula': newCedula,
                  'email': editEmail.text.trim().toLowerCase(),
                  'telefono': editTel.text.trim(),
                  'direccion': editDir.text.trim().toUpperCase(),
                  'acceso_app': clientData['acceso_app'] ?? false,
                };
                if (newCedula != oldCedula) {
                  await FirebaseFirestore.instance.collection('clientes').doc(newCedula).set(cObj);
                  await FirebaseFirestore.instance.collection('clientes').doc(oldCedula).delete();
                } else { await FirebaseFirestore.instance.collection('clientes').doc(oldCedula).update(cObj); }

                Map<String, dynamic> vObj = {
                  'marca': editMarca.text.trim().toUpperCase(),
                  'modelo': editModelo.text.trim().toUpperCase(),
                  'color': editColor.text.trim().toUpperCase(),
                  'anio': editAnio.text.trim(),
                  'km': editKM.text.trim(),
                  'propietario_id': newCedula,
                };
                if (newPlaca != oldPlaca) {
                  await FirebaseFirestore.instance.collection('vehiculos').doc(newPlaca).set(vObj);
                  await FirebaseFirestore.instance.collection('vehiculos').doc(oldPlaca).delete();
                } else { await FirebaseFirestore.instance.collection('vehiculos').doc(oldPlaca).update(vObj); }

                if (!mounted) return;
                navigator.pop();
                scaffoldMessenger.showSnackBar(const SnackBar(content: Text("DATOS ACTUALIZADOS")));
              },
              child: const Text("GUARDAR CAMBIOS"),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildHeaderStats(), const SizedBox(height: 30), _buildSearchBar(), const SizedBox(height: 20), Expanded(child: _buildClientsList()),
    ]);
  }

  Widget _buildClientsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('clientes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs.where((d) => d['nombre'].toString().toLowerCase().contains(_searchQuery) || d['cedula'].toString().contains(_searchQuery)).toList();
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var client = docs[index].data() as Map<String, dynamic>;
            bool acceso = client['acceso_app'] ?? false;
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
              child: IntrinsicHeight(
                child: Row(children: [
                  Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(client['nombre'].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    _infoRow(Icons.badge, "ID: ${client['cedula']}"),
                    _infoRow(Icons.email, client['email']),
                    _infoRow(Icons.phone, client['telefono']),
                    _infoRow(Icons.location_on, client['direccion'] ?? "SIN DIRECCIÓN", isDim: true),
                  ])),
                  const VerticalDivider(color: Colors.white10, indent: 5, endIndent: 5),
                  Expanded(flex: 5, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 15), child: _buildVehicleDetail(client['cedula']))),
                  Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    ElevatedButton(
                      onPressed: () => _gestionarAcceso(client, acceso),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: acceso ? Colors.green.withValues(alpha: 0.1) : brandRed.withValues(alpha: 0.1), 
                        foregroundColor: acceso ? Colors.green : brandRed, 
                        minimumSize: const Size(120, 35)
                      ),
                      child: Text(acceso ? "ACTIVO" : "SIN ACCESO", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 35, height: 35,
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.green, size: 18),
                            onPressed: () => _abrirWhatsApp(client['telefono'], client['nombre']),
                            tooltip: "WhatsApp",
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(icon: const Icon(Icons.edit_note, color: Colors.blueAccent), onPressed: () => _editMasterData(client)),
                        IconButton(icon: const Icon(Icons.delete_forever, color: Colors.redAccent), onPressed: () => _eliminarCliente(client['cedula'], client['nombre'])),
                      ],
                    )
                  ]),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVehicleDetail(String cedula) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('vehiculos').where('propietario_id', isEqualTo: cedula).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("SIN VEHÍCULO", style: TextStyle(color: Colors.white24, fontSize: 11)));
        var vDoc = snap.data!.docs.first;
        var v = vDoc.data() as Map<String, dynamic>;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("${v['marca']} ${v['modelo']}".toUpperCase(), style: TextStyle(color: brandRed, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _badge(vDoc.id, Colors.orange),
            _badge("AÑO: ${v['anio']}", Colors.blueGrey),
            _badge(v['color'] ?? "COLOR", Colors.white54),
            _badge("${v['km']} KM", Colors.green),
          ]),
        ]);
      },
    );
  }

  // WIDGETS AUXILIARES
  Widget _infoRow(IconData i, String t, {bool isDim = false}) => Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [Icon(i, size: 13, color: isDim ? Colors.white24 : Colors.white54), const SizedBox(width: 10), Expanded(child: Text(t, style: TextStyle(color: isDim ? Colors.white24 : Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis))]));
  Widget _badge(String t, Color c) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5), border: Border.all(color: c.withValues(alpha: 0.2))), child: Text(t.toUpperCase(), style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.bold)));
  Widget _buildSectionLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: TextStyle(color: brandRed, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)), const Divider(color: Colors.white10)]));
  Widget _buildEditField(String l, TextEditingController c, IconData i) => Padding(padding: const EdgeInsets.only(bottom: 15), child: TextField(controller: c, style: const TextStyle(color: Colors.white, fontSize: 13), decoration: InputDecoration(labelText: l, labelStyle: const TextStyle(color: Colors.white38, fontSize: 11), floatingLabelBehavior: FloatingLabelBehavior.always, prefixIcon: Icon(i, color: brandRed, size: 18), filled: true, fillColor: const Color(0xFF161616), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))));
  
  void _showSuccessDialog(String t, String m) { 
    showDialog(
      context: context, 
      builder: (c) => AlertDialog(
        backgroundColor: cardBlack, 
        title: Text(t, style: const TextStyle(color: Colors.white)), 
        content: Text(m, style: const TextStyle(color: Colors.white70)), 
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text("LISTO", style: TextStyle(color: brandRed)))]
      )
    ); 
  }
  
  Widget _buildHeaderStats() { 
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('clientes').snapshots(), 
      builder: (context, snapshot) { 
        int total = snapshot.hasData ? snapshot.data!.docs.length : 0; 
        return Row(children: [_statCard("CLIENTES", total.toString(), Icons.people, Colors.blue), const SizedBox(width: 20), _statCard("SOPORTE", "ACTIVO", Icons.verified, Colors.green)]); 
      }
    ); 
  }
  
  Widget _statCard(String t, String v, IconData i, Color c) => Expanded(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)), child: Row(children: [Icon(i, color: c, size: 28), const SizedBox(width: 18), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: Colors.white38, fontSize: 10)), Text(v, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))])])));
  
  Widget _buildSearchBar() => TextField(onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()), style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Buscar por nombre o cédula...", prefixIcon: Icon(Icons.search, color: brandRed), filled: true, fillColor: cardBlack, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));
}