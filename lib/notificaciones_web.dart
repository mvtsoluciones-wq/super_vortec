import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificacionesWebModule extends StatefulWidget {
  const NotificacionesWebModule({super.key});

  @override
  State<NotificacionesWebModule> createState() => _NotificacionesWebModuleState();
}

class _NotificacionesWebModuleState extends State<NotificacionesWebModule> {
  final Color cardBlack = const Color(0xFF101010);
  final Color brandRed = const Color(0xFFD50000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("ALERTAS DE TALLER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notificaciones')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD50000)));

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("Sin actividad reciente", style: TextStyle(color: Colors.white24)));

          return ListView.builder(
            padding: const EdgeInsets.all(25),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              bool leido = data['leido'] ?? false;
              
              // Intentamos recuperar la lista de presupuestos si existe
              List<dynamic> presupuestosIds = data['presupuestos_ids'] ?? [];
              String textoPresupuestos = "";
              if (presupuestosIds.isNotEmpty) {
                textoPresupuestos = presupuestosIds.join(", ");
              }

              return Dismissible(
                key: Key(docs[index].id),
                onDismissed: (_) => FirebaseFirestore.instance.collection('notificaciones').doc(docs[index].id).delete(),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: leido ? cardBlack : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: leido ? Colors.white10 : brandRed.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(20),
                    leading: CircleAvatar(
                      backgroundColor: leido ? Colors.grey[900] : brandRed,
                      child: Icon(Icons.assignment_turned_in, color: Colors.white, size: 20),
                    ),
                    title: Row(
                      children: [
                        Text(
                          data['titulo'] ?? "NOTIFICACIÓN",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const SizedBox(width: 10),
                        // SI HAY PRESUPUESTOS, LOS MOSTRAMOS DESTACADOS
                        if (textoPresupuestos.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: brandRed, borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              "N°: $textoPresupuestos",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          )
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(data['mensaje'] ?? "", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.directions_car, size: 14, color: Colors.white54),
                            const SizedBox(width: 5),
                            Text("PLACA: ${data['placa']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 20),
                            const Icon(Icons.attach_money, size: 14, color: Colors.green),
                            Text("TOTAL: \$${data['monto']}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    trailing: !leido 
                      ? IconButton(
                          icon: const Icon(Icons.mark_email_read, color: Colors.blue),
                          tooltip: "Marcar como leído",
                          onPressed: () => FirebaseFirestore.instance.collection('notificaciones').doc(docs[index].id).update({'leido': true}),
                        )
                      : const Icon(Icons.check, color: Colors.white10),
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