import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CajaChicaWebModule extends StatefulWidget {
  const CajaChicaWebModule({super.key});

  @override
  State<CajaChicaWebModule> createState() => _CajaChicaWebModuleState();
}

class _CajaChicaWebModuleState extends State<CajaChicaWebModule> {
  // --- PALETA DE COLORES ORIGINAL ---
  final Color softGreen = const Color(0xFF66BB6A);
  final Color cardBlack = const Color(0xFF101010);
  final Color bgDark = Colors.black;
  final Color inputFill = const Color(0xFF1E1E1E);
  final Color dangerRed = const Color(0xFFE53935);

  // --- CONTROLADORES ---
  final TextEditingController _conceptoController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  String _fuenteSeleccionada = 'Efectivo';
  String? _tecnicoSeleccionado;

  final TextEditingController _clienteDeudaController = TextEditingController();
  final TextEditingController _conceptoDeudaController =
      TextEditingController();
  final TextEditingController _montoDeudaController = TextEditingController();

  // --- FILTROS ---
  String _filtroSeleccionado = "Este Mes";
  late DateTimeRange _rangoFechas;

  // --- VARIABLES DE BALANCE Y DEUDA ---
  double _balEfectivo = 0.0;
  double _balZelle = 0.0;
  double _balBanco = 0.0;

