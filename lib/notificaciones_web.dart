import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificacionesWebModule extends StatefulWidget {
  const NotificacionesWebModule({super.key});

  @override
  State<NotificacionesWebModule> createState() => _NotificacionesWebModuleState();
}

class _NotificacionesWebModuleState extends State<NotificacionesWebModule> {
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // Controlador para respuestas rápidas
  final TextEditingController _mensajeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("CENTRO DE MENSAJES Y ALERTAS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        actions: [
          // Botón para enviar un mensaje nuevo desde cero
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            tooltip: "Redactar Mensaje Nuevo",
            onPressed: () => _mostrarDialogoResponder(context, "", ""),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notificaciones')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD50000)));

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mark_email_unread_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 20),
                  const Text("Bandeja de entrada vacía", style: TextStyle(color: Colors.white24)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(25),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String docId = docs[index].id;
              
              bool leido = data['leido'] ?? false;
              String tipo = data['tipo'] ?? 'general';
              String placa = data['placa'] ?? 'General';
              String presupuestoInfo = data['numero_presupuesto'] ?? '';

              // Determinamos colores e iconos según el tipo de mensaje
              Color colorBorde = Colors.white10;
              IconData icono = Icons.notifications;
              Color colorIcono = brandRed;

              if (tipo == 'aprobacion') {
                colorBorde = Colors.green.withValues(alpha: 0.5);
                icono = Icons.check_circle;
                colorIcono = Colors.green;
              } else if (tipo == 'mensaje_cliente') {
                colorBorde = Colors.blue.withValues(alpha: 0.5);
                icono = Icons.message;
                colorIcono = Colors.blue;
              } else if (tipo == 'mensaje_admin') {
                 // Mensajes que nosotros enviamos
                 colorBorde = Colors.grey.withValues(alpha: 0.3);
                 icono = Icons.outbound;
                 colorIcono = Colors.grey;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: leido ? cardBlack : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: !leido ? colorBorde : Colors.white10, width: !leido ? 1.5 : 1),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
                      leading: CircleAvatar(
                        backgroundColor: colorIcono.withValues(alpha: 0.2),
                        child: Icon(icono, color: colorIcono, size: 20),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              data['titulo'] ?? "NOTIFICACIÓN",
                              style: TextStyle(
                                color: leido ? Colors.white70 : Colors.white, 
                                fontWeight: FontWeight.w900, 
                                fontSize: 16
                              ),
                            ),
                          ),
                          if (presupuestoInfo.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: brandRed, borderRadius: BorderRadius.circular(4)),
                              child: Text("N° $presupuestoInfo", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(data['mensaje'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _infoBadge("PLACA: $placa", Colors.blue),
                              const SizedBox(width: 10),
                              if (data['monto'] != null)
                                _infoBadge("MONTO: \$${data['monto']}", Colors.green),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // BARRA DE ACCIONES (RESPONDER / LEER / BORRAR)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12))
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // 1. BOTÓN RESPONDER (CHAT)
                          TextButton.icon(
                            onPressed: () => _mostrarDialogoResponder(context, placa, docId),
                            icon: const Icon(Icons.reply, size: 18, color: Colors.blueAccent),
                            label: const Text("RESPONDER", style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          
                          // 2. BOTÓN MARCAR LEÍDO
                          if (!leido)
                            TextButton.icon(
                              onPressed: () => FirebaseFirestore.instance.collection('notificaciones').doc(docId).update({'leido': true}),
                              icon: const Icon(Icons.mark_email_read, size: 18, color: Colors.white70),
                              label: const Text("LEÍDO", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ),

                          const Spacer(),

                          // 3. BOTÓN ELIMINAR (CON CONFIRMACIÓN)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            tooltip: "Eliminar mensaje",
                            onPressed: () => _confirmarEliminacion(context, docId),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _infoBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  // --- FUNCIONES DE LÓGICA ---

  // 1. Diálogo para escribir respuesta
  void _mostrarDialogoResponder(BuildContext context, String placaDestino, String docIdReferencia) {
    _mensajeController.clear();
    // Si viene de una placa, pre-llenamos (si no, el admin debe escribirla)
    final TextEditingController placaController = TextEditingController(text: placaDestino);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: inputFill,
        title: const Text("Enviar Mensaje al Cliente", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: placaController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "PLACA DEL VEHÍCULO",
                labelStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.directions_car, color: Colors.blue),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _mensajeController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "MENSAJE",
                hintText: "Ej: Su repuesto ha llegado...",
                labelStyle: TextStyle(color: Colors.grey),
                hintStyle: TextStyle(color: Colors.white12),
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            icon: const Icon(Icons.send, color: Colors.white, size: 16),
            label: const Text("ENVIAR", style: TextStyle(color: Colors.white)),
            onPressed: () {
              if (placaController.text.isNotEmpty && _mensajeController.text.isNotEmpty) {
                _enviarMensaje(placaController.text.toUpperCase(), _mensajeController.text);
                Navigator.pop(ctx);
                // Si respondemos a un mensaje específico, lo marcamos como leído automáticamente
                if (docIdReferencia.isNotEmpty) {
                  FirebaseFirestore.instance.collection('notificaciones').doc(docIdReferencia).update({'leido': true});
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // 2. Función para guardar el mensaje en Firebase
Future<void> _enviarMensaje(String placa, String mensaje) async {
    try {
      await FirebaseFirestore.instance.collection('notificaciones').add({
        'titulo': 'MENSAJE DE TALLER', // Título que verá el cliente
        'mensaje': mensaje,
        'placa': placa, // CLAVE: Esto direcciona el mensaje al cliente correcto
        'tipo': 'mensaje_admin', // CLAVE: Identifica que viene del Taller
        'fecha': FieldValue.serverTimestamp(),
        'leido': false,
        'remitente': 'admin', // Para diferenciar quién escribió
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mensaje enviado al cliente"), backgroundColor: Colors.blue));
    } catch (e) {
      debugPrint("Error enviando mensaje: $e");
    }
  }

  // 3. Confirmación de Eliminación
  void _confirmarEliminacion(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBlack,
        title: const Text("¿Eliminar Notificación?", style: TextStyle(color: Colors.white)),
        content: const Text("Esta acción no se puede deshacer.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandRed),
            onPressed: () {
              FirebaseFirestore.instance.collection('notificaciones').doc(docId).delete();
              Navigator.pop(ctx);
            },
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}