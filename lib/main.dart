import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; 

import 'firebase_options.dart';

// --- IMPORTACIONES DE TUS PANTALLAS ---
import 'admin_panel.dart';
import 'citas.dart';
import 'diagnostico.dart';
import 'notificaciones.dart';
import 'tienda.dart';
import 'ofertas.dart';
import 'market.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const SuperVortecApp());
}

// CONTROLADOR GLOBAL DEL TEMA
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

class SuperVortecApp extends StatelessWidget {
  const SuperVortecApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Mi Garaje',
          themeMode: mode,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFFD50000),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFFD50000),
            scaffoldBackgroundColor: Colors.black,
            useMaterial3: true,
          ),
          home: const AuthWrapper(),
        );
      },
    );
  }
}

// --- GUARDIÁN DE INACTIVIDAD ---
class SessionTimeoutGuard extends StatefulWidget {
  final Widget child;
  const SessionTimeoutGuard({super.key, required this.child});

  @override
  State<SessionTimeoutGuard> createState() => _SessionTimeoutGuardState();
}

class _SessionTimeoutGuardState extends State<SessionTimeoutGuard> {
  Timer? _timer;
  final Duration _timeLimit = const Duration(minutes: 10);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(_timeLimit, _logoutUser);
  }

  void _resetTimer() {
    _startTimer();
  }

  Future<void> _logoutUser() async {
    if (FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sesión cerrada por inactividad."),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      onPointerHover: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}

// --- VIGILANTE DE SESIÓN ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFD50000)),
            ),
          );
        }
        if (snapshot.hasData) {
          return const SessionTimeoutGuard(
            child: PlatformGuard(),
          );
        }
        return const LoginScreen();
      },
    );
  }
}

class PlatformGuard extends StatelessWidget {
  const PlatformGuard({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (kIsWeb) {
      if (screenWidth > 1000) {
        return const AdminControlPanel();
      }
      return const WebBlockedScreen();
    }
    return const ClientHomeScreen();
  }
}

class WebBlockedScreen extends StatelessWidget {
  const WebBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phonelink_lock, color: Color(0xFFD50000), size: 100),
            const SizedBox(height: 30),
            const Text("APP NO DISPONIBLE EN WEB", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text("Cerrar Sesión", style: TextStyle(color: Colors.white54))),
          ],
        ),
      ),
    );
  }
}

