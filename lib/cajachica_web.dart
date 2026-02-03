import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CajaChicaWebModule extends StatefulWidget {
  const CajaChicaWebModule({super.key});

  @override
  State<CajaChicaWebModule> createState() => _CajaChicaWebModuleState();
}

class _CajaChicaWebModuleState extends State<CajaChicaWebModule> {
  // --- PALETA EMPRESARIAL PREMIUM ---
  final Color softGreen = const Color(0xFF4CAF50); 
  final Color cardBlack = const Color(0xFF121212);
  final Color bgDark = const Color(0xFF0A0A0A); 
  final Color inputFill = const Color(0xFF1E1E1E);
  final Color dangerRed = const Color(0xFFE53935);
  final Color accentBlue = const Color(0xFF2196F3);

  // --- CONTROLADORES ---
  final TextEditingController _conceptoController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  String _fuenteSeleccionada = 'Efectivo';
  String? _tecnicoSeleccionado;

  final TextEditingController _clienteDeudaController = TextEditingController();
  final TextEditingController _conceptoDeudaController = TextEditingController();
  final TextEditingController _montoDeudaController = TextEditingController();

  // --- FILTROS ---
  String _filtroSeleccionado = "Este Mes";
  late DateTimeRange _rangoFechas;

  // --- VARIABLES DE BALANCE Y RESUMEN ---
  double _balEfectivo = 0.0;
  double _balZelle = 0.0;
  double _balBanco = 0.0;
  double _totalDisponible = 0.0;

