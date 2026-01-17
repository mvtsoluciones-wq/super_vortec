import 'package:flutter/material.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  int _selectedDayIndex = 0;
  int _selectedTimeIndex = -1;
  final TextEditingController _reasonController = TextEditingController();

  final List<DateTime> _days = List.generate(7, (index) => DateTime.now().add(Duration(days: index)));
  final List<String> _timeSlots = ["08:00 AM", "09:00 AM", "10:30 AM", "01:00 PM", "02:30 PM", "04:00 PM"];

  @override
  Widget build(BuildContext context) {
    const Color brandRed = Color(0xFFD50000);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("RESERVAR CITA", style: TextStyle(fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [Color(0xFF1A1A1A), Colors.black],
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("SELECCIONA UNA FECHA", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _days.length,
                    itemBuilder: (context, index) {
                      bool isSelected = _selectedDayIndex == index;
                      DateTime day = _days[index];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDayIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 60,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? brandRed : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: isSelected ? brandRed : Colors.white10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getDayName(day.weekday).toUpperCase(),
                                style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.grey),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                day.day.toString(),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                const Text("HORARIOS DISPONIBLES", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(_timeSlots.length, (index) {
                    bool isSelected = _selectedTimeIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTimeIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? Colors.white : Colors.white24),
                        ),
                        child: Text(
                          _timeSlots[index],
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 30),
                const Text("MOTIVO DE LA VISITA", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Ej: Ruido en la suspensión delantera...",
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandRed,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 10,
                shadowColor: brandRed.withValues(alpha: 0.5),
              ),
              onPressed: () {
                if (_selectedTimeIndex == -1) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor selecciona una hora")));
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("¡Solicitud enviada! Te contactaremos pronto."),
                    backgroundColor: Colors.green,
                  )
                );
              },
              child: const Text("CONFIRMAR CITA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          )
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
    return days[weekday - 1];
  }
}