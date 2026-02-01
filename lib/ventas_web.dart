import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VentasWebModule extends StatefulWidget {
  final Map<String, dynamic>? datosRecibo;
  final String? idRecibo;

  const VentasWebModule({super.key, this.datosRecibo, this.idRecibo});

  @override
  State<VentasWebModule> createState() => _VentasWebModuleState();
}

class _VentasWebModuleState extends State<VentasWebModule> {
  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);
  final Color bgDark = const Color(0xFF050505);

  String _metodoPago = "Transferencia";
  
  // Controlador de texto (Se usa para capturar las notas)
  final TextEditingController _notasController = TextEditingController();
  
  // Variables de Filtro
  String _filtroTexto = "";
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _filtroRapidoSeleccionado = "todos"; 

  @override
  Widget build(BuildContext context) {
    if (widget.datosRecibo != null) {
      return _buildFormularioCierreVenta(); 
    } else {
      return _buildDashboardHistorial(); 
    }
  }

  // --- NUEVA FUNCIÓN: ELIMINAR VENTA ---
  Future<void> _eliminarVenta(String docId) async {
    bool confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBlack,
        title: const Text("¿Eliminar Venta?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Esta acción eliminará el registro financiero permanentemente.", 
          style: TextStyle(color: Colors.white70)
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      )
    ) ?? false;

    if (confirmar) {
      try {
        await FirebaseFirestore.instance.collection('ventas').doc(docId).delete();
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🗑️ Venta eliminada")));
      } catch (e) {
        debugPrint("Error: $e");
      }
    }
  }

  // --- NUEVA FUNCIÓN: EDITAR VENTA (Método y Notas) ---
  Future<void> _editarVenta(String docId, Map<String, dynamic> data) async {
    String metodoEdit = data['metodo_pago'] ?? "Transferencia";
    TextEditingController notasEdit = TextEditingController(text: data['notas_venta'] ?? "");

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return AlertDialog(
            backgroundColor: cardBlack,
            title: const Text("Editar Datos de Venta", style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: metodoEdit,
                  dropdownColor: inputFill,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Método de Pago", labelStyle: TextStyle(color: Colors.white54)),
                  items: ["Efectivo", "Transferencia", "Zelle", "Pago Móvil", "Tarjeta", "Binance"]
                      .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setStateModal(() => metodoEdit = v!),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: notasEdit,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Notas / Referencia", labelStyle: TextStyle(color: Colors.white54)),
                )
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('ventas').doc(docId).update({
                    'metodo_pago': metodoEdit,
                    'notas_venta': notasEdit.text,
                  });
                  Navigator.pop(ctx);
                  if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Venta actualizada")));
                }, 
                child: const Text("GUARDAR", style: TextStyle(color: Colors.white))
              ),
            ],
          );
        }
      )
    );
  }

  // ==========================================
  // VISTA 1: DASHBOARD HISTORIAL DE VENTAS
  // ==========================================
  Widget _buildDashboardHistorial() {
    return Scaffold(
      backgroundColor: bgDark,
      body: Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER Y FILTROS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("REPORTE DE INGRESOS", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    _buildSubtituloFiltro(),
                  ],
                ),
                Row(
                  children: [
                    // Buscador de Texto
                    Container(
                      width: 250,
                      height: 45,
                      decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(10)),
                      child: TextField(
                        onChanged: (val) => setState(() => _filtroTexto = val.toUpperCase()),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search, color: Colors.white38),
                          hintText: "Buscar cliente...",
                          hintStyle: TextStyle(color: Colors.white24),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(top: 8)
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    
                    // BOTÓN DE FILTRO DE FECHAS
                    InkWell(
                      onTap: _mostrarDialogoFiltro,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 45,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: _filtroRapidoSeleccionado != "todos" ? brandRed : inputFill,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12)
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(_filtroRapidoSeleccionado == "todos" ? "Filtrar Fecha" : "Filtro Activo", 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    if (_filtroRapidoSeleccionado != "todos") 
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        tooltip: "Borrar filtros",
                        onPressed: () {
                          setState(() {
                            _filtroRapidoSeleccionado = "todos";
                            _fechaInicio = null;
                            _fechaFin = null;
                          });
                        },
                      )
                  ],
                )
              ],
            ),
            const SizedBox(height: 30),

            // LISTA DE VENTAS
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('ventas').orderBy('fecha_venta', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  var docs = snapshot.data!.docs;
                  
                  double totalIngresos = 0;
                  double totalGanancias = 0;
                  int cantidadVentas = 0;

                  // LÓGICA DE FILTRADO
                  var docsFiltrados = docs.where((d) {
                    var data = d.data() as Map<String, dynamic>;
                    
                    // 1. Filtro Texto
                    String key = "${data['cliente_id']} ${data['placa_vehiculo']} ${data['modelo_vehiculo']}".toUpperCase();
                    bool matchTexto = key.contains(_filtroTexto);

                    // 2. Filtro Fecha
                    bool matchFecha = true;
                    if (_fechaInicio != null && _fechaFin != null && data['fecha_venta'] != null) {
                      DateTime fechaVenta = (data['fecha_venta'] as Timestamp).toDate();
                      DateTime fVenta = DateTime(fechaVenta.year, fechaVenta.month, fechaVenta.day);
                      DateTime fInicio = DateTime(_fechaInicio!.year, _fechaInicio!.month, _fechaInicio!.day);
                      DateTime fFin = DateTime(_fechaFin!.year, _fechaFin!.month, _fechaFin!.day);
                      
                      // Comparación inclusiva
                      matchFecha = (fVenta.isAtSameMomentAs(fInicio) || fVenta.isAfter(fInicio)) && 
                                   (fVenta.isAtSameMomentAs(fFin) || fVenta.isBefore(fFin));
                    }

                    if (matchTexto && matchFecha) {
                      totalIngresos += (data['total_reparacion'] ?? 0).toDouble();
                      totalGanancias += (data['ganancia_estimada'] ?? 0).toDouble();
                      cantidadVentas++;
                    }
                    return matchTexto && matchFecha;
                  }).toList();

                  return Column(
                    children: [
                      // Tarjetas KPI
                      Row(
                        children: [
                          _kpiCard("VENTAS", cantidadVentas.toString(), Colors.blueAccent),
                          const SizedBox(width: 20),
                          _kpiCard("INGRESOS", "\$${totalIngresos.toStringAsFixed(2)}", Colors.green),
                          const SizedBox(width: 20),
                          _kpiCard("GANANCIA", "\$${totalGanancias.toStringAsFixed(2)}", Colors.purpleAccent, isBold: true),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Tabla Encabezados
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            _headerCell("FECHA", flex: 2),
                            _headerCell("CLIENTE", flex: 3),
                            _headerCell("MÉTODO", flex: 2),
                            _headerCell("TOTAL", flex: 2, align: TextAlign.right),
                            _headerCell("GANANCIA", flex: 2, align: TextAlign.right),
                            _headerCell("ACCIONES", flex: 2, align: TextAlign.center), // NUEVA COLUMNA
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Filas de la Tabla
                      Expanded(
                        child: ListView.separated(
                          itemCount: docsFiltrados.length,
                          separatorBuilder: (c, i) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            var data = docsFiltrados[index].data() as Map<String, dynamic>;
                            // Pasamos el ID del documento para poder editar/borrar
                            return _buildVentaRow(docsFiltrados[index].id, data); 
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET DIÁLOGO DE FILTRO ---
  void _mostrarDialogoFiltro() {
    DateTime now = DateTime.now();
    String tempSeleccion = _filtroRapidoSeleccionado;
    DateTime? tempInicio = _fechaInicio;
    DateTime? tempFin = _fechaFin;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              backgroundColor: cardBlack,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              title: const Text("Filtrar por Período", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRadioOption("Todos los tiempos", "todos", tempSeleccion, (val) {
                      setStateModal(() { tempSeleccion = val!; tempInicio = null; tempFin = null; });
                    }),
                    _buildRadioOption("Hoy", "hoy", tempSeleccion, (val) {
                      setStateModal(() { tempSeleccion = val!; tempInicio = now; tempFin = now; });
                    }),
                    _buildRadioOption("Últimos 7 días", "semana", tempSeleccion, (val) {
                      setStateModal(() { tempSeleccion = val!; tempInicio = now.subtract(const Duration(days: 7)); tempFin = now; });
                    }),
                    _buildRadioOption("Este mes", "mes_actual", tempSeleccion, (val) {
                      setStateModal(() { 
                        tempSeleccion = val!; 
                        tempInicio = DateTime(now.year, now.month, 1); 
                        tempFin = DateTime(now.year, now.month + 1, 0); 
                      });
                    }),
                    _buildRadioOption("Mes pasado", "mes_anterior", tempSeleccion, (val) {
                      setStateModal(() { 
                        tempSeleccion = val!; 
                        tempInicio = DateTime(now.year, now.month - 1, 1); 
                        tempFin = DateTime(now.year, now.month, 0); 
                      });
                    }),
                    const Divider(color: Colors.white10, height: 30),
                    const Text("Rango Personalizado", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              DateTime? picked = await showDatePicker(context: context, initialDate: tempInicio ?? now, firstDate: DateTime(2020), lastDate: DateTime.now());
                              if (picked != null) setStateModal(() => tempInicio = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)),
                              child: Text(tempInicio != null ? DateFormat('dd/MM/yyyy').format(tempInicio!) : "Inicio", style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              DateTime? picked = await showDatePicker(context: context, initialDate: tempFin ?? now, firstDate: DateTime(2020), lastDate: DateTime.now());
                              if (picked != null) setStateModal(() => tempFin = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)),
                              child: Text(tempFin != null ? DateFormat('dd/MM/yyyy').format(tempFin!) : "Fin", style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.white54))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: brandRed),
                  onPressed: () {
                    setState(() {
                      _filtroRapidoSeleccionado = tempSeleccion;
                      _fechaInicio = tempInicio;
                      _fechaFin = tempFin;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Aplicar Filtro", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          },
        );
      },
    );
  }

  // --- SOLUCIÓN ERROR DEPRECATED: Radio Manual con Iconos ---
  Widget _buildRadioOption(String label, String value, String groupValue, Function(String?) onChanged) {
    bool isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? brandRed : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtituloFiltro() {
    String texto = "Mostrando todas las ventas";
    if (_fechaInicio != null && _fechaFin != null) {
      texto = "Del ${DateFormat('dd/MM').format(_fechaInicio!)} al ${DateFormat('dd/MM').format(_fechaFin!)}";
    }
    return Text(texto, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12));
  }

  // ==========================================
  // VISTA 2: FORMULARIO DE CIERRE
  // ==========================================
  Widget _buildFormularioCierreVenta() {
    final data = widget.datosRecibo!;
    double ingreso = (data['total_reparacion'] ?? 0).toDouble();
    double costo = (data['total_costo'] ?? 0).toDouble();
    double ganancia = (data['ganancia_estimada'] ?? 0).toDouble();
    double margen = ingreso > 0 ? (ganancia / ingreso) * 100 : 0;

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: cardBlack,
        title: const Text("CERRAR VENTA", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            // Resumen Financiero
            Row(
              children: [
                _financialCard("TOTAL VENTA", ingreso, Colors.blue),
                const SizedBox(width: 20),
                _financialCard("COSTOS", costo, Colors.orange),
                const SizedBox(width: 20),
                _financialCard("GANANCIA", ganancia, Colors.green),
              ],
            ),
            const SizedBox(height: 20),
            Text("Margen: ${margen.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white54)),
            const Spacer(),
            
            _infoTitle("MÉTODO DE PAGO"),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(10)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _metodoPago,
                  dropdownColor: inputFill,
                  style: const TextStyle(color: Colors.white),
                  isExpanded: true,
                  items: ["Efectivo", "Transferencia", "Zelle", "Pago Móvil", "Tarjeta", "Binance"].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() => _metodoPago = v!),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Campo de Notas
            TextField(
              controller: _notasController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Notas / Referencia",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
              ),
            ),
            const SizedBox(height: 20),

            // Botón Confirmar
            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: _procesarVentaFinal,
                child: const Text("CONFIRMAR VENTA", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _procesarVentaFinal() async {
    try {
      await FirebaseFirestore.instance.collection('ventas').add({
        ...widget.datosRecibo!,
        'fecha_venta': FieldValue.serverTimestamp(),
        'metodo_pago': _metodoPago,
        'notas_venta': _notasController.text,
        'estatus_venta': 'CERRADA',
      });
      
      if (widget.idRecibo != null) {
        await FirebaseFirestore.instance.collection('recibos').doc(widget.idRecibo).update({'estado_facturacion': 'VENDIDO'});
      }
      
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Venta registrada"), backgroundColor: Colors.purple));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // --- WIDGETS AUXILIARES ---
  Widget _kpiCard(String label, String value, Color color, {bool isBold = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(value, style: TextStyle(color: Colors.white, fontSize: isBold ? 24 : 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildVentaRow(String docId, Map<String, dynamic> data) {
    DateTime fecha = data['fecha_venta'] != null ? (data['fecha_venta'] as Timestamp).toDate() : DateTime.now();
    double total = (data['total_reparacion'] ?? 0).toDouble();
    double ganancia = (data['ganancia_estimada'] ?? 0).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Row(children: [
        Expanded(flex: 2, child: Text(DateFormat('dd/MM HH:mm').format(fecha), style: const TextStyle(color: Colors.white54, fontSize: 12))),
        
        // COLUMNA NOMBRE CLIENTE
        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _NombreClienteWidget(clienteId: data['cliente_id']),
          Text("${data['modelo_vehiculo']} - ${data['placa_vehiculo']}", style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ])),
        
        Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(5)), child: Text(data['metodo_pago'] ?? "N/A", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11)))),
        Expanded(flex: 2, child: Text("\$${total.toStringAsFixed(2)}", textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Text("\$${ganancia.toStringAsFixed(2)}", textAlign: TextAlign.right, style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold))),
        
        // COLUMNA ACCIONES (Editar y Eliminar)
        Expanded(flex: 2, child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18), 
              onPressed: () => _editarVenta(docId, data),
              tooltip: "Editar Datos",
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18), 
              onPressed: () => _eliminarVenta(docId),
              tooltip: "Eliminar Venta",
            ),
          ],
        )),
      ]),
    );
  }

  Widget _infoTitle(String text) => Text(text, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1));
  
  Widget _headerCell(String text, {int flex = 1, TextAlign align = TextAlign.left}) => Expanded(flex: flex, child: Text(text, textAlign: align, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)));

  Widget _financialCard(String label, double amount, Color color, {bool isBig = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("\$${amount.toStringAsFixed(2)}", style: TextStyle(color: Colors.white, fontSize: isBig ? 28 : 22, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET PARA MOSTRAR NOMBRE EN VENTAS ---
class _NombreClienteWidget extends StatelessWidget {
  final String? clienteId;
  const _NombreClienteWidget({required this.clienteId});

  @override
  Widget build(BuildContext context) {
    if (clienteId == null) return const Text("S/N", style: TextStyle(color: Colors.white38));

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('clientes').doc(clienteId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1));
        
        if (snapshot.hasData && snapshot.data!.exists) {
          String nombre = snapshot.data!.get('nombre') ?? "Cliente";
          return Text(nombre.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
        }
        return Text(clienteId!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
      },
    );
  }
}