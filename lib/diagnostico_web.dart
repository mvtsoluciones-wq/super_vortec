import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiagnosticoWebModule extends StatefulWidget {
  const DiagnosticoWebModule({super.key});

  @override
  State<DiagnosticoWebModule> createState() => _DiagnosticoWebModuleState();
}

class _DiagnosticoWebModuleState extends State<DiagnosticoWebModule> {
  final _formKey = GlobalKey<FormState>();
  
  final List<String> _estados = [
    'En Espera',
    'Revisión Inicial',
    'Buscando Repuestos',
    'En Reparación',
    'Pruebas de Ruta',
    'Finalizado'
  ];
  String _estadoActual = 'En Espera';
  double _progresoActual = 10.0;

  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
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
              Text("CONTROL DE DIAGNÓSTICO WEB", 
                style: TextStyle(color: brandRed, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 35),
              
              Row(
                children: [
                  Expanded(flex: 2, child: _buildDropdownField("Estado en la App")),
                  const SizedBox(width: 25),
                  Expanded(flex: 1, child: _buildProgressSlider()),
                ],
              ),
              
              const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Divider(color: Colors.white10)),
              
              _buildDiagnosticoField("Diagnóstico Técnico para el Cliente", Icons.analytics, maxLines: 5),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(child: _buildDiagnosticoField("Lista de Repuestos", Icons.settings_suggest)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildDiagnosticoField("Días Estimados", Icons.timer, isNumber: true)),
                ],
              ),
              const SizedBox(height: 25),
              _buildDiagnosticoField("Presupuesto de Reparación (\$)", Icons.monetization_on, isNumber: true),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("SINCRONIZANDO CON APP MÓVIL..."), backgroundColor: Colors.blue),
                      );
                    }
                  },
                  child: const Text("NOTIFICAR CAMBIOS AL CLIENTE", 
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _estadoActual,
              dropdownColor: cardBlack,
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              items: _estados.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
              onChanged: (newValue) => setState(() => _estadoActual = newValue!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("AVANCE: ${_progresoActual.toInt()}%", 
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        Slider(
          value: _progresoActual,
          min: 0, max: 100, divisions: 10,
          activeColor: brandRed,
          inactiveColor: Colors.white10,
          onChanged: (double value) => setState(() => _progresoActual = value),
        ),
      ],
    );
  }

  Widget _buildDiagnosticoField(String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextFormField(
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: brandRed, size: 20),
            filled: true,
            fillColor: inputFill,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: brandRed, width: 1.5)),
          ),
        ),
      ],
    );
  }
}