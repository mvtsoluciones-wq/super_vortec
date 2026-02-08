import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; 

// --- 1. IMPORTACIÓN NECESARIA PARA CORREGIR EL ERROR DE FECHA ---
import 'package:intl/date_symbol_data_local.dart';

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

  // --- 2. LÍNEA AGREGADA PARA INICIALIZAR EL FORMATO DE FECHA EN ESPAÑOL ---
  await initializeDateFormatting('es_ES', null);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const SuperVortecApp());
}

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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFFD50000))),
          );
        }
        if (snapshot.hasData) {
          return const SessionTimeoutGuard(child: PlatformGuard());
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
      } else {
        return const WebBlockedScreen();
      }
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
            const Text(
              "APP NO DISPONIBLE EN WEB",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: const Text("Cerrar Sesión", style: TextStyle(color: Colors.white54)),
            ),
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
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88, initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
    return daysLeft < 0 ? "Vencida" : "$daysLeft Días";
  }

  String _calculateElapsed(dynamic fechaFin) {
    if (fechaFin == null || fechaFin is! Timestamp) return "En taller";
    DateTime fecha = fechaFin.toDate();
    DateTime now = DateTime.now();
    Duration diff = now.difference(fecha);
    if (diff.inDays > 365) return "${(diff.inDays / 365).floor()} Años";
    if (diff.inDays > 30) return "${(diff.inDays / 30).floor()} Meses";
    if (diff.inDays > 0) return "${diff.inDays} Días";
    return "Hoy";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const Color brandRed = Color(0xFFD50000);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    if (user == null) return const Scaffold(body: Center(child: Text("Error de sesión")));

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(isDark, user.email ?? "Usuario"),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('MI GARAJE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3.0, fontSize: 18, color: textColor)),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: isDark ? Colors.amber : Colors.indigo),
            onPressed: () => themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark,
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            height: double.infinity, width: double.infinity,
            decoration: BoxDecoration(
              gradient: isDark
                  ? const RadialGradient(center: Alignment(0, -0.3), radius: 1.2, colors: [Color(0xFF252525), Colors.black])
                  : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFEEEEEE)]),
            ),
          ),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('clientes').where('email', isEqualTo: user.email).limit(1).snapshots(),
            builder: (context, clientSnap) {
              if (!clientSnap.hasData || clientSnap.data!.docs.isEmpty) return const Center(child: CircularProgressIndicator());
              String cedula = (clientSnap.data!.docs.first.data() as Map<String, dynamic>)['cedula'] ?? "";

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('vehiculos').where('propietario_id', isEqualTo: cedula).snapshots(),
                builder: (context, vehicleSnap) {
                  if (!vehicleSnap.hasData) return const Center(child: CircularProgressIndicator());

                  final Map<String, Map<String, dynamic>> uniqueVehicles = {};
                  for (var doc in vehicleSnap.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    String plate = (data['placa'] ?? "").toString().trim().toUpperCase();
                    if (plate.isNotEmpty && !uniqueVehicles.containsKey(plate)) {
                      uniqueVehicles[plate] = {
                        "brand": data['marca'] ?? "MARCA",
                        "model": data['modelo'] ?? "MODELO",
                        "year": data['anio']?.toString() ?? "----",
                        "plate": plate,
                        "color": data['color'] ?? "N/A",
                        "km": data['km']?.toString() ?? "0",
                        "isInWorkshop": data['en_taller'] ?? false,
                      };
                    }
                  }

                  final List<Map<String, dynamic>> vehicles = uniqueVehicles.values.toList();
                  vehicles.sort((a, b) => a['plate'].compareTo(b['plate']));

                  if (vehicles.isEmpty) return _buildEmptyState("Sin Vehículos", "No hay autos registrados.", textColor);
                  if (_currentPage >= vehicles.length) _currentPage = 0;
                  
                  // OBTENEMOS LA PLACA ACTUAL
                  String placaActual = vehicles[_currentPage]['plate'];

                  return SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        // PASAMOS LA PLACA AL MENÚ SLIDER
                        _buildMenuSlider(context, brandRed, isDark, placaActual),
                        const SizedBox(height: 20),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("VEHÍCULO ACTIVO", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 2.5, fontWeight: FontWeight.bold)),
                              Text("${_currentPage + 1}/${vehicles.length}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 10)),
                            ],
                          ),
                        ),

                        SizedBox(
                          height: 180,
                          child: PageView.builder(
                            key: const PageStorageKey('stable_carousel'),
                            controller: _pageController,
                            itemCount: vehicles.length,
                            physics: const PageScrollPhysics(),
                            onPageChanged: (int index) => setState(() => _currentPage = index),
                            itemBuilder: (context, index) {
                              return AnimatedScale(
                                duration: const Duration(milliseconds: 400),
                                scale: _currentPage == index ? 1.0 : 0.9,
                                child: _buildVehicleCard(vehicles[index], isDark),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(vehicles.length, (index) => AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4), height: 5, width: _currentPage == index ? 20 : 5, decoration: BoxDecoration(color: _currentPage == index ? brandRed : Colors.grey[800], borderRadius: BorderRadius.circular(3)))),
                        ),
                        
                        const SizedBox(height: 15),
                        const Divider(color: Colors.white10, thickness: 1, indent: 25, endIndent: 25),

                        Expanded(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                                  child: Text("HISTORIAL DE SERVICIOS", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 2.5, fontWeight: FontWeight.bold)),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  child: Container(
                                    key: ValueKey<String>(placaActual),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance.collection('historial_web').where('placa_vehiculo', isEqualTo: placaActual).snapshots(),
                                      builder: (context, historySnap) {
                                        if (!historySnap.hasData) return const Center(child: CircularProgressIndicator());
                                        if (historySnap.data!.docs.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(50), child: Text("Sin servicios registrados.", style: TextStyle(color: Colors.grey[600], fontSize: 12))));

                                        return Column(
                                          children: historySnap.data!.docs.map((doc) {
                                            var data = doc.data() as Map<String, dynamic>;
                                            return _buildHistoryCard(context, {
                                              'budget_id': data['numero_presupuesto'] ?? "N/A",
                                              'title': data['sistema_reparar'] ?? "Servicio Técnico",
                                              'date': _formatDate(data['fecha_finalizacion']),
                                              'status': "Finalizado",
                                              'isCompleted': true,
                                              'warranty': data['garantia'] ?? "N/A",
                                              'daysLeft': _calculateRemainingWarranty(data['fecha_finalizacion'], data['garantia']),
                                              'elapsed': _calculateElapsed(data['fecha_finalizacion']),
                                              'complaint': "Reparación General",
                                              'diagnosis': data['sistema_reparar'] ?? "Sin descripción de falla.", 
                                              'budget': (data['presupuesto_items'] as List? ?? []).map((i) => {'item': i['item'] ?? "Repuesto", 'price': (i['precio_unitario'] ?? 0).toDouble()}).toList(),
                                              'videoUrl': data['url_evidencia_video'] ?? "", 
                                            }, isDark);
                                          }).toList(),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

  // --- MENU SLIDER CORREGIDO ---
  Widget _buildMenuSlider(BuildContext context, Color red, bool isDark, String placa) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSliderItem(context, Icons.calendar_month, "CITAS", red, isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AppointmentsScreen()))),
          
          // --- AQUÍ ESTÁ LA CORRECCIÓN: NotificacionesScreen con parámetro currentPlaca ---
          _buildSliderItem(
            context, 
            Icons.notifications, 
            "NOTIFIC.", 
            Colors.amber, 
            isDark, 
            onTap: () => Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (c) => NotificacionesScreen(currentPlaca: placa)
              )
            )
          ),
          
          _buildSliderItem(context, Icons.monitor_heart, "DIAGNÓSTICO", isDark ? Colors.white : Colors.black, isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DiagnosticScreen(plate: placa)))),
          
          _buildSliderItem(context, Icons.storefront, "TIENDA", red, isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const StoreScreen()))),
          _buildSliderItem(context, Icons.local_offer, "OFERTAS", Colors.orange, isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const OfferScreen()))),
          _buildSliderItem(context, Icons.directions_car, "MARKET", Colors.blueAccent, isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const MarketplaceScreen()))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String t, String s, Color c) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.no_accounts, size: 80, color: Colors.grey.withValues(alpha: 0.3)), const SizedBox(height: 20), Text(t, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 18)), Text(s, style: const TextStyle(color: Colors.grey))]));

  Widget _buildDrawer(bool isDark, String email) => Drawer(backgroundColor: isDark ? Colors.black : Colors.white, child: ListView(padding: EdgeInsets.zero, children: [UserAccountsDrawerHeader(decoration: BoxDecoration(color: isDark ? const Color(0xFF111111) : Colors.grey[200]), accountName: const Text("JMendez Performance", style: TextStyle(fontWeight: FontWeight.bold)), accountEmail: Text(email), currentAccountPicture: const CircleAvatar(backgroundColor: Color(0xFFD50000), child: Icon(Icons.person, color: Colors.white))), ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("CERRAR SESIÓN", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), onTap: () => FirebaseAuth.instance.signOut())]));

  Widget _buildVehicleCard(Map<String, dynamic> v, bool isDark) {
    Color textColor = isDark ? Colors.white : Colors.black;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const CircleAvatar(backgroundColor: Color(0xFFD50000), radius: 18, child: Icon(Icons.directions_car, color: Colors.white, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v['brand'], style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)), Text(v['model'], style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 18))])),
            if (v['isInWorkshop'] == true) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFD50000))), child: const Text("EN TALLER", style: TextStyle(color: Color(0xFFD50000), fontSize: 8, fontWeight: FontWeight.bold))),
          ]),
          const Spacer(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _buildTechItem("PLACA", v['plate'], isDark),
            _buildTechItem("COLOR", v['color'], isDark),
            _buildTechItem("KM", v['km'], isDark),
          ]),
        ],
      ),
    );
  }

  Widget _buildTechItem(String l, String v, bool isDark) => Column(children: [Text(l, style: const TextStyle(color: Colors.grey, fontSize: 8)), Text(v.toUpperCase(), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12))]);

  Widget _buildHistoryCard(BuildContext ctx, Map<String, dynamic> h, bool isDark) {
    Color statusColor = Colors.green;
    return GestureDetector(
      onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (c) => RepairDetailScreen(historyItem: h, isDark: isDark))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!)),
        child: Column(children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.check_circle, color: statusColor, size: 20)),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(h['title'], style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 13)), Text(h['date'], style: const TextStyle(color: Colors.grey, fontSize: 11))])),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 12),
          ]),
          const SizedBox(height: 15),
          const Divider(color: Colors.white10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _buildStat(Icons.verified_user, "Garantía", h['warranty']),
            _buildStat(Icons.hourglass_bottom, "Restan", h['daysLeft']),
            _buildStat(Icons.history, "Tiempo", h['elapsed']),
          ]),
        ]),
      ),
    );
  }

  Widget _buildStat(IconData i, String l, String v) => Column(children: [Row(mainAxisSize: MainAxisSize.min, children: [Icon(i, size: 10, color: Colors.grey), const SizedBox(width: 4), Text(l, style: const TextStyle(color: Colors.grey, fontSize: 8))]), const SizedBox(height: 4), Text(v, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11))]);

  Widget _buildSliderItem(BuildContext context, IconData icon, String label, Color iconColor, bool isDark, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 90, margin: const EdgeInsets.symmetric(horizontal: 5), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(height: 60, width: 60, decoration: BoxDecoration(gradient: LinearGradient(colors: isDark ? [const Color(0xFF2C2C2C), Colors.black] : [Colors.white, Colors.grey[200]!]), shape: BoxShape.circle, border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!)), child: Icon(icon, color: iconColor, size: 24)),
        const SizedBox(height: 10),
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
      ])),
    );
  }
}