  // Variables para el Resumen
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
      case "Hoy":
        start = DateTime(now.year, now.month, now.day);
        break;
      case "Ayer":
        start = DateTime(now.year, now.month, now.day - 1);
        end = DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
        break;
      case "Este Mes":
        start = DateTime(now.year, now.month, 1);
        break;
      case "Mes Pasado":
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      default:
        return;
    }
    setState(() {
      _filtroSeleccionado = opcion;
      _rangoFechas = DateTimeRange(start: start, end: end);
    });
  }

  bool _esFechaValida(DateTime fecha) {
    return fecha.isAfter(
          _rangoFechas.start.subtract(const Duration(seconds: 1)),
        ) &&
        fecha.isBefore(_rangoFechas.end.add(const Duration(seconds: 1)));
  }

  // --- OPERACIONES ---

  Future<void> _registrarSalida(String categoria) async {
    if (_conceptoController.text.isEmpty || _montoController.text.isEmpty)
      return;
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
      setState(() {
        _tecnicoSeleccionado = null;
      });
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✅ REGISTRADO")));
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _toggleEstadoPago(String docId, String estadoActual) async {
    String nuevoEstado = (estadoActual == 'PAGADO') ? 'PENDIENTE' : 'PAGADO';
    await FirebaseFirestore.instance.collection('gastos').doc(docId).update({
      'estado_pago': nuevoEstado,
    });
  }

  Future<void> _registrarDeuda(String coleccion, String tipo) async {
    if (_clienteDeudaController.text.isEmpty ||
        _montoDeudaController.text.isEmpty)
      return;
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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("✅ $tipo AGREGADO")));
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _liquidarDeuda(
    String coleccion,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      if (coleccion == 'cxp') {
        _conceptoController.text =
            "PAGO A: ${data['entidad']} - ${data['motivo'] ?? ''}";
        _montoController.text = data['monto'].toString();
        await _registrarSalida('CxP-Liquidada');
        await FirebaseFirestore.instance.collection('cxp').doc(docId).update({
          'estado': 'PAGADO',
        });
      } else {
        // CXC: Cobrar y generar recibo sin navegar
        await FirebaseFirestore.instance.collection('cxc').doc(docId).update({
          'estado': 'COBRADO',
        });
        await FirebaseFirestore.instance.collection('recibos').add({
          'cliente_id': data['entidad'],
          'modelo_vehiculo': 'S/D',
          'placa_vehiculo': 'S/P',
          'total_reparacion': data['monto'],
          'fecha_emision_recibo': FieldValue.serverTimestamp(),
          'estado_facturacion': 'PENDIENTE',
          'numero_recibo': '',
          'notas': data['motivo'] ?? 'Cobro Deuda',
          'presupuesto_items': [
            {
              'item': data['motivo'] ?? 'COBRO DEUDA',
              'cantidad': 1,
              'precio_unitario': data['monto'],
              'subtotal': data['monto'],
            },
          ],
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ COBRADO (Recibo generado en segundo plano)"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error al liquidar: $e");
    }
  }

  Future<void> _editarRegistro(
    String coleccion,
    String docId,
    Map<String, dynamic> data,
  ) async {
    TextEditingController editEntidad = TextEditingController(
      text: data['entidad'] ?? data['motivo'],
    );
    TextEditingController editMotivo = TextEditingController(
      text: data['motivo'] ?? "",
    );
    TextEditingController editMonto = TextEditingController(
      text: data['monto'].toString(),
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBlack,
        title: const Text(
          "Editar Registro",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editEntidad,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Entidad / Cliente"),
            ),
            TextField(
              controller: editMotivo,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Concepto"),
            ),
            TextField(
              controller: editMonto,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Monto \$"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection(coleccion)
                  .doc(docId)
                  .update({
                    'entidad': editEntidad.text.toUpperCase(),
                    'motivo': editMotivo.text.toUpperCase(),
                    'monto': double.parse(editMonto.text),
                  });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("GUARDAR"),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarDocumento(String coleccion, String docId) async {
    bool confirmar =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: cardBlack,
            title: const Text(
              "¿Eliminar?",
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("NO"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("SÍ", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmar)
      await FirebaseFirestore.instance
          .collection(coleccion)
          .doc(docId)
          .delete();
  }

  // --- CÁLCULO DE FINANZAS (Incluye Deudas para el Resumen) ---
  void _calcularBalance(
    List<QueryDocumentSnapshot> ventas,
    List<QueryDocumentSnapshot> gastos,
    List<QueryDocumentSnapshot> cxp,
  ) {
    double vEfe = 0, vZel = 0, vBan = 0;
    double gEfe = 0, gZel = 0, gBan = 0;

    // 1. DINERO (Ventas)
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

    // Reiniciar contadores de deuda
    _deudaNomina = 0;
    _deudaTecnicos = 0;
    _deudaProveedores = 0;

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
        // Sumar a deudas si está pendiente
        if (categoria == 'Nomina')
          _deudaNomina += m;
        else if (categoria == 'Tecnico')
          _deudaTecnicos += m;
      }
    }

    // Deuda Proveedores
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
    // Length 6: Gastos, CxC, CxP, Nomina, Tecnicos, RESUMEN (al final)
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: bgDark,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(60.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 50),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('ventas')
                    .snapshots(),
                builder: (context, ventasSnap) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('gastos')
                        .orderBy('fecha', descending: true)
                        .snapshots(),
                    builder: (context, gastosSnap) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('cxp')
                            .orderBy('fecha', descending: true)
                            .snapshots(),
                        builder: (context, cxpSnap) {
                          if (!ventasSnap.hasData ||
                              !gastosSnap.hasData ||
                              !cxpSnap.hasData)
                            return const Center(
                              child: CircularProgressIndicator(),
                            );

                          var vF = ventasSnap.data!.docs
                              .where(
                                (doc) => _esFechaValida(
                                  (doc.data()
                                              as Map<
                                                String,
                                                dynamic
                                              >)['fecha_venta']
                                          ?.toDate() ??
                                      DateTime(2000),
                                ),
                              )
                              .toList();
                          var gF = gastosSnap.data!.docs
                              .where(
                                (doc) => _esFechaValida(
                                  (doc.data() as Map<String, dynamic>)['fecha']
                                          ?.toDate() ??
                                      DateTime(2000),
                                ),
                              )
                              .toList();
                          var cxpTotal = cxpSnap.data!.docs;

                          var gOp = gF
                              .where(
                                (d) =>
                                    (d.data() as Map)['categoria'] ==
                                        'Operativo' ||
                                    (d.data() as Map)['categoria'] == null,
                              )
                              .toList();
                          var gNo = gF
                              .where(
                                (d) =>
                                    (d.data() as Map)['categoria'] == 'Nomina',
                              )
                              .toList();
                          var gTe = gF
                              .where(
                                (d) =>
                                    (d.data() as Map)['categoria'] == 'Tecnico',
                              )
                              .toList();

                          _calcularBalance(vF, gastosSnap.data!.docs, cxpTotal);

                          return Column(
                            children: [
                              Row(
                                children: [
                                  _buildBalanceCard(
                                    "CAJA EFECTIVO",
                                    _balEfectivo,
                                    Icons.attach_money,
                                    Colors.green,
                                  ),
                                  const SizedBox(width: 30),
                                  _buildBalanceCard(
                                    "CUENTA ZELLE",
                                    _balZelle,
                                    Icons.phonelink_ring,
                                    Colors.purpleAccent,
                                  ),
                                  const SizedBox(width: 30),
                                  _buildBalanceCard(
                                    "BANCO NACIONAL",
                                    _balBanco,
                                    Icons.account_balance,
                                    Colors.blueAccent,
                                  ),
                                  const SizedBox(width: 30),
                                  _buildBalanceCard(
                                    "TOTAL NETO",
                                    (_balEfectivo + _balZelle + _balBanco),
                                    Icons.savings,
                                    Colors.amber,
                                    isTotal: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 50),
                              _buildTabBar(),
                              const SizedBox(height: 30),
                              SizedBox(
                                height: 1000,
                                child: TabBarView(
                                  children: [
                                    _tabGenerico(
                                      gOp,
                                      "Operativo",
                                      Icons.shopping_cart,
                                    ),
                                    _tabDeudas(
                                      "cxc",
                                      "Cliente",
                                      Icons.assignment_return,
                                      Colors.blue,
                                    ),
                                    _tabDeudas(
                                      "cxp",
                                      "Proveedor",
                                      Icons.assignment_late,
                                      Colors.orange,
                                    ),
                                    _tabGenerico(gNo, "Nomina", Icons.badge),
                                    _tabGenerico(
                                      gTe,
                                      "Tecnico",
                                      Icons.engineering,
                                    ),
                                    // PESTAÑA RESUMEN AL FINAL
                                    _buildTabResumen(),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET DE RESUMEN (Pestaña Final) ---
  Widget _buildTabResumen() {
    double proyeccion = _totalDisponible - _totalDeuda;
    Color colorProyeccion = proyeccion >= 0 ? softGreen : dangerRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "RESUMEN Y PROYECCIÓN",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildResumenCard(
                "DISPONIBLE REAL",
                _totalDisponible,
                softGreen,
                Icons.account_balance_wallet,
                detalles: [
                  _rowDetalle("Efectivo", _balEfectivo),
                  _rowDetalle("Zelle", _balZelle),
                  _rowDetalle("Banco", _balBanco),
                ],
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: _buildResumenCard(
                "DEUDA TOTAL",
                _totalDeuda,
                Colors.orangeAccent,
                Icons.money_off,
                detalles: [
                  _rowDetalle("Nómina Pendiente", _deudaNomina),
                  _rowDetalle("Técnicos Pendiente", _deudaTecnicos),
                  _rowDetalle("Proveedores (CxP)", _deudaProveedores),
                ],
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: _buildResumenCard(
                "SALDO SI PAGAS TODO",
                proyeccion,
                colorProyeccion,
                proyeccion >= 0 ? Icons.check_circle : Icons.warning,
                isProyeccion: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResumenCard(
    String titulo,
    double monto,
    Color color,
    IconData icon, {
    List<Widget>? detalles,
    bool isProyeccion = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 15),
              Text(
                titulo,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Text(
            "\$${monto.toStringAsFixed(2)}",
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (detalles != null || isProyeccion) ...[
            const SizedBox(height: 25),
            const Divider(color: Colors.white10),
            const SizedBox(height: 15),
          ],
          if (detalles != null) ...detalles,
          if (isProyeccion)
            Text(
              monto >= 0
                  ? "Excelente. Tienes capacidad para cubrir todas tus obligaciones pendientes hoy."
                  : "ATENCIÓN. Tus deudas superan el dinero disponible. Se requiere inyección de capital o cobranza.",
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _rowDetalle(String label, double val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          Text(
            "\$${val.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "CONTROL DE CAJA CHICA",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              "Gestión financiera operativa",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
        _buildFiltroFechaBadge(),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        isScrollable: false,
        indicatorColor: softGreen,
        labelColor: softGreen,
        unselectedLabelColor: Colors.white38,
        tabs: const [
          Tab(text: "GASTOS"),
          Tab(text: "POR COBRAR"),
          Tab(text: "POR PAGAR"),
          Tab(text: "NÓMINA"),
          Tab(text: "TÉCNICOS"),
          Tab(text: "RESUMEN", icon: Icon(Icons.analytics)), // Pestaña al final
        ],
      ),
    );
  }

  Widget _buildTecnicoSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mecanicos')
          .orderBy('nombre')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var items = snapshot.data!.docs
            .map(
              (doc) => DropdownMenuItem<String>(
                value: (doc.data() as Map)['nombre'].toString(),
                child: Text((doc.data() as Map)['nombre'].toString()),
              ),
            )
            .toList();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: inputFill,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              hint: const Text(
                "SELECCIONE TÉCNICO",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              value: _tecnicoSeleccionado,
              dropdownColor: cardBlack,
              isExpanded: true,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              items: items,
              onChanged: (v) => setState(() {
                _tecnicoSeleccionado = v;
                _conceptoController.text = v ?? "";
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _tabGenerico(
    List<QueryDocumentSnapshot> docs,
    String cat,
    IconData icon,
  ) {
    double total = docs
        .where((d) => (d.data() as Map)['estado_pago'] == 'PAGADO')
        .fold(0, (p, d) => p + (d['monto'] ?? 0));
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          decoration: BoxDecoration(
            color: cardBlack,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: cat == 'Tecnico'
                    ? _buildTecnicoSelector()
                    : _buildInput(
                        cat == "Nomina" ? "EMPLEADO" : "CONCEPTO",
                        _conceptoController,
                        icon,
                      ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 2,
                child: _buildInput(
                  "MONTO \$",
                  _montoController,
                  Icons.attach_money,
                  isNum: true,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(flex: 2, child: _buildDropdown()),
              const SizedBox(width: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: softGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 25,
                  ),
                ),
                onPressed: () => _registrarSalida(cat),
                child: const Text(
                  "AGREGAR",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        _totalRow("TOTAL $cat (LIQUIDADO)", total),
        const SizedBox(height: 15),
        Expanded(
          child: ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              var d = docs[i].data() as Map<String, dynamic>;
              // PASAMOS cat PARA EL SWITCH
              return _buildRecordRow(
                'gastos',
                docs[i].id,
                d,
                icon,
                categoriaContext: cat,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _tabDeudas(String col, String label, IconData icon, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(col)
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var docs = snapshot.data!.docs;
        var docsPendientes = docs
            .where((d) => (d.data() as Map)['estado'] == 'PENDIENTE')
            .toList();
        double total = docsPendientes.fold(0, (p, d) => p + (d['monto'] ?? 0));

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              decoration: BoxDecoration(
                color: cardBlack,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildInput(
                      label.toUpperCase(),
                      _clienteDeudaController,
                      Icons.person,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 3,
                    child: _buildInput(
                      "CONCEPTO",
                      _conceptoDeudaController,
                      Icons.edit,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 2,
                    child: _buildInput(
                      "MONTO \$",
                      _montoDeudaController,
                      Icons.attach_money,
                      isNum: true,
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 25,
                      ),
                    ),
                    onPressed: () => _registrarDeuda(
                      col,
                      col == 'cxc' ? 'Por Cobrar' : 'Por Pagar',
                    ),
                    child: const Text(
                      "AGREGAR",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _totalRow(
              "PENDIENTE POR ${label.toUpperCase()}",
              total,
              color: color,
            ),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: docsPendientes.length,
                itemBuilder: (context, i) {
                  var d = docsPendientes[i].data() as Map<String, dynamic>;
                  return _buildRecordRow(
                    col,
                    docsPendientes[i].id,
                    d,
                    icon,
                    isDeuda: true,
                    color: color,
                    categoriaContext: 'Deuda',
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecordRow(
    String col,
    String id,
    Map<String, dynamic> d,
    IconData icon, {
    bool isDeuda = false,
    Color? color,
    String? categoriaContext,
  }) {
    bool pagado = isDeuda
        ? (d['estado'] != 'PENDIENTE')
        : (d['estado_pago'] == 'PAGADO');
    DateTime f = (d['fecha'] as Timestamp).toDate();

    // LÓGICA DE SWITCH: Solo en Nomina o Tecnico (NO en Gastos Operativos, NO en Deudas)
    bool mostrarSwitch =
        !isDeuda &&
        (categoriaContext == 'Nomina' || categoriaContext == 'Tecnico');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: inputFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: pagado ? Colors.green : (color ?? softGreen),
            size: 18,
          ),
          const SizedBox(width: 15),
          Text(
            DateFormat('dd/MM').format(f),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              isDeuda
                  ? "${d['entidad']}  •  ${d['motivo'] ?? ''}"
                  : "${d['motivo']}  •  [${d['fuente']}]",
              style: TextStyle(
                color: pagado ? Colors.white24 : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (mostrarSwitch)
            Text(
              pagado ? "PAGADO" : "PENDIENTE",
              style: TextStyle(
                color: pagado ? Colors.green : Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),

          const SizedBox(width: 15),
          Text(
            "\$${(d['monto'] ?? 0).toStringAsFixed(2)}",
            style: TextStyle(
              color: pagado ? Colors.white24 : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 20),

          if (mostrarSwitch)
            Transform.scale(
              scale: 0.7,
              child: Switch(
                value: pagado,
                activeThumbColor: Colors.green,
                onChanged: (val) =>
                    _toggleEstadoPago(id, d['estado_pago'] ?? 'PAGADO'),
              ),
            ),

          if (isDeuda && !pagado)
            IconButton(
              icon: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
              onPressed: () => _liquidarDeuda(col, id, d),
              tooltip: "Cobrar/Pagar",
            ),

          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
            onPressed: () => _editarRegistro(col, id, d),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.white24,
              size: 18,
            ),
            onPressed: () => _eliminarDocumento(col, id),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double val, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (color ?? softGreen).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (color ?? softGreen).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            "\$${val.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
    String t,
    double a,
    IconData i,
    Color c, {
    bool isTotal = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: isTotal ? c.withValues(alpha: 0.1) : cardBlack,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isTotal ? c : Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(i, color: c, size: 20),
                const SizedBox(width: 10),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      t,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "\$${a.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    String l,
    TextEditingController c,
    IconData i, {
    bool isNum = false,
  }) {
    return TextField(
      controller: c,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: l,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        prefixIcon: Icon(i, color: softGreen, size: 18),
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: inputFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _fuenteSeleccionada,
          dropdownColor: cardBlack,
          isExpanded: true,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          items: [
            'Efectivo',
            'Zelle',
            'Banco',
          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _fuenteSeleccionada = v!),
        ),
      ),
    );
  }

  Widget _buildFiltroFechaBadge() {
    return PopupMenuButton<String>(
      color: cardBlack,
      onSelected: _aplicarFiltroPredefinido,
      itemBuilder: (ctx) => ["Hoy", "Ayer", "Este Mes", "Mes Pasado"]
          .map(
            (t) => PopupMenuItem(
              value: t,
              child: Text(t, style: const TextStyle(color: Colors.white)),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        decoration: BoxDecoration(
          color: cardBlack,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: softGreen, size: 18),
            const SizedBox(width: 12),
            Text(
              _filtroSeleccionado.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
