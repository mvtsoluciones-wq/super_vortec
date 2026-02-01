import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CajaChicaWebModule extends StatefulWidget {
  const CajaChicaWebModule({super.key});

  @override
  State<CajaChicaWebModule> createState() => _CajaChicaWebModuleState();
}

class _CajaChicaWebModuleState extends State<CajaChicaWebModule> {
  // --- PALETA DE COLORES ---
  final Color softGreen = const Color(0xFF66BB6A); 
  final Color cardBlack = const Color(0xFF101010);
  final Color bgDark = Colors.black; 
  final Color inputFill = const Color(0xFF1E1E1E);

  // --- CONTROLADORES ---
  final TextEditingController _conceptoController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  String _fuenteSeleccionada = 'Efectivo';
  String? _tecnicoSeleccionado;

  final TextEditingController _clienteDeudaController = TextEditingController();
  final TextEditingController _montoDeudaController = TextEditingController();

  // --- FILTROS ---
  String _filtroSeleccionado = "Este Mes";
  late DateTimeRange _rangoFechas;

  double _balEfectivo = 0.0;
  double _balZelle = 0.0;
  double _balBanco = 0.0;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    _rangoFechas = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59), 
    );
  }

  // --- MÉTODOS DE FILTRO ---
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

  // --- OPERACIONES FIREBASE ---

  Future<void> _registrarSalida(String categoria) async {
    if (_conceptoController.text.isEmpty || _montoController.text.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('gastos').add({
        'fecha': DateTime.now(),
        'motivo': _conceptoController.text.toUpperCase(),
        'monto': double.parse(_montoController.text),
        'fuente': _fuenteSeleccionada,
        'categoria': categoria,
        'estado_pago': 'PAGADO', // Por defecto se crea como pagado
        'creado_en': FieldValue.serverTimestamp(),
      });
      _conceptoController.clear();
      _montoController.clear();
      setState(() { _tecnicoSeleccionado = null; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ REGISTRADO"), duration: Duration(seconds: 1)));
    } catch (e) { debugPrint("Error: $e"); }
  }

  // Cambiar estado de pago (Suiche)
  Future<void> _toggleEstadoPago(String docId, String estadoActual) async {
    String nuevoEstado = (estadoActual == 'PAGADO') ? 'PENDIENTE' : 'PAGADO';
    await FirebaseFirestore.instance.collection('gastos').doc(docId).update({
      'estado_pago': nuevoEstado
    });
  }

  Future<void> _registrarDeuda(String coleccion, String tipo) async {
    if (_clienteDeudaController.text.isEmpty || _montoDeudaController.text.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection(coleccion).add({
        'fecha': DateTime.now(),
        'entidad': _clienteDeudaController.text.toUpperCase(),
        'monto': double.parse(_montoDeudaController.text),
        'estado': 'PENDIENTE',
        'tipo': tipo,
        'creado_en': FieldValue.serverTimestamp(),
      });
      _clienteDeudaController.clear();
      _montoDeudaController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ $tipo AGREGADO"), duration: const Duration(seconds: 1)));
    } catch (e) { debugPrint("Error: $e"); }
  }

  Future<void> _liquidarDeuda(String coleccion, String docId, Map<String, dynamic> data) async {
    if (coleccion == 'cxp') {
      _conceptoController.text = "PAGO A: ${data['entidad']}";
      _montoController.text = data['monto'].toString();
      await _registrarSalida('CxP-Liquidada');
      await FirebaseFirestore.instance.collection('cxp').doc(docId).update({'estado': 'PAGADO'});
    } else {
      await FirebaseFirestore.instance.collection('cxc').doc(docId).update({'estado': 'COBRADO'});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ COBRADO"), backgroundColor: Colors.green));
    }
  }

  Future<void> _editarRegistro(String coleccion, String docId, Map<String, dynamic> data) async {
    TextEditingController editMotivo = TextEditingController(text: data['motivo'] ?? data['entidad']);
    TextEditingController editMonto = TextEditingController(text: data['monto'].toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBlack,
        title: const Text("Editar Registro", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                coleccion == 'gastos' ? 'motivo' : 'entidad': editMotivo.text.toUpperCase(),
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

  // --- LÓGICA DE BALANCE (CORREGIDO: Descuenta solo si está pagado) ---
  void _calcularBalance(List<QueryDocumentSnapshot> ventas, List<QueryDocumentSnapshot> gastos) {
    double vEfe = 0, vZel = 0, vBan = 0;
    double gEfe = 0, gZel = 0, gBan = 0;
    
    for (var doc in ventas) {
      var d = doc.data() as Map<String, dynamic>;
      double m = (d['total_reparacion'] ?? 0).toDouble();
      String met = (d['metodo_pago'] ?? "").toString().toUpperCase();
      if (met.contains("EFECTIVO")) vEfe += m;
      else if (met.contains("ZELLE") || met.contains("BINANCE")) vZel += m;
      else vBan += m;
    }

    for (var doc in gastos) {
      var d = doc.data() as Map<String, dynamic>;
      // VERIFICACIÓN CLAVE: Solo resta si estado_pago es 'PAGADO'
      String estado = d['estado_pago'] ?? 'PAGADO';
      if (estado == 'PAGADO') {
        double m = (d['monto'] ?? 0).toDouble();
        String f = (d['fuente'] ?? "").toString();
        if (f == "Efectivo") gEfe += m;
        else if (f == "Zelle") gZel += m;
        else gBan += m;
      }
    }
    
    _balEfectivo = vEfe - gEfe;
    _balZelle = vZel - gZel;
    _balBanco = vBan - gBan;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: bgDark,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('ventas').snapshots(),
                builder: (context, ventasSnap) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('gastos').orderBy('fecha', descending: true).snapshots(),
                    builder: (context, gastosSnap) {
                      if (!ventasSnap.hasData || !gastosSnap.hasData) return const Center(child: CircularProgressIndicator());

                      var vF = ventasSnap.data!.docs.where((doc) => _esFechaValida((doc.data() as Map<String, dynamic>)['fecha_venta']?.toDate() ?? DateTime(2000))).toList();
                      var gD = gastosSnap.data!.docs.where((doc) => _esFechaValida((doc.data() as Map<String, dynamic>)['fecha']?.toDate() ?? DateTime(2000))).toList();

                      var gOp = gD.where((d) => (d.data() as Map)['categoria'] == 'Operativo' || (d.data() as Map)['categoria'] == null).toList();
                      var gNo = gD.where((d) => (d.data() as Map)['categoria'] == 'Nomina').toList();
                      var gTe = gD.where((d) => (d.data() as Map)['categoria'] == 'Tecnico').toList();

                      _calcularBalance(vF, gD);

                      return Column(
                        children: [
                          Row(
                            children: [
                              _buildBalanceCard("CAJA EFECTIVO", _balEfectivo, Icons.attach_money, Colors.green),
                              const SizedBox(width: 20),
                              _buildBalanceCard("CUENTA ZELLE", _balZelle, Icons.phonelink_ring, Colors.purpleAccent),
                              const SizedBox(width: 20),
                              _buildBalanceCard("BANCO NACIONAL", _balBanco, Icons.account_balance, Colors.blueAccent),
                              const SizedBox(width: 20),
                              _buildBalanceCard("TOTAL NETO", (_balEfectivo + _balZelle + _balBanco), Icons.savings, Colors.amber, isTotal: true),
                            ],
                          ),
                          const SizedBox(height: 40),
                          _buildTabBar(),
                          const SizedBox(height: 30),
                          SizedBox(
                            height: 800, 
                            child: TabBarView(
                              children: [
                                _tabGenerico(gOp, "Operativo", Icons.shopping_cart),
                                _tabDeudas("cxc", "Cliente", Icons.assignment_return, Colors.blue),
                                _tabDeudas("cxp", "Proveedor", Icons.assignment_late, Colors.orange),
                                _tabGenerico(gNo, "Nomina", Icons.badge),
                                _tabGenerico(gTe, "Tecnico", Icons.engineering),
                              ],
                            ),
                          ),
                        ],
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

  // --- UI COMPONENTS ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("CONTROL DE CAJA CHICA", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          Text("Gestión financiera operativa", style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ]),
        _buildFiltroFechaBadge(),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(10)),
      child: TabBar(
        isScrollable: false,
        indicatorColor: softGreen,
        labelColor: softGreen,
        unselectedLabelColor: Colors.white38,
        tabs: const [
          Tab(text: "GASTOS"), Tab(text: "POR COBRAR"), Tab(text: "POR PAGAR"), Tab(text: "NÓMINA"), Tab(text: "TÉCNICOS"),
        ],
      ),
    );
  }

  Widget _buildTecnicoSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('mecanicos').orderBy('nombre').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var items = snapshot.data!.docs.map((doc) => DropdownMenuItem<String>(value: (doc.data() as Map)['nombre'].toString(), child: Text((doc.data() as Map)['nombre'].toString()))).toList();
        return Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(10)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(hint: const Text("SELECCIONE TÉCNICO", style: TextStyle(color: Colors.white38, fontSize: 12)), value: _tecnicoSeleccionado, dropdownColor: cardBlack, isExpanded: true, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), items: items, onChanged: (v) => setState(() { _tecnicoSeleccionado = v; _conceptoController.text = v ?? ""; }))));
      }
    );
  }

  Widget _tabGenerico(List<QueryDocumentSnapshot> docs, String cat, IconData icon) {
    double total = docs.where((d) => (d.data() as Map)['estado_pago'] == 'PAGADO').fold(0, (p, d) => p + (d['monto'] ?? 0));
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(15)),
          child: Row(
            children: [
              Expanded(flex: 3, child: cat == 'Tecnico' ? _buildTecnicoSelector() : _buildInput(cat == "Nomina" ? "EMPLEADO" : "CONCEPTO", _conceptoController, icon)),
              const SizedBox(width: 15),
              Expanded(flex: 2, child: _buildInput("MONTO \$", _montoController, Icons.attach_money, isNum: true)),
              const SizedBox(width: 15),
              Expanded(flex: 2, child: _buildDropdown()),
              const SizedBox(width: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: softGreen, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25)),
                onPressed: () => _registrarSalida(cat),
                child: const Text("AGREGAR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              )
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
              return _buildRecordRow('gastos', docs[i].id, d, icon);
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
        var docs = snapshot.data!.docs;
        double total = docs.where((d) => d['estado'] == 'PENDIENTE').fold(0, (p, d) => p + (d['monto'] ?? 0));
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  Expanded(flex: 4, child: _buildInput(label.toUpperCase(), _clienteDeudaController, Icons.person)),
                  const SizedBox(width: 15),
                  Expanded(flex: 2, child: _buildInput("MONTO \$", _montoDeudaController, Icons.attach_money, isNum: true)),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25)),
                    onPressed: () => _registrarDeuda(col, col == 'cxc' ? 'Por Cobrar' : 'Por Pagar'),
                    child: const Text("AGREGAR DEUDA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            _totalRow("PENDIENTE POR ${label.toUpperCase()}", total, color: color),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  var d = docs[i].data() as Map<String, dynamic>;
                  return _buildRecordRow(col, docs[i].id, d, icon, isDeuda: true, color: color);
                },
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildRecordRow(String col, String id, Map<String, dynamic> d, IconData icon, {bool isDeuda = false, Color? color}) {
    // Para Gastos/Nomina/Tecnicos usamos 'estado_pago', para CXC/CXP usamos 'estado'
    bool pagado = isDeuda 
        ? (d['estado'] != 'PENDIENTE') 
        : (d['estado_pago'] == 'PAGADO');
    
    DateTime f = (d['fecha'] as Timestamp).toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: pagado ? Colors.green : (color ?? softGreen), size: 18),
          const SizedBox(width: 15),
          Text(DateFormat('dd/MM').format(f), style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              "${d['motivo'] ?? d['entidad']}${d['fuente'] != null ? ' • [${d['fuente']}]' : ''}", 
              style: TextStyle(color: pagado ? Colors.white70 : Colors.white, fontWeight: FontWeight.bold)
            )
          ),
          
          // --- NUEVO: INDICADOR DE ESTADO ---
          Text(
            pagado ? "PAGADO" : "PENDIENTE",
            style: TextStyle(color: pagado ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 15),

          Text("\$${(d['monto'] ?? 0).toStringAsFixed(2)}", style: TextStyle(color: pagado ? Colors.white70 : Colors.white, fontWeight: FontWeight.bold)),
          
          const SizedBox(width: 15),

          // --- NUEVO: SWITCH DE PAGADO (Solo para Gastos/Nomina/Tecnicos) ---
          if (!isDeuda)
            Transform.scale(
              scale: 0.7,
              child: Switch(
                value: pagado,
                activeColor: Colors.green,
                onChanged: (val) => _toggleEstadoPago(id, d['estado_pago'] ?? 'PAGADO'),
              ),
            ),

          if(isDeuda && !pagado) IconButton(icon: const Icon(Icons.check_circle, color: Colors.green, size: 20), onPressed: () => _liquidarDeuda(col, id, d)),
          
          IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18), onPressed: () => _editarRegistro(col, id, d)),
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 18), onPressed: () => _eliminarDocumento(col, id)),
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
        border: Border.all(color: (color ?? softGreen).withValues(alpha: 0.2))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // TEXTO DEL TOTAL EN BLANCO
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          Text("\$${val.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String t, double a, IconData i, Color c, {bool isTotal = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: isTotal ? c.withValues(alpha: 0.1) : cardBlack, borderRadius: BorderRadius.circular(15), border: Border.all(color: isTotal ? c : Colors.white10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(i, color: c, size: 18), const SizedBox(width: 10), 
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(t, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold))))
          ]),
          const SizedBox(height: 15),
          FittedBox(fit: BoxFit.scaleDown, child: Text("\$${a.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900))),
        ]),
      ),
    );
  }

  Widget _buildInput(String l, TextEditingController c, IconData i, {bool isNum = false}) {
    return TextField(
      controller: c, keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: l, labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
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

  Widget _buildFiltroFechaBadge() {
    return PopupMenuButton<String>(
      color: cardBlack, onSelected: _aplicarFiltroPredefinido,
      itemBuilder: (ctx) => ["Hoy", "Ayer", "Este Mes", "Mes Pasado"].map((t) => PopupMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white)))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white12)),
        child: Row(children: [Icon(Icons.calendar_today, color: softGreen, size: 18), const SizedBox(width: 12), Text(_filtroSeleccionado.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
      ),
    );
  }
}