import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  // VARIABLES DE ESTADO
  int _selectedDayIndex = 0;
  int _selectedTimeIndex = -1; // -1: Ninguno, 0: Mañana, 1: Tarde
  String? _selectedService; 
  
  // NUEVA VARIABLE: Vehículo seleccionado
  String? _selectedVehicleId; // Guardaremos el ID o Placa del vehículo seleccionado
  List<Map<String, String>> _userVehicles = []; // Lista de vehículos del usuario

  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  // DATOS
  final List<DateTime> _days = List.generate(7, (index) => DateTime.now().add(Duration(days: index)));
  
  final List<String> _timeSlots = [
    "En la Mañana (8:00 - 12:00)", 
    "En la Tarde (1:00 - 5:00)"
  ];

  final List<String> _serviceTypes = [
    "Diagnóstico General",
    "Mecánica Ligera",
    "Electricidad Automotriz",
    "Aire Acondicionado",
    "Latonería y Pintura"
  ];

  @override
  void initState() {
    super.initState();
    _loadUserVehicles(); // Cargar vehículos al iniciar
  }

  // --- FUNCIÓN PARA CARGAR VEHÍCULOS DEL USUARIO ---
  Future<void> _loadUserVehicles() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. Buscar la cédula del cliente usando su email
        var clienteQuery = await FirebaseFirestore.instance
            .collection('clientes')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (clienteQuery.docs.isNotEmpty) {
          String cedula = clienteQuery.docs.first['cedula'] ?? "";
          
          // 2. Buscar vehículos asociados a esa cédula
          if (cedula.isNotEmpty) {
            var vehiculosQuery = await FirebaseFirestore.instance
                .collection('vehiculos')
                .where('propietario_id', isEqualTo: cedula)
                .get();

            List<Map<String, String>> loadedVehicles = [];
            for (var doc in vehiculosQuery.docs) {
              var data = doc.data();
              String marca = data['marca'] ?? "Marca";
              String modelo = data['modelo'] ?? "Modelo";
              String placa = data['placa'] ?? doc.id; // Usamos ID si no hay placa
              
              loadedVehicles.add({
                'id': placa, // Usaremos la placa como identificador
                'display': "$marca $modelo ($placa)".toUpperCase()
              });
            }

            if (mounted) {
              setState(() {
                _userVehicles = loadedVehicles;
                // Si solo tiene un vehículo, lo seleccionamos automáticamente
                if (_userVehicles.length == 1) {
                  _selectedVehicleId = _userVehicles[0]['id'];
                }
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error cargando vehículos: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandRed = Color(0xFFD50000);
    const Color bgDark = Color(0xFF121212); 
    const Color cardColor = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Agendar Cita", 
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: brandRed))
        : Column(
          children: [
            // 1. CALENDARIO (Horizontal)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _days.length,
                  itemBuilder: (context, index) {
                    final day = _days[index];
                    final isSelected = _selectedDayIndex == index;
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDayIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 15),
                        width: 65,
                        decoration: BoxDecoration(
                          color: isSelected ? brandRed : cardColor,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: isSelected 
                            ? [BoxShadow(color: brandRed.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))]
                            : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getDayName(day.weekday),
                              style: TextStyle(
                                fontSize: 12, 
                                color: isSelected ? Colors.white : Colors.grey[500],
                                fontWeight: FontWeight.w500
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              day.day.toString(),
                              style: TextStyle(
                                fontSize: 22, 
                                fontWeight: FontWeight.bold, 
                                color: isSelected ? Colors.white : Colors.white70
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 2. FORMULARIO EN TARJETA INFERIOR
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                decoration: const BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      // --- NUEVO: SELECTOR DE VEHÍCULO ---
                      const Text("Seleccionar Vehículo", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: _userVehicles.isEmpty ? Colors.red.withValues(alpha: 0.3) : Colors.transparent)
                        ),
                        child: _userVehicles.isEmpty 
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              child: Text("No tienes vehículos registrados", style: TextStyle(color: Colors.grey)),
                            )
                          : DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedVehicleId,
                              hint: Text("Elige tu vehículo...", style: TextStyle(color: Colors.grey[600])),
                              isExpanded: true,
                              dropdownColor: const Color(0xFF2C2C2C),
                              icon: const Icon(Icons.directions_car, color: brandRed),
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              items: _userVehicles.map((vehicle) {
                                return DropdownMenuItem<String>(
                                  value: vehicle['id'],
                                  child: Text(vehicle['display']!),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedVehicleId = newValue;
                                });
                              },
                            ),
                          ),
                      ),
                      if (_userVehicles.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 5, left: 5),
                          child: Text("Contacta al taller para registrar tu vehículo.", style: TextStyle(color: Colors.red[300], fontSize: 11)),
                        ),

                      const SizedBox(height: 25),

                      const Text("Tipo de Servicio", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedService,
                            hint: Text("Seleccione motivo...", style: TextStyle(color: Colors.grey[600])),
                            isExpanded: true,
                            dropdownColor: const Color(0xFF2C2C2C),
                            icon: const Icon(Icons.keyboard_arrow_down, color: brandRed),
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            items: _serviceTypes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedService = newValue;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      const Text("Preferencia de Turno", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Column(
                        children: List.generate(_timeSlots.length, (index) {
                          final isSelected = _selectedTimeIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTimeIndex = index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: isSelected ? brandRed : const Color(0xFF2C2C2C),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: isSelected ? brandRed : Colors.transparent
                                  )
                                ),
                                child: Text(
                                  _timeSlots[index],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey[400],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 25),

                      const Text("Descripción de la Falla", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Ej: Ruido extraño al frenar...",
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(15),
                        ),
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandRed,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 5,
                            shadowColor: brandRed.withValues(alpha: 0.5),
                          ),
                          onPressed: _enviarSolicitud, 
                          child: const Text("ENVIAR SOLICITUD", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  // --- FUNCIÓN PRINCIPAL PARA GUARDAR EN FIREBASE ---
  Future<void> _enviarSolicitud() async {
    // 1. Validaciones
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Selecciona un vehículo"), backgroundColor: Colors.orange));
      return;
    }
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Selecciona un tipo de servicio"), backgroundColor: Colors.orange));
      return;
    }
    if (_selectedTimeIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Selecciona un turno"), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuario no autenticado");

      // Buscar nombre del cliente nuevamente para asegurar datos frescos
      String nombreCliente = "Usuario App";
      String telefonoCliente = "";
      
      var clienteQuery = await FirebaseFirestore.instance
          .collection('clientes')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (clienteQuery.docs.isNotEmpty) {
        var data = clienteQuery.docs.first.data();
        nombreCliente = data['nombre'] ?? "Cliente";
        telefonoCliente = data['telefono'] ?? "";
      }

      // Obtener el string del vehículo seleccionado para guardarlo
      String vehiculoString = _userVehicles.firstWhere((v) => v['id'] == _selectedVehicleId)['display']!;

      // Preparar fecha
      DateTime fechaSeleccionada = _days[_selectedDayIndex];
      DateTime fechaFinal = DateTime(
        fechaSeleccionada.year, 
        fechaSeleccionada.month, 
        fechaSeleccionada.day,
        _selectedTimeIndex == 0 ? 8 : 13, 
        0
      );

      // Guardar en Firestore
      await FirebaseFirestore.instance.collection('citas').add({
        'cliente_id': user.uid,
        'nombre_cliente': nombreCliente,
        'telefono': telefonoCliente,
        'vehiculo': vehiculoString, // Guardamos "MARCA MODELO (PLACA)"
        'vehiculo_placa': _selectedVehicleId, // Guardamos la placa pura también por si acaso
        'motivo': _selectedService,
        'descripcion': _descriptionController.text.trim(),
        'fecha_hora': Timestamp.fromDate(fechaFinal),
        'turno': _timeSlots[_selectedTimeIndex],
        'estado': 'pendiente',
        'creado_en': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showSuccessDialog();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al agendar: $e"), backgroundColor: Colors.red)
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 40),
                ),
                const SizedBox(height: 20),
                const Text("¡Solicitud Enviada!", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  "Hemos recibido tu solicitud para $_selectedService. Te confirmaremos pronto.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD50000),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(context); 
                      Navigator.pop(context); 
                    },
                    child: const Text("ENTENDIDO", style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  String _getDayName(int weekday) {
    const days = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
    return days[weekday - 1];
  }
}