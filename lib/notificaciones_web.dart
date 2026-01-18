import 'package:flutter/material.dart';

class NotificacionesWebModule extends StatefulWidget {
  const NotificacionesWebModule({super.key});

  @override
  State<NotificacionesWebModule> createState() => _NotificacionesWebModuleState();
}

class _NotificacionesWebModuleState extends State<NotificacionesWebModule> {
  final TextEditingController _mensajeController = TextEditingController();
  String? _clienteSeleccionado;

  // Colores corporativos
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // Datos de prueba
  final List<String> _clientes = ["Juan Pérez", "Talleres ABC", "María Rodríguez"];
  
  final List<Map<String, String>> _plantillas = [
    {"titulo": "Bienvenida", "msj": "Hola, su vehículo ha sido ingresado exitosamente a Super Vortec. Pronto recibirá el diagnóstico."},
    {"titulo": "Presupuesto Listo", "msj": "Estimado cliente, el presupuesto de su reparación ya está disponible para su aprobación en la sección de documentos."},
    {"titulo": "Reparación Finalizada", "msj": "¡Buenas noticias! Su vehículo está listo para ser retirado. Lo esperamos en el taller."},
    {"titulo": "Retraso de Repuestos", "msj": "Le informamos que estamos a la espera de un repuesto faltante. El tiempo de entrega se extenderá 24 horas."},
  ];

  void _enviarMensaje() {
    if (_clienteSeleccionado == null || _mensajeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("Complete todos los campos"), backgroundColor: brandRed),
      );
      return;
    }
    
    // Simulación de envío a Firebase Cloud Messaging (FCM)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Mensaje enviado a la App del cliente"), backgroundColor: Colors.green),
    );
    _mensajeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PANEL DE REDACCIÓN
              Expanded(
                flex: 2,
                child: _buildRedaccionCard(),
              ),
              const SizedBox(width: 30),
              // PANEL DE PLANTILLAS
              Expanded(
                flex: 1,
                child: _buildPlantillasPanel(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("CENTRO DE MENSAJERÍA PUSH", style: TextStyle(color: brandRed, fontWeight: FontWeight.w900, fontSize: 18)),
        const Text("Envía actualizaciones directas a los dispositivos móviles de tus clientes", style: TextStyle(color: Colors.white24, fontSize: 10)),
      ],
    );
  }

  Widget _buildRedaccionCard() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("DESTINATARIO", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(10)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: cardBlack,
                hint: const Text("Seleccionar Cliente...", style: TextStyle(color: Colors.white24, fontSize: 14)),
                value: _clienteSeleccionado,
                items: _clientes.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (val) => setState(() => _clienteSeleccionado = val),
              ),
            ),
          ),
          const SizedBox(height: 25),
          const Text("MENSAJE", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _mensajeController,
            maxLines: 8,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Escribe el mensaje aquí...",
              hintStyle: const TextStyle(color: Colors.white10),
              filled: true,
              fillColor: inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: brandRed)),
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _enviarMensaje,
              icon: const Icon(Icons.send_rounded),
              label: const Text("ENVIAR NOTIFICACIÓN PUSH", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantillasPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("PLANTILLAS RÁPIDAS", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ..._plantillas.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => setState(() => _mensajeController.text = p['msj']!),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: cardBlack,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: brandRed.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['titulo']!, style: TextStyle(color: brandRed, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(p['msj']!, style: const TextStyle(color: Colors.white38, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }
}