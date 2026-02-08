import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class CitasWebModule extends StatefulWidget {
  const CitasWebModule({super.key});

  @override
  State<CitasWebModule> createState() => _CitasWebModuleState();
}

class _CitasWebModuleState extends State<CitasWebModule> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _vehiculoController = TextEditingController();
  final _motivoController = TextEditingController();
  String _turnoManual = "En la Mañana (8:00 - 12:00)";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _vehiculoController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  int _daysInMonth(DateTime date) => DateTime(date.year, date.month + 1, 0).day;

  int _firstDayOffset(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday - 1;
  }

  void _changeMonth(int increment) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + increment);
    });
  }

  Future<void> _enviarNotificacionApp(String placa, String titulo, String mensaje) async {
    if (placa == 'MANUAL' || placa.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Cita manual: No se puede enviar notificación a App (Sin Placa)")));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('notificaciones').add({
        'titulo': titulo,
        'mensaje': mensaje,
        'placa': placa,
        'fecha': FieldValue.serverTimestamp(),
        'leido': false,
        'tipo': 'cita',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [const Icon(Icons.notifications_active, color: Colors.white), const SizedBox(width: 10), Text("Notificación enviada a $placa")]),
        backgroundColor: Colors.blueAccent,
      ));
    } catch (e) {
      debugPrint("Error enviando notificación: $e");
    }
  }

  Future<void> _guardarCitaManual() async {
    if (_nombreController.text.isEmpty || _vehiculoController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nombre y Vehículo son obligatorios")));
      return;
    }

    try {
      DateTime fechaHora = DateTime(
        _selectedDate.year, 
        _selectedDate.month, 
        _selectedDate.day, 
        _turnoManual.contains("Mañana") ? 9 : 14, 
        0
      );

      await FirebaseFirestore.instance.collection('citas').add({
        'cliente_id': 'manual_admin',
        'nombre_cliente': _nombreController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'vehiculo': _vehiculoController.text.trim(),
        'vehiculo_placa': 'MANUAL',
        'motivo': _motivoController.text.trim().isEmpty ? "Servicio General" : _motivoController.text.trim(),
        'descripcion': "Cita agendada manualmente en el taller",
        'fecha_hora': Timestamp.fromDate(fechaHora),
        'turno': _turnoManual,
        'estado': 'confirmada',
        'creado_en': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _nombreController.clear();
      _telefonoController.clear();
      _vehiculoController.clear();
      _motivoController.clear();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Cita manual registrada"), backgroundColor: Colors.green));
      _tabController.animateTo(0);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _actualizarEstado(String docId, String nuevoEstado, String placa, DateTime fechaCita) async {
    await FirebaseFirestore.instance.collection('citas').doc(docId).update({'estado': nuevoEstado});
    
    String fechaStr = DateFormat('dd/MM', 'es_ES').format(fechaCita);
    
    if (nuevoEstado == 'confirmada') {
      _enviarNotificacionApp(placa, "¡Cita Confirmada!", "Te esperamos el $fechaStr. Gracias por confiar en nosotros.");
    } else if (nuevoEstado == 'cancelada') {
      _enviarNotificacionApp(placa, "Cita Cancelada", "Tu cita del $fechaStr no pudo ser procesada. Contáctanos.");
    }
  }

  Future<void> _reprogramarCita(BuildContext context, String docId, DateTime currentFecha, String placa) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentFecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD50000), 
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            // CORRECCIÓN 1: Se usa DialogThemeData para evitar el error de tipo de argumento
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF121212),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != currentFecha) {
      final newDateTime = DateTime(picked.year, picked.month, picked.day, currentFecha.hour, currentFecha.minute);
      
      try {
        await FirebaseFirestore.instance.collection('citas').doc(docId).update({
          'fecha_hora': Timestamp.fromDate(newDateTime),
        });

        String nuevaFechaStr = DateFormat('dd/MM/yyyy', 'es_ES').format(newDateTime);
        
        await _enviarNotificacionApp(
          placa, 
          "Cita Reprogramada", 
          "Debido a disponibilidad, tu cita ha sido movida para el $nuevaFechaStr. ¡Gracias por tu comprensión!"
        );

        // CORRECCIÓN 2: Validación de seguridad para usar el contexto después de una operación asíncrona
        if (!context.mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("📅 Cita reprogramada exitosamente"), backgroundColor: Colors.blue));

      } catch (e) {
        debugPrint("Error al reprogramar: $e");
      }
    }
  }

  Future<void> _abrirWhatsApp(String telefono, String? clienteId) async {
    String numberToUse = telefono;

    if (numberToUse.isEmpty && clienteId != null && clienteId != 'manual_admin') {
      try {
        var doc = await FirebaseFirestore.instance.collection('clientes').doc(clienteId).get();
        if (doc.exists) {
           numberToUse = doc.data()?['telefono'] ?? "";
        }
      } catch (e) {
        debugPrint("Error buscando teléfono extra: $e");
      }
    }

    if (numberToUse.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ No hay número de teléfono registrado")));
      return;
    }

    String cleanNumber = numberToUse.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.startsWith('0')) {
      cleanNumber = "58${cleanNumber.substring(1)}";
    }

    var url = Uri.parse("https://wa.me/$cleanNumber");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("No se pudo abrir WhatsApp: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF121212);
    const cardColor = Color(0xFF1E1E1E);
    const brandRed = Color(0xFFD50000);

    return Scaffold(
      backgroundColor: bgDark,
      body: Row(
        children: [
          Container(
            width: 350,
            color: const Color(0xFF181818),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("CALENDARIO DE TRABAJO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: () => _changeMonth(-1)),
                    Text(DateFormat('MMMM yyyy', 'es_ES').format(_focusedMonth).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white), onPressed: () => _changeMonth(1)),
                  ],
                ),
                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ["L", "M", "M", "J", "V", "S", "D"].map((day) => 
                    SizedBox(
                      width: 30, 
                      child: Text(day, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))
                    )
                  ).toList(),
                ),
                const SizedBox(height: 10),

                Expanded(
                  flex: 2,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('citas').snapshots(),
                    builder: (context, snapshot) {
                      Map<int, int> citasPorDia = {};
                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          Timestamp? ts = doc['fecha_hora'];
                          if (ts != null) {
                            DateTime date = ts.toDate();
                            if (date.year == _focusedMonth.year && date.month == _focusedMonth.month) {
                              citasPorDia[date.day] = (citasPorDia[date.day] ?? 0) + 1;
                            }
                          }
                        }
                      }

                      int daysInMonth = _daysInMonth(_focusedMonth);
                      int offset = _firstDayOffset(_focusedMonth);

                      return GridView.builder(
                        itemCount: daysInMonth + offset,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                        itemBuilder: (context, index) {
                          if (index < offset) return const SizedBox();

                          int dayNum = index - offset + 1;
                          DateTime currentDayDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                          bool isSelected = currentDayDate.year == _selectedDate.year && currentDayDate.month == _selectedDate.month && currentDayDate.day == _selectedDate.day;
                          int count = citasPorDia[dayNum] ?? 0;

                          return GestureDetector(
                            onTap: () => setState(() => _selectedDate = currentDayDate),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isSelected ? brandRed : (count > 0 ? cardColor : Colors.transparent),
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected ? null : Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("$dayNum", style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
                                  if (count > 0)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      width: 6, height: 6,
                                      decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.blue, shape: BoxShape.circle),
                                    )
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const Divider(color: Colors.white12),
                
                Text("Resumen para el ${DateFormat('dd/MM').format(_selectedDate)}", style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('citas').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    
                    int delDia = 0;
                    int pendientes = 0;
                    
                    for (var doc in snapshot.data!.docs) {
                      Timestamp? ts = doc['fecha_hora'];
                      if (ts != null) {
                        DateTime d = ts.toDate();
                        if (d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day) {
                          delDia++;
                          if (doc['estado'] == 'pendiente') pendientes++;
                        }
                      }
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniStat("Total", "$delDia", Colors.blue),
                        _buildMiniStat("Pendientes", "$pendientes", Colors.orange),
                      ],
                    );
                  },
                )
              ],
            ),
          ),

          Expanded(
            child: Column(
              children: [
                Container(
                  color: cardColor,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: brandRed,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(icon: Icon(Icons.app_shortcut), text: "SOLICITUDES APP"),
                      Tab(icon: Icon(Icons.edit_note), text: "AGENDAR MANUAL"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCitasList(bgDark),
                      _buildManualForm(bgDark, cardColor, brandRed),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitasList(Color bgDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('citas').orderBy('fecha_hora').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs.where((doc) {
          Timestamp? ts = doc['fecha_hora'];
          if (ts == null) return false;
          DateTime d = ts.toDate();
          return d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day;
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 60, color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(height: 10),
                const Text("No hay citas para este día", style: TextStyle(color: Colors.white38)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            
            String placa = data['vehiculo_placa'] ?? 'MANUAL';
            Timestamp? ts = data['fecha_hora'];
            DateTime fechaCita = ts != null ? ts.toDate() : DateTime.now();
            String fechaStr = DateFormat('dd/MM', 'es_ES').format(fechaCita);
            String telefono = data['telefono'] ?? "";
            String clienteId = data['cliente_id'] ?? "";

            return Card(
              color: const Color(0xFF1E1E1E),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: data['cliente_id'] == 'manual_admin' ? Colors.blue.withValues(alpha: 0.2) : Colors.purple.withValues(alpha: 0.2),
                  child: Icon(
                    data['cliente_id'] == 'manual_admin' ? Icons.person : Icons.phone_android, 
                    color: Colors.white
                  ),
                ),
                title: Text(data['nombre_cliente'] ?? "Cliente", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${data['vehiculo']} - ${data['motivo']}", style: const TextStyle(color: Colors.white70)),
                    Text("Turno: ${data['turno']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_calendar, color: Colors.blueAccent),
                      tooltip: "Reprogramar Fecha",
                      onPressed: () => _reprogramarCita(context, docs[index].id, fechaCita, placa),
                    ),

                    IconButton(
                      icon: const Icon(Icons.notifications_active_outlined, color: Colors.orange),
                      tooltip: "Enviar Recordatorio",
                      onPressed: () => _enviarNotificacionApp(
                        placa, 
                        "Recordatorio de Cita", 
                        "Hola, recuerda tu cita programada para el $fechaStr. ¡Te esperamos!"
                      ),
                    ),

                    if (data['estado'] == 'pendiente') ...[
                      IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _actualizarEstado(docs[index].id, 'confirmada', placa, fechaCita), tooltip: "Confirmar"),
                      IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _actualizarEstado(docs[index].id, 'cancelada', placa, fechaCita), tooltip: "Rechazar"),
                    ] else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: data['estado'] == 'confirmada' ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4)
                        ),
                        child: Text(data['estado'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    const SizedBox(width: 10),
                    IconButton(icon: const Icon(Icons.chat, color: Colors.green), onPressed: () => _abrirWhatsApp(telefono, clienteId)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildManualForm(Color bgDark, Color cardColor, Color brandRed) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AGENDAR NUEVA CITA MANUAL", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Text("Esta cita se guardará automáticamente como confirmada.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          
          _buildInput(_nombreController, "Nombre del Cliente", Icons.person),
          const SizedBox(height: 15),
          _buildInput(_telefonoController, "Teléfono (WhatsApp)", Icons.phone),
          const SizedBox(height: 15),
          _buildInput(_vehiculoController, "Vehículo (Marca Modelo)", Icons.directions_car),
          const SizedBox(height: 15),
          _buildInput(_motivoController, "Motivo / Falla", Icons.build),
          const SizedBox(height: 15),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(10)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _turnoManual,
                dropdownColor: const Color(0xFF2C2C2C),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: "En la Mañana (8:00 - 12:00)", child: Text("Mañana (8am - 12pm)")),
                  DropdownMenuItem(value: "En la Tarde (1:00 - 5:00)", child: Text("Tarde (1pm - 5pm)")),
                ], 
                onChanged: (val) => setState(() => _turnoManual = val!),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: brandRed),
              onPressed: _guardarCitaManual,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text("GUARDAR CITA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}