// --- CLIENT HOME SCREEN ---
class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.90);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- FUNCIONES AUXILIARES ---

  String _formatDate(dynamic date) {
    if (date == null) return "Pendiente";
    if (date is Timestamp) {
      DateTime dt = date.toDate();
      return "${dt.day}/${dt.month}/${dt.year}";
    }
    return date.toString();
  }

  String _calculateRemainingWarranty(dynamic fechaFin, String? garantia) {
    if (fechaFin == null || fechaFin is! Timestamp || garantia == null || garantia.isEmpty) return "-";
    
    DateTime fecha = fechaFin.toDate();
    DateTime now = DateTime.now();
    
    final numberMatch = RegExp(r'(\d+)').firstMatch(garantia);
    if (numberMatch == null) return "-"; 
    
    int amount = int.parse(numberMatch.group(1)!);
    DateTime expiryDate = fecha;
    String g = garantia.toUpperCase();
    
    if (g.contains("MES")) {
      expiryDate = DateTime(fecha.year, fecha.month + amount, fecha.day);
    } else if (g.contains("DIA") || g.contains("DÍA")) {
      expiryDate = fecha.add(Duration(days: amount));
    } else if (g.contains("ANO") || g.contains("AÑO")) {
      expiryDate = DateTime(fecha.year + amount, fecha.month, fecha.day);
    } else {
      return "-"; 
    }
    
    int daysLeft = expiryDate.difference(now).inDays;
    if (daysLeft < 0) return "Vencida";
    return "$daysLeft Días";
  }

  String _calculateElapsed(dynamic fechaFin) {
    if (fechaFin == null || fechaFin is! Timestamp) return "En curso";
    DateTime fecha = fechaFin.toDate();
    DateTime now = DateTime.now();
    Duration diff = now.difference(fecha);
    
    if (diff.inDays > 365) return "${(diff.inDays / 365).floor()} Año(s)";
    if (diff.inDays > 30) return "${(diff.inDays / 30).floor()} Mes(es)";
    if (diff.inDays > 0) return "${diff.inDays} Días";
    return "Hoy";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const Color brandRed = Color(0xFFD50000);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey : Colors.grey[700];

    if (user == null) return const Scaffold(body: Center(child: Text("Error de sesión")));

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(isDark, user.email ?? "Usuario"),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'MI GARAJE',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3.0, fontSize: 18, color: textColor),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: isDark ? Colors.amber : Colors.indigo),
            onPressed: () {
              themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: isDark
                  ? const RadialGradient(center: Alignment(0, -0.3), radius: 1.2, colors: [Color(0xFF252525), Colors.black])
                  : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFEEEEEE)]),
            ),
          ),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('clientes').where('email', isEqualTo: user.email).limit(1).snapshots(),
            builder: (context, clientSnap) {
              if (clientSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: brandRed));
              if (!clientSnap.hasData || clientSnap.data!.docs.isEmpty) return _buildEmptyState("Sin Perfil", "Correo no registrado.", textColor);

              var clientData = clientSnap.data!.docs.first.data() as Map<String, dynamic>;
              String cedulaCliente = clientData['cedula'] ?? "";

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('vehiculos').where('propietario_id', isEqualTo: cedulaCliente).snapshots(),
                builder: (context, vehicleSnap) {
                  if (vehicleSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: brandRed));
                  if (!vehicleSnap.hasData || vehicleSnap.data!.docs.isEmpty) return _buildEmptyState("Sin Vehículos", "No hay autos asociados.", textColor);

                  final vehicles = vehicleSnap.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return {
                      "brand": data['marca'] ?? "MARCA",
                      "model": data['modelo'] ?? "MODELO",
                      "year": data['anio']?.toString() ?? "----",
                      "plate": data['placa'] ?? "S/P",
                      "color": data['color'] ?? "N/A",
                      "km": data['km']?.toString() ?? "0",
                      "isInWorkshop": data['en_taller'] ?? false,
                    };
                  }).toList();

                  if (_currentPage >= vehicles.length) _currentPage = 0;
                  
                  String placaActual = vehicles[_currentPage]['plate'];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 110,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            children: [
                              _buildSliderItem(context, Icons.calendar_month, "CITAS", brandRed, isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AppointmentsScreen()))),
                              _buildSliderItem(context, Icons.notifications, "NOTIFIC.", Colors.amber, isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const NotificationScreen()))),
                              _buildSliderItem(context, Icons.monitor_heart, "DIAGNÓSTICO", isDark ? Colors.white : Colors.black, isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const DiagnosticScreen()))),
                              _buildSliderItem(context, Icons.storefront, "TIENDA", const Color(0xFFD50000), isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const StoreScreen()))),
                              _buildSliderItem(context, Icons.local_offer, "OFERTAS", Colors.orange, isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const OfferScreen()))),
                              _buildSliderItem(context, Icons.directions_car, "MARKET", Colors.blueAccent, isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const MarketplaceScreen()))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("VEHÍCULO ACTIVO", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 2.5, fontWeight: FontWeight.bold)),
                              Text("${_currentPage + 1}/${vehicles.length}", style: TextStyle(color: subTextColor, fontSize: 10)),
                            ],
                          ),
                        ),

                        SizedBox(
                          height: 220,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: vehicles.length,
                            physics: const BouncingScrollPhysics(),
                            onPageChanged: (int index) {
                              if (_currentPage != index) {
                                setState(() {
                                  _currentPage = index;
                                });
                              }
                            },
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10), 
                                child: _buildVehicleCard(vehicles[index], isDark)
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(vehicles.length, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 5, width: _currentPage == index ? 20 : 5,
                              decoration: BoxDecoration(color: _currentPage == index ? brandRed : Colors.grey[800], borderRadius: BorderRadius.circular(3)),
                            );
                          }),
                        ),
                        const SizedBox(height: 30),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                          child: Text("HISTORIAL DE SERVICIOS", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 2.5, fontWeight: FontWeight.bold)),
                        ),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 600), 
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            key: ValueKey<String>(placaActual),
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('historial_web')
                                  .where('placa_vehiculo', isEqualTo: placaActual)
                                  .snapshots(),
                              builder: (context, historySnap) {
                                if (historySnap.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                                }
                                
                                if (!historySnap.hasData || historySnap.data!.docs.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.all(30.0),
                                    child: Center(child: Text("Sin historial para $placaActual", style: TextStyle(color: Colors.grey[600]))),
                                  );
                                }

                                return Column(
                                  children: historySnap.data!.docs.map((doc) {
                                    var data = doc.data() as Map<String, dynamic>;
                                    List items = data['presupuesto_items'] ?? [];
                                    String titulo = data['sistema_reparar'] ?? "Servicio Taller";
                                    var fechaFin = data['fecha_finalizacion'];
                                    String garantiaTxt = data['garantia'] ?? "N/A";
                                    String estado = "Finalizado"; 
                                    bool isCompleted = true;

                                    Map<String, dynamic> historyItem = {
                                      'title': titulo, 
                                      'date': _formatDate(fechaFin),
                                      'status': estado,
                                      'isCompleted': isCompleted,
                                      'warranty': garantiaTxt,
                                      'daysLeft': _calculateRemainingWarranty(fechaFin, garantiaTxt), 
                                      'elapsed': _calculateElapsed(fechaFin),
                                      'complaint': "Servicio realizado a ${data['modelo_vehiculo'] ?? 'vehículo'}",
                                      'diagnosis': "Trabajo realizado en ${data['sistema_reparar'] ?? 'sistema general'}.",
                                      'videoReception': data['link_video'] ?? "",
                                      'videoRepair': "",
                                      'budget': items.map((i) => {
                                        'item': i['item'] ?? i['descripcion'] ?? "Item",
                                        'price': (i['precio_unitario'] ?? i['total'] ?? 0).toDouble()
                                      }).toList(),
                                    };

                                    return _buildHistoryCard(context, historyItem, isDark);
                                  }).toList(),
                                );
                              }
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  );
                }
              );
            }
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildEmptyState(String title, String subtitle, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_accounts, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDrawer(bool isDark, String userEmail) {
    return Drawer(
      backgroundColor: isDark ? Colors.black : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF111111) : Colors.grey[200]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(backgroundColor: Color(0xFFD50000), radius: 30, child: Icon(Icons.person, color: Colors.white, size: 30)),
                const SizedBox(height: 15),
                Text(userEmail.split('@')[0].toUpperCase(), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                Text("Cliente Verificado", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          _buildDrawerItem(Icons.logout, "CERRAR SESIÓN", isDark, onTap: () async {
            await FirebaseAuth.instance.signOut();
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, bool isDark, {VoidCallback? onTap}) {
    Color color = isDark ? Colors.white : Colors.black87;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, letterSpacing: 1)),
      onTap: onTap,
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicleData, bool isDark) {
    bool isInWorkshop = vehicleData['isInWorkshop'] ?? false;
    Color cardBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black;
    Color borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[300]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0 : 0.05), blurRadius: 10)],
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFD50000).withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.directions_car, color: Color(0xFFD50000), size: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicleData['brand'].toString().toUpperCase(), style: TextStyle(color: textColor, fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(vehicleData['model'].toString().toUpperCase(), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: textColor, letterSpacing: 0.5)),
                    Text(vehicleData['year'].toString(), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),
              if (isInWorkshop)
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFFD50000))), child: const Text("EN TALLER", style: TextStyle(color: Color(0xFFD50000), fontWeight: FontWeight.bold, fontSize: 8, letterSpacing: 0.5))),
            ],
          ),
          const Spacer(),
          Divider(color: borderColor, height: 1),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTechInfo("PLACA", vehicleData['plate'] ?? "S/P", isDark),
              Container(width: 1, height: 25, color: borderColor),
              _buildTechInfo("COLOR", vehicleData['color'] ?? "N/A", isDark),
              Container(width: 1, height: 25, color: borderColor),
              _buildTechInfo("KM", vehicleData['km'] ?? "0", isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechInfo(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 8, letterSpacing: 1.0)),
        const SizedBox(height: 3),
        Text(value.toUpperCase(), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> historyItem, bool isDark) {
    bool isCompleted = historyItem['isCompleted'] ?? true;
    Color statusColor = isCompleted ? Colors.green : const Color(0xFFD50000);
    Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color titleColor = isDark ? Colors.white : Colors.black;
    Color borderColor = isDark ? Colors.white10 : Colors.grey[300]!;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RepairDetailScreen(historyItem: historyItem, isDark: isDark))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardBg, borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(isCompleted ? Icons.check_circle : Icons.timelapse, color: statusColor, size: 20)),
                const SizedBox(width: 15),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(historyItem['title'] ?? "Servicio", style: TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 4), Text(historyItem['date'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 11))])),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 12),
              ],
            ),
            if (isCompleted) ...[
              const SizedBox(height: 15), Divider(color: borderColor, height: 1), const SizedBox(height: 15),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _buildHistoryStat(Icons.verified_user_outlined, "Garantía", historyItem['warranty'] ?? "N/A", isDark),
                _buildHistoryStat(Icons.hourglass_bottom, "Restan", historyItem['daysLeft'] ?? "-", isDark, isHighlighted: true),
                _buildHistoryStat(Icons.history, "Tiempo", historyItem['elapsed'] ?? "-", isDark),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryStat(IconData icon, String label, String value, bool isDark, {bool isHighlighted = false}) {
    Color valColor = isHighlighted ? (isDark ? Colors.greenAccent : Colors.green[700]!) : (isDark ? Colors.white : Colors.black87);
    return Column(children: [Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: Colors.grey), const SizedBox(width: 4), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9))]), const SizedBox(height: 4), Text(value, style: TextStyle(color: valColor, fontSize: 11, fontWeight: FontWeight.bold))]);
  }

  Widget _buildSliderItem(BuildContext context, IconData icon, String label, Color iconColor, bool isDark, {VoidCallback? onTap}) {
    return GestureDetector(onTap: onTap, child: Container(width: 90, margin: const EdgeInsets.symmetric(horizontal: 5), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(height: 60, width: 60, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isDark ? [const Color(0xFF2C2C2C), Colors.black.withValues(alpha: 0.8)] : [Colors.white, Colors.grey[200]!]), shape: BoxShape.circle, border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1), blurRadius: 10, offset: const Offset(0, 5))]), child: Icon(icon, color: iconColor, size: 24)), const SizedBox(height: 10), Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold, letterSpacing: 1.0))])));
  }
}

class RepairDetailScreen extends StatelessWidget {
  final Map<String, dynamic> historyItem;
  final bool isDark;

  const RepairDetailScreen({super.key, required this.historyItem, required this.isDark});

  @override
  Widget build(BuildContext context) {
    bool isCompleted = historyItem['isCompleted'] ?? true;
    Color statusColor = isCompleted ? Colors.green : const Color(0xFFD50000);
    List budgetList = historyItem['budget'] ?? [];
    double totalBudget = budgetList.fold(0, (total, item) => total + ((item['price'] ?? 0.0) as double));

    Color textColor = isDark ? Colors.white : Colors.black;
    Color cardColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    Color borderColor = isDark ? Colors.white10 : Colors.grey[300]!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text("INFORME DE SERVICIO", style: TextStyle(fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold, color: textColor)), centerTitle: true, iconTheme: IconThemeData(color: textColor)),
      body: Stack(
        children: [
          Container(
            height: double.infinity, width: double.infinity,
            decoration: BoxDecoration(
              gradient: isDark ? const RadialGradient(center: Alignment(0, -0.3), radius: 1.2, colors: [Color(0xFF252525), Colors.black]) : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFEEEEEE)]),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(25, 120, 25, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor)),
                  child: Text(historyItem['status'].toString().toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 20),
                Text(historyItem['title'] ?? "", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor, height: 1.2)),
                const SizedBox(height: 10),
                Text(historyItem['date'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 14)),

                const SizedBox(height: 40),

                _buildSectionTitle("REPORTE TÉCNICO"),
                const SizedBox(height: 15),
                _buildInfoBlock("Falla Reportada", historyItem['complaint'], textColor, cardColor, borderColor),
                const SizedBox(height: 10),
                _buildInfoBlock("Diagnóstico Técnico", historyItem['diagnosis'], textColor, cardColor, borderColor),

                const SizedBox(height: 30),

                _buildSectionTitle("EVIDENCIA MULTIMEDIA"),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildVideoCard(context, "Recepción", historyItem['videoReception'], title: "Recepción del vehículo.", desc: "Video del estado inicial.", isDark: isDark)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildVideoCard(context, "Reparación", historyItem['videoRepair'], title: "Reparación: ${historyItem['title']}", desc: historyItem['diagnosis'], isDark: isDark)),
                  ],
                ),

                const SizedBox(height: 30),

                _buildSectionTitle("PRESUPUESTO APROBADO"),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15), border: Border.all(color: borderColor)),
                  child: Column(
                    children: [
                      ...budgetList.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(item['item'], style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13))),
                              Text("\$${(item['price'] ?? 0.0).toStringAsFixed(2)}", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      Divider(color: borderColor),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("TOTAL", style: TextStyle(color: Color(0xFFD50000), fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("\$${totalBudget.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFD50000), fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2));
  }

  Widget _buildInfoBlock(String label, String? content, Color textColor, Color bgColor, Color borderColor) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD50000))),
          const SizedBox(height: 5),
          Text(content ?? "Pendiente...", style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, String label, String? videoUrl, {required String title, required String? desc, required bool isDark}) {
    bool hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    String? thumbnailUrl;

    if (hasVideo) {
      String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
      if (videoId != null) thumbnailUrl = "https://img.youtube.com/vi/$videoId/mqdefault.jpg";
    }

    return GestureDetector(
      onTap: () {
        if (hasVideo) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => InAppVideoPlayerScreen(videoUrl: videoUrl!, videoTitle: title, videoDescription: desc ?? "Sin detalles.")));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No hay video disponible")));
        }
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.black, borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isDark ? Colors.white24 : Colors.grey[400]!),
          image: thumbnailUrl != null ? DecorationImage(image: NetworkImage(thumbnailUrl!), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken)) : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.play_circle_fill, color: hasVideo ? const Color(0xFFD50000) : Colors.grey.withValues(alpha: 0.3), size: 40),
            Positioned(bottom: 10, child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)]))),
          ],
        ),
      ),
    );
  }
}

class InAppVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final String videoDescription;

  const InAppVideoPlayerScreen({super.key, required this.videoUrl, required this.videoTitle, required this.videoDescription});

  @override
  State<InAppVideoPlayerScreen> createState() => _InAppVideoPlayerScreenState();
}

class _InAppVideoPlayerScreenState extends State<InAppVideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    _controller = YoutubePlayerController(initialVideoId: videoId ?? "", flags: const YoutubePlayerFlags(autoPlay: true, mute: false, enableCaption: false, forceHD: true));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(controller: _controller, showVideoProgressIndicator: true, progressIndicatorColor: const Color(0xFFD50000), progressColors: const ProgressBarColors(playedColor: Color(0xFFD50000), handleColor: Color(0xFFD50000))),
      builder: (context, player) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: const BoxDecoration(color: Colors.black),
            child: Column(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(backgroundColor: Colors.black.withValues(alpha: 0.5), child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context))),
                        const Spacer(),
                        const Text("EVIDENCIA DIGITAL", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
                        const Spacer(),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 20, offset: const Offset(0, 10))], borderRadius: BorderRadius.circular(10)),
                  child: player,
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)), border: const Border(top: BorderSide(color: Colors.white10))),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFD50000), borderRadius: BorderRadius.circular(5)), child: const Text("VIDEO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
                          const SizedBox(height: 15),
                          Text(widget.videoTitle, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 15),
                          const Text("DETALLES", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(widget.videoDescription, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}