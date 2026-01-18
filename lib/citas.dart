import 'package:flutter/material.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  // VARIABLES DE ESTADO
  int _selectedDayIndex = 0;
  int _selectedTimeIndex = -1;
  String? _selectedService; 
  bool _hasAttachedFiles = false; 
  final TextEditingController _descriptionController = TextEditingController();

  // DATOS
  final List<DateTime> _days = List.generate(7, (index) => DateTime.now().add(Duration(days: index)));
  
  final List<String> _timeSlots = [
    "En la Mañana", 
    "En la Tarde"
  ];

  final List<String> _serviceTypes = [
    "Diagnóstico",
    "Reparación",
    "Latonería y Pintura"
  ];

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
      body: Column(
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
                    Row(
                      children: List.generate(_timeSlots.length, (index) {
                        final isSelected = _selectedTimeIndex == index;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTimeIndex = index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  color: isSelected ? brandRed : const Color(0xFF2C2C2C),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: isSelected ? brandRed : Colors.transparent
                                  )
                                ),
                                child: Center(
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

                    const SizedBox(height: 25),

                    const Text("Evidencia (Fotos/Videos)", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _hasAttachedFiles = !_hasAttachedFiles;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_hasAttachedFiles ? "Archivos adjuntados" : "Archivos eliminados"),
                            duration: const Duration(seconds: 1),
                          )
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: _hasAttachedFiles ? Colors.green : Colors.white24, style: BorderStyle.solid),
                        ),
                        child: _hasAttachedFiles 
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 30),
                                const SizedBox(height: 5),
                                const Text("3 Archivos listos para enviar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text("Toque para cambiar", style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cloud_upload_outlined, color: brandRed, size: 30),
                                const SizedBox(height: 5),
                                const Text("Toque para subir archivos", style: TextStyle(color: Colors.white70)),
                                Text("Formatos: JPG, PNG, MP4", style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                              ],
                            ),
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
                        onPressed: _showSuccessDialog, 
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

  void _showSuccessDialog() {
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Selecciona un tipo de servicio"), backgroundColor: Colors.orange));
      return;
    }
    if (_selectedTimeIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Selecciona un turno"), backgroundColor: Colors.orange));
      return;
    }

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
                
                // CORRECCIÓN REALIZADA AQUÍ: Se eliminaron las llaves {} en la interpolación
                Text(
                  "Hemos recibido tu solicitud de $_selectedService para el turno de la ${_timeSlots[_selectedTimeIndex].toLowerCase()}.",
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