  double _deudaNomina = 0.0;
  double _deudaTecnicos = 0.0;
  double _deudaProveedores = 0.0; 
  double _totalDeuda = 0.0;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    _rangoFechas = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59), 
    );
  }

  void _aplicarFiltroPredefinido(String opcion) {
    DateTime now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (opcion) {
      case "Hoy": start = DateTime(now.year, now.month, now.day); break;
      case "Ayer": start = DateTime(now.year, now.month, now.day - 1); end = DateTime(now.year, now.month, now.day - 1, 23, 59, 59); break;
      case "Este Mes": start = DateTime(now.year, now.month, 1); break;
      case "Mes Pasado": start = DateTime(now.year, now.month - 1, 1); end = DateTime(now.year, now.month, 0, 23, 59, 59); break;
      default: return; 
    }
    setState(() {
      _filtroSeleccionado = opcion;
      _rangoFechas = DateTimeRange(start: start, end: end);
    });
  }

  bool _esFechaValida(DateTime fecha) {
    return fecha.isAfter(_rangoFechas.start.subtract(const Duration(seconds: 1))) && 
           fecha.isBefore(_rangoFechas.end.add(const Duration(seconds: 1)));
  }

  // --- OPERACIONES ---

  Future<void> _registrarSalida(String categoria) async {
    if (_conceptoController.text.isEmpty || _montoController.text.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('gastos').add({
        'fecha': DateTime.now(),
        'motivo': _conceptoController.text.toUpperCase(),
        'monto': double.parse(_montoController.text),
        'fuente': _fuenteSeleccionada,
        'categoria': categoria,
        'estado_pago': 'PAGADO',
        'creado_en': FieldValue.serverTimestamp(),
      });
      _conceptoController.clear();
      _montoController.clear();
      setState(() { _tecnicoSeleccionado = null; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ REGISTRADO")));
    } catch (e) { debugPrint("Error: $e"); }
  }

  Future<void> _toggleEstadoPago(String docId, String estadoActual) async {
    String nuevoEstado = (estadoActual == 'PAGADO') ? 'PENDIENTE' : 'PAGADO';
    await FirebaseFirestore.instance.collection('gastos').doc(docId).update({'estado_pago': nuevoEstado});
  }

  Future<void> _registrarDeuda(String coleccion, String tipo) async {
    if (_clienteDeudaController.text.isEmpty || _montoDeudaController.text.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection(coleccion).add({
        'fecha': DateTime.now(),
        'entidad': _clienteDeudaController.text.toUpperCase(),
        'motivo': _conceptoDeudaController.text.toUpperCase(),
        'monto': double.parse(_montoDeudaController.text),
        'estado': 'PENDIENTE',
        'tipo': tipo,
        'creado_en': FieldValue.serverTimestamp(),
      });
      _clienteDeudaController.clear();
      _conceptoDeudaController.clear();
      _montoDeudaController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ $tipo AGREGADO")));
    } catch (e) { debugPrint("Error: $e"); }
  }

  // --- MODIFICACIÓN IMPORTANTE AQUÍ: TRANSFERENCIA DE DEUDA A GASTO ---
  Future<void> _liquidarDeuda(String coleccion, String docId, Map<String, dynamic> data) async {
    try {
      if (coleccion == 'cxp') {
        // --- PROVEEDOR (POR PAGAR) ---
        
        // 1. Crear el gasto automáticamente en la colección 'gastos'
        // Lo marcamos como 'Operativo' para que aparezca en la pestaña GASTOS
        await FirebaseFirestore.instance.collection('gastos').add({
          'fecha': DateTime.now(),
          'motivo': "LIQUIDACIÓN CxP: ${data['entidad']} - ${data['motivo'] ?? ''}".toUpperCase(),
          'monto': data['monto'], // El mismo monto de la deuda
          'fuente': _fuenteSeleccionada, // Se descuenta de la fuente seleccionada arriba (Efectivo/Zelle/etc)
          'categoria': 'Operativo', // IMPORTANTE: Para que se vea en la pestaña Gastos
          'estado_pago': 'PAGADO',
          'creado_en': FieldValue.serverTimestamp(),
        });

        // 2. Actualizar la deuda a PAGADO en la colección 'cxp'
        await FirebaseFirestore.instance.collection('cxp').doc(docId).update({'estado': 'PAGADO'});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ PAGADO: Movido a Gastos y descontado"), backgroundColor: Colors.green));
        }

      } else {
        // --- CLIENTE (POR COBRAR) ---
        await FirebaseFirestore.instance.collection('cxc').doc(docId).update({'estado': 'COBRADO'});
        await FirebaseFirestore.instance.collection('recibos').add({
          'cliente_id': data['entidad'], 
          'modelo_vehiculo': 'S/D',
          'placa_vehiculo': 'S/P',
          'total_reparacion': data['monto'],
          'fecha_emision_recibo': FieldValue.serverTimestamp(),
          'estado_facturacion': 'PENDIENTE',
          'numero_recibo': '',
          'notas': data['motivo'] ?? 'Liquidación de deuda',
          'presupuesto_items': [
            {'item': data['motivo'] ?? 'PAGO DE DEUDA', 'cantidad': 1, 'precio_unitario': data['monto'], 'subtotal': data['monto']}
          ]
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ COBRO REGISTRADO Y RECIBO GENERADO"), backgroundColor: Colors.green));
      }
    } catch (e) { 
      debugPrint("Error al liquidar: $e"); 
    }
  }

  Future<void> _editarRegistro(String coleccion, String docId, Map<String, dynamic> data) async {
    TextEditingController editEntidad = TextEditingController(text: data['entidad'] ?? data['motivo']);
    TextEditingController editMotivo = TextEditingController(text: data['motivo'] ?? "");
    TextEditingController editMonto = TextEditingController(text: data['monto'].toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBlack,
        title: const Text("Editar Registro", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: editEntidad, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Entidad / Cliente")),
            TextField(controller: editMotivo, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Concepto")),
            TextField(controller: editMonto, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Monto \$")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              await FirebaseFirestore.instance.collection(coleccion).doc(docId).update({
                'entidad': editEntidad.text.toUpperCase(),
                'motivo': editMotivo.text.toUpperCase(),
                'monto': double.parse(editMonto.text),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            }, 
            child: const Text("GUARDAR")
          ),
        ],
      )
    );
  }

  Future<void> _eliminarDocumento(String coleccion, String docId) async {
    bool confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBlack,
        title: const Text("¿Eliminar?", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("NO")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("SÍ", style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;
    if (confirmar) await FirebaseFirestore.instance.collection(coleccion).doc(docId).delete();
  }

  void _calcularBalance(List<QueryDocumentSnapshot> ventas, List<QueryDocumentSnapshot> gastos, List<QueryDocumentSnapshot> cxp) {
    double vEfe = 0, vZel = 0, vBan = 0;
    double gEfe = 0, gZel = 0, gBan = 0;
    
    for (var doc in ventas) {
      var d = doc.data() as Map<String, dynamic>;
      double m = (d['total_reparacion'] ?? 0).toDouble();
      String met = (d['metodo_pago'] ?? "").toString().toUpperCase();
      if (met.contains("EFECTIVO")) { 
        vEfe += m; 
      } else if (met.contains("ZELLE") || met.contains("BINANCE")) { 
        vZel += m; 
      } else { 
        vBan += m; 
      }
    }

    _deudaNomina = 0; _deudaTecnicos = 0; _deudaProveedores = 0;

    for (var doc in gastos) {
      var d = doc.data() as Map<String, dynamic>;
      double m = (d['monto'] ?? 0).toDouble();
      String estado = d['estado_pago'] ?? 'PAGADO';
      String categoria = d['categoria'] ?? '';

      if (estado == 'PAGADO') {
        String f = (d['fuente'] ?? "").toString();
        if (f == "Efectivo") {
          gEfe += m; 
        } else if (f == "Zelle") {
          gZel += m; 
        } else {
          gBan += m;
        }
      } else {
        if (categoria == 'Nomina') {
          _deudaNomina += m;
        } else if (categoria == 'Tecnico') {
          _deudaTecnicos += m;
        }
      }
    }

    for (var doc in cxp) {
      var d = doc.data() as Map<String, dynamic>;
      if (d['estado'] == 'PENDIENTE') {
        _deudaProveedores += (d['monto'] ?? 0).toDouble();
      }
    }

    _balEfectivo = vEfe - gEfe;
    _balZelle = vZel - gZel;
    _balBanco = vBan - gBan;
    _totalDisponible = _balEfectivo + _balZelle + _balBanco;
    _totalDeuda = _deudaNomina + _deudaTecnicos + _deudaProveedores;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: bgDark,
        body: SizedBox.expand(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('ventas').snapshots(),
                  builder: (context, ventasSnap) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('gastos').orderBy('fecha', descending: true).snapshots(),
                      builder: (context, gastosSnap) {
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('cxp').orderBy('fecha', descending: true).snapshots(),
                          builder: (context, cxpSnap) {
                            if (!ventasSnap.hasData || !gastosSnap.hasData || !cxpSnap.hasData) return const Center(child: CircularProgressIndicator());

                            var vF = ventasSnap.data!.docs.where((doc) => _esFechaValida((doc.data() as Map<String, dynamic>)['fecha_venta']?.toDate() ?? DateTime(2000))).toList();
                            var gF = gastosSnap.data!.docs.where((doc) => _esFechaValida((doc.data() as Map<String, dynamic>)['fecha']?.toDate() ?? DateTime(2000))).toList();
                            
                            var gOp = gF.where((d) => (d.data() as Map)['categoria'] == 'Operativo' || (d.data() as Map)['categoria'] == null).toList();
                            var gNo = gF.where((d) => (d.data() as Map)['categoria'] == 'Nomina').toList();
                            var gTe = gF.where((d) => (d.data() as Map)['categoria'] == 'Tecnico').toList();

                            _calcularBalance(vF, gastosSnap.data!.docs, cxpSnap.data!.docs);

                            return Column(
                              children: [
                                Row(
                                  children: [
                                    _buildBalanceCard("DISPONIBLE EFECTIVO", _balEfectivo, Icons.payments, Colors.green),
                                    const SizedBox(width: 20),
                                    _buildBalanceCard("CUENTA ZELLE", _balZelle, Icons.phonelink_ring, Colors.purpleAccent),
                                    const SizedBox(width: 20),
                                    _buildBalanceCard("BANCO NACIONAL", _balBanco, Icons.account_balance, Colors.blueAccent),
                                    const SizedBox(width: 20),
                                    _buildBalanceCard("BALANCE TOTAL NETO", _totalDisponible, Icons.account_balance_wallet, Colors.amber, isTotal: true),
                                  ],
                                ),
                                const SizedBox(height: 35),
                                _buildTabBar(),
                                const SizedBox(height: 25),
                                SizedBox(
                                  height: 800, 
                                  child: TabBarView(
                                    children: [
                                      _tabGenerico(gOp, "Operativo", Icons.receipt_long),
                                      _tabDeudas("cxc", "Cliente", Icons.person_search, Colors.blue),
                                      _tabDeudas("cxp", "Proveedor", Icons.inventory, Colors.orange),
                                      _tabGenerico(gNo, "Nomina", Icons.badge),
                                      _tabGenerico(gTe, "Tecnico", Icons.engineering),
                                      _buildTabResumen(),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("SISTEMA DE CONTROL FINANCIERO", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          Text("Gestión de Caja Chica y Pasivos - Super Vortec", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
        ]),
        _buildFiltroFechaBadge(),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: TabBar(
        indicator: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
        indicatorColor: softGreen,
        labelColor: softGreen,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: "GASTOS"), Tab(text: "POR COBRAR"), Tab(text: "POR PAGAR"), Tab(text: "NÓMINA"), Tab(text: "TÉCNICOS"),
          Tab(text: "RESUMEN", icon: Icon(Icons.analytics_outlined, size: 18)),
        ],
      ),
    );
  }

  Widget _tabGenerico(List<QueryDocumentSnapshot> docs, String cat, IconData icon) {
    double total = docs.where((d) => (d.data() as Map)['estado_pago'] == 'PAGADO').fold(0, (p, d) => p + (d['monto'] ?? 0));
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
          child: Row(
            children: [
              Expanded(flex: 3, child: cat == 'Tecnico' ? _buildTecnicoSelector() : _buildInput(cat == "Nomina" ? "EMPLEADO" : "CONCEPTO", _conceptoController, icon)),
              const SizedBox(width: 15),
              Expanded(flex: 2, child: _buildInput("MONTO \$", _montoController, Icons.attach_money, isNum: true)),
              const SizedBox(width: 15),
              Expanded(flex: 2, child: _buildDropdown()),
              const SizedBox(width: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: softGreen, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => _registrarSalida(cat),
                child: const Text("REGISTRAR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              )
            ],
          ),
        ),
        const SizedBox(height: 25),
        _totalRow("TOTAL $cat (PAGADO)", total),
        const SizedBox(height: 15),
        Expanded(
          child: ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              var d = docs[i].data() as Map<String, dynamic>;
              return _buildRecordRow('gastos', docs[i].id, d, icon, categoriaContext: cat);
            },
          ),
        ),
      ],
    );
  }

  Widget _tabDeudas(String col, String label, IconData icon, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(col).orderBy('fecha', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var docs = snapshot.data!.docs.where((d) => (d.data() as Map)['estado'] == 'PENDIENTE').toList();
        double total = docs.fold(0, (p, d) => p + (d['monto'] ?? 0));
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withValues(alpha: 0.2))),
              child: Row(
                children: [
                  Expanded(flex: 3, child: _buildInput(label.toUpperCase(), _clienteDeudaController, Icons.person_outline)),
                  const SizedBox(width: 15),
                  Expanded(flex: 3, child: _buildInput("MOTIVO / CONCEPTO", _conceptoDeudaController, Icons.edit_note)), 
                  const SizedBox(width: 15),
                  Expanded(flex: 2, child: _buildInput("MONTO \$", _montoDeudaController, Icons.attach_money, isNum: true)),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () => _registrarDeuda(col, col == 'cxc' ? 'Por Cobrar' : 'Por Pagar'),
                    child: const Text("AGREGAR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 25),
            _totalRow("TOTAL $label PENDIENTE", total, color: color),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  var d = docs[i].data() as Map<String, dynamic>;
                  return _buildRecordRow(col, docs[i].id, d, icon, isDeuda: true, color: color, categoriaContext: 'Deuda');
                },
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildRecordRow(String col, String id, Map<String, dynamic> d, IconData icon, {bool isDeuda = false, Color? color, String? categoriaContext}) {
    bool pagado = isDeuda ? (d['estado'] != 'PENDIENTE') : (d['estado_pago'] == 'PAGADO');
    DateTime f = (d['fecha'] as Timestamp).toDate();
    // MOSTRAR SWITCH: SOLO si NO es deuda Y NO es gasto Operativo
    bool mostrarSwitch = !isDeuda && (categoriaContext == 'Nomina' || categoriaContext == 'Tecnico');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Row(
        children: [
          Icon(icon, color: pagado ? Colors.green : (color ?? softGreen), size: 20),
          const SizedBox(width: 20),
          Text(DateFormat('dd/MM HH:mm').format(f), style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(width: 20),
          Expanded(child: Text(isDeuda ? "${d['entidad']}  •  ${d['motivo'] ?? ''}" : "${d['motivo']}  •  [${d['fuente']}]", style: TextStyle(color: pagado ? Colors.white38 : Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
          if (mostrarSwitch) Text(pagado ? "LIQUIDADO" : "PENDIENTE", style: TextStyle(color: pagado ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.w900)),
          const SizedBox(width: 20),
          Text("\$${(d['monto'] ?? 0).toStringAsFixed(2)}", style: TextStyle(color: pagado ? Colors.white38 : Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(width: 20),
          
          if (mostrarSwitch)
            Transform.scale(scale: 0.7, child: Switch(value: pagado, activeThumbColor: Colors.green, onChanged: (val) => _toggleEstadoPago(id, d['estado_pago'] ?? 'PAGADO'))),
          
          if (isDeuda && !pagado) IconButton(icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 22), onPressed: () => _liquidarDeuda(col, id, d)),
          IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 18), onPressed: () => _editarRegistro(col, id, d)),
          IconButton(icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white24, size: 18), onPressed: () => _eliminarDocumento(col, id)),
        ],
      ),
    );
  }

  Widget _buildTabResumen() {
    double proyeccion = _totalDisponible - _totalDeuda;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("DASHBOARD DE SALUD FINANCIERA", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 30),
        Row(
          children: [
            _buildResumenMetric("LIQUIDEZ (DISPONIBLE)", _totalDisponible, softGreen, Icons.account_balance, detalles: ["Efectivo: \$$_balEfectivo", "Zelle: \$$_balZelle", "Banco: \$$_balBanco"]),
            const SizedBox(width: 20),
            _buildResumenMetric("PASIVOS (LO QUE DEBES)", _totalDeuda, dangerRed, Icons.trending_down, detalles: ["Nómina: \$$_deudaNomina", "Técnicos: \$$_deudaTecnicos", "Proveedores: \$$_deudaProveedores"]),
            const SizedBox(width: 20),
            _buildResumenMetric("CAPITAL NETO PROYECTADO", proyeccion, accentBlue, Icons.pie_chart, isMain: true),
          ],
        ),
      ],
    );
  }

  Widget _buildResumenMetric(String title, double val, Color color, IconData icon, {List<String>? detalles, bool isMain = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 10), Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 20),
            Text("\$${val.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
            if (detalles != null) ...[
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 10),
              ...detalles.map((d) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Text(d, style: const TextStyle(color: Colors.white54, fontSize: 12)))),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(String t, double a, IconData i, Color c, {bool isTotal = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(color: isTotal ? c.withValues(alpha: 0.1) : cardBlack, borderRadius: BorderRadius.circular(15), border: Border.all(color: isTotal ? c : Colors.white10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(i, color: c, size: 18), const SizedBox(width: 10), Text(t, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 15),
          Text("\$${a.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }

  Widget _buildInput(String l, TextEditingController c, IconData i, {bool isNum = false}) {
    return TextField(
      controller: c, keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: l, labelStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        prefixIcon: Icon(i, color: softGreen, size: 18),
        filled: true, fillColor: inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _fuenteSeleccionada, dropdownColor: cardBlack, isExpanded: true,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          items: ['Efectivo', 'Zelle', 'Banco'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _fuenteSeleccionada = v!),
        ),
      ),
    );
  }

  Widget _buildTecnicoSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('mecanicos').orderBy('nombre').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var items = snapshot.data!.docs.map((doc) => DropdownMenuItem<String>(value: (doc.data() as Map)['nombre'].toString(), child: Text((doc.data() as Map)['nombre'].toString()))).toList();
        return Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(10)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(hint: const Text("SELECCIONE TÉCNICO", style: TextStyle(color: Colors.white38, fontSize: 11)), value: _tecnicoSeleccionado, dropdownColor: cardBlack, isExpanded: true, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), items: items, onChanged: (v) => setState(() { _tecnicoSeleccionado = v; _conceptoController.text = v ?? ""; }))));
      }
    );
  }

  Widget _totalRow(String label, double val, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: (color ?? softGreen).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: (color ?? softGreen).withValues(alpha: 0.15))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          Text("\$${val.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildFiltroFechaBadge() {
    return PopupMenuButton<String>(
      color: cardBlack, onSelected: _aplicarFiltroPredefinido,
      itemBuilder: (ctx) => ["Hoy", "Ayer", "Este Mes", "Mes Pasado"].map((t) => PopupMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white)))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white12)),
        child: Row(children: [Icon(Icons.calendar_today_outlined, color: softGreen, size: 16), const SizedBox(width: 10), Text(_filtroSeleccionado.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))]),
      ),
    );
  }
}