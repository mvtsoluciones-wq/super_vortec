import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // DATOS DE EJEMPLO
  final List<Map<String, dynamic>> _notifications = [
    {
      "id": "1",
      "title": "Vehículo Listo",
      "body": "Tu Chevrolet Silverado ha pasado la prueba de calidad. Ya puedes pasar a recogerla.",
      "time": "Hace 5 min",
      "type": "success", 
      "isRead": false,
    },
    {
      "id": "2",
      "title": "Recordatorio de Cita",
      "body": "No olvides tu cita de diagnóstico mañana a las 08:00 AM.",
      "time": "Hace 2 horas",
      "type": "info",
      "isRead": false,
    },
    {
      "id": "3",
      "title": "Pago Confirmado",
      "body": "Hemos recibido tu pago de \$85.00 por el servicio de diagnóstico.",
      "time": "Ayer",
      "type": "success",
      "isRead": true,
    },
    {
      "id": "4",
      "title": "Falla Detectada",
      "body": "El escáner detectó una nueva alerta en el sistema de frenos. Revisa el diagnóstico.",
      "time": "Ayer",
      "type": "alert",
      "isRead": true,
    },
    {
      "id": "5",
      "title": "20% de Descuento",
      "body": "Aprovecha nuestra promo en cambio de aceite sintético solo por esta semana.",
      "time": "15 Ene",
      "type": "promo",
      "isRead": true,
    },
  ];

  // FUNCIÓN PARA ABRIR WHATSAPP
  Future<void> _launchWhatsApp() async {
    const String phoneNumber = "584125508533"; 
    const String message = "Hola, tengo una duda sobre una notificación que recibí en la app Mi Garaje.";
    
    final Uri url = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'No se pudo abrir WhatsApp';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir WhatsApp")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF121212);
    // CORRECCIÓN: Se eliminó la variable 'brandRed' que no se usaba aquí.

    return Scaffold(
      backgroundColor: bgDark,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _launchWhatsApp,
        backgroundColor: Colors.green,
        icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 25),
        label: const Text("Contáctanos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Notificaciones", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white70),
            tooltip: "Marcar todo como leído",
            onPressed: () {
              setState(() {
                for (var n in _notifications) {
                  n['isRead'] = true;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Todo marcado como leído"), duration: Duration(seconds: 1))
              );
            },
          )
        ],
      ),
      body: _notifications.isEmpty 
        ? _buildEmptyState()
        : ListView.builder(
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 80), 
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final item = _notifications[index];
              return _buildNotificationCard(item, index);
            },
          ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item, int index) {
    return Dismissible(
      key: Key(item['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
      ),
      onDismissed: (direction) {
        setState(() {
          _notifications.removeAt(index);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${item['title']} eliminado"), duration: const Duration(seconds: 1)),
        );
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            item['isRead'] = true;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: item['isRead'] ? const Color(0xFF1E1E1E) : const Color(0xFF2C2C2C), 
            borderRadius: BorderRadius.circular(15),
            border: item['isRead'] ? null : Border.all(color: Colors.white12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(item['type']),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['title'], 
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: item['isRead'] ? FontWeight.normal : FontWeight.bold,
                            fontSize: 15
                          )
                        ),
                        Text(item['time'], style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item['body'], 
                      style: TextStyle(color: Colors.grey[400], fontSize: 12, height: 1.4)
                    ),
                  ],
                ),
              ),
              if (!item['isRead'])
                Container(
                  margin: const EdgeInsets.only(left: 10, top: 5),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFFD50000), shape: BoxShape.circle),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'success':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'alert':
        icon = Icons.warning_amber_rounded;
        color = Colors.red;
        break;
      case 'promo':
        icon = Icons.local_offer;
        color = Colors.purpleAccent;
        break;
      default:
        icon = Icons.info;
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[800]),
          const SizedBox(height: 20),
          const Text("Sin notificaciones", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}