class RepairDetailScreen extends StatelessWidget {
  final Map<String, dynamic> historyItem;
  final bool isDark;
  const RepairDetailScreen({super.key, required this.historyItem, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color textColor = isDark ? Colors.white : Colors.black;
    double total = (historyItem['budget'] as List).fold(0, (acc, item) => acc + (item['price'] ?? 0));
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, title: Text("ORDEN #${historyItem['budget_id']}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 2)), iconTheme: IconThemeData(color: textColor)),
      body: Stack(children: [
        Container(height: double.infinity, width: double.infinity, decoration: BoxDecoration(gradient: isDark ? const RadialGradient(center: Alignment(0, -0.3), radius: 1.2, colors: [Color(0xFF252525), Colors.black]) : const LinearGradient(colors: [Colors.white, Color(0xFFEEEEEE)]))),
        SingleChildScrollView(padding: const EdgeInsets.fromLTRB(25, 120, 25, 40), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green)), child: const Text("FINALIZADO", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10))),
          const SizedBox(height: 20),
          Text(historyItem['title'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor)),
          Text(historyItem['date'], style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),
          _buildInfoBlock("DIAGNÓSTICO TÉCNICO", historyItem['diagnosis'], textColor, isDark),
          const SizedBox(height: 30),
          _buildVideoSection(context, historyItem, isDark),
          const SizedBox(height: 30),
          _buildBudgetSection(historyItem['budget'], total, isDark, textColor),
        ])),
      ]),
    );
  }

  Widget _buildInfoBlock(String l, String c, Color t, bool d) => Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: d ? Colors.white.withValues(alpha: 0.05) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(color: Color(0xFFD50000), fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 5), Text(c, style: TextStyle(color: t.withValues(alpha: 0.7), fontSize: 13, height: 1.4))]));

  Widget _buildVideoSection(BuildContext ctx, Map h, bool d) {
    String url = h['videoUrl'] ?? ""; // USO DE URL_EVIDENCIA_VIDEO
    String? id = YoutubePlayer.convertUrlToId(url);
    String thumb = id != null ? "https://img.youtube.com/vi/$id/mqdefault.jpg" : "";
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("EVIDENCIA MULTIMEDIA", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
      const SizedBox(height: 15),
      GestureDetector(
        onTap: () { if (url.isNotEmpty) Navigator.push(ctx, MaterialPageRoute(builder: (c) => InAppVideoPlayerScreen(videoUrl: url, videoTitle: h['title'], videoDescription: h['diagnosis']))); },
        child: Container(height: 150, width: double.infinity, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10), image: thumb.isNotEmpty ? DecorationImage(image: NetworkImage(thumb), fit: BoxFit.cover, opacity: 0.6) : null), child: const Center(child: Icon(Icons.play_circle_fill, color: Color(0xFFD50000), size: 50))),
      ),
    ]);
  }

  Widget _buildBudgetSection(List items, double total, bool d, Color t) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: d ? Colors.white.withValues(alpha: 0.05) : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)), child: Column(children: [
    ...items.map((i) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(i['item'], style: const TextStyle(color: Colors.grey, fontSize: 13))), Text("\$${(i['price'] ?? 0).toStringAsFixed(2)}", style: TextStyle(color: t, fontWeight: FontWeight.bold))]))),
    const Divider(color: Colors.white10),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("TOTAL", style: TextStyle(color: Color(0xFFD50000), fontWeight: FontWeight.bold)), Text("\$${total.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFD50000), fontWeight: FontWeight.bold, fontSize: 18))]),
  ]));
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
    _controller = YoutubePlayerController(initialVideoId: YoutubePlayer.convertUrlToId(widget.videoUrl) ?? "", flags: const YoutubePlayerFlags(autoPlay: true, mute: false));
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(controller: _controller),
      builder: (context, player) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
        body: Column(children: [player, Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.videoTitle, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text(widget.videoDescription, style: const TextStyle(color: Colors.white70))]))]),
      ),
    );
  }
}