import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificacionesScreen extends StatefulWidget {
  final String currentPlaca; 
  
  const NotificacionesScreen({super.key, required this.currentPlaca});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  
  // Función para enviar al usuario a WhatsApp con un mensaje pre-cargado
  Future<void> _contactarTaller(String asunto) async {
    const String telefono = "+584125508533"; // Número del taller
    final String mensaje = "Hola, escribo desde la App respecto a: $asunto";
    
    final Uri url = Uri.parse("https://wa.me/$telefono?text=${Uri.encodeComponent(mensaje)}");

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir WhatsApp")),
        );
      }
    } catch (e) {
      debugPrint("Error abriendo WhatsApp: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF121212);
    
    // Normalizamos la placa para evitar errores de espacios o minúsculas
    String placaFiltro = widget.currentPlaca.trim().toUpperCase();

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        title: Column(
          children: [
            const Text("CENTRO DE MENSAJES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text("Vehículo: $placaFiltro", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notificaciones')
            // Solo trae documentos donde el campo 'placa' sea igual a la del usuario
            .where('placa', isEqualTo: placaFiltro) 
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Manejo de errores
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Error cargando mensajes.\nPosible falta de índice en Firebase.\n\n${snapshot.error}",
                  style: const TextStyle(color: Colors.red, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD50000)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mark_email_unread_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 15),
                  const Text("Buzón limpio", style: TextStyle(color: Colors.white38, fontSize: 16)),
                  const Text("No tienes mensajes nuevos del taller.", style: TextStyle(color: Colors.white12, fontSize: 12)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          // FILTRO LOCAL ADICIONAL:
          // Ocultamos las notificaciones de tipo 'aprobacion' porque esas son 
          // las que el CLIENTE envió al taller. El cliente solo quiere ver lo que el taller le escribe a él.
          final misMensajes = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            String tipo = data['tipo'] ?? '';
            return tipo != 'aprobacion'; 
          }).toList();

          if (misMensajes.isEmpty) {
             return const Center(child: Text("Bandeja vacía", style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: misMensajes.length,
            itemBuilder: (context, index) {
              var data = misMensajes[index].data() as Map<String, dynamic>;
              String docId = misMensajes[index].id;
              
              bool leido = data['leido'] ?? false;
              String titulo = data['titulo'] ?? "Mensaje del Taller";
              String tipo = data['tipo'] ?? 'general';
              
              // Formateo de fecha amigable
              Timestamp? timestamp = data['fecha'];
              String fechaStr = timestamp != null 
                  ? DateFormat('dd MMM, hh:mm a').format(timestamp.toDate()) 
                  : "Reciente";

              // Estilo especial si es un mensaje directo del admin (Chat)
              bool esMensajeDirecto = tipo == 'mensaje_admin';

              return GestureDetector(
                onTap: () {
                  // Al tocar, marcamos como leído en la base de datos
                  if (!leido) {
                    FirebaseFirestore.instance.collection('notificaciones').doc(docId).update({'leido': true});
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    // Si es mensaje directo y no está leído, se ve azul oscuro. Si no, negro tarjeta.
                    color: esMensajeDirecto 
                        ? (leido ? const Color(0xFF1E1E1E) : const Color(0xFF1A237E).withValues(alpha: 0.2)) 
                        : const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      // Borde brillante si no está leído
                      color: !leido 
                          ? (esMensajeDirecto ? Colors.blueAccent : const Color(0xFFD50000)) 
                          : Colors.white10,
                      width: !leido ? 1.5 : 1
                    ),
                    boxShadow: !leido ? [
                       BoxShadow(color: esMensajeDirecto ? Colors.blue.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1), blurRadius: 10)
                    ] : [],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ÍCONO SEGÚN TIPO DE MENSAJE
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: esMensajeDirecto ? Colors.blue.withValues(alpha: 0.1) : Colors.white10,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              esMensajeDirecto ? Icons.support_agent : Icons.info_outline,
                              color: esMensajeDirecto ? Colors.blue : Colors.white70,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      titulo,
                                      style: TextStyle(
                                        color: leido ? Colors.white70 : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15
                                      ),
                                    ),
                                    if (!leido)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: const Color(0xFFD50000), borderRadius: BorderRadius.circular(4)),
                                        child: const Text("NUEVO", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                      )
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  data['mensaje'] ?? "",
                                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  fechaStr,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 15),
                      // BOTÓN DE RESPUESTA RÁPIDA VÍA WHATSAPP
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700], // Verde WhatsApp
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            if (!leido) {
                               FirebaseFirestore.instance.collection('notificaciones').doc(docId).update({'leido': true});
                            }
                            _contactarTaller(titulo);
                          },
                          icon: const Icon(Icons.chat, size: 16),
                          label: const Text("RESPONDER AL TALLER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}