import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistorialWebModule extends StatefulWidget {
  const HistorialWebModule({super.key});

  @override
  State<HistorialWebModule> createState() => _HistorialWebModuleState();
}

class _HistorialWebModuleState extends State<HistorialWebModule> {
  String _filtroNombre = "";
  String? _clienteSeleccionadoId; 
  String? _clienteSeleccionadoNombre;

  final Color brandRed = const Color(0xFFD50000);
  final Color cardBlack = const Color(0xFF101010);
  final Color inputFill = const Color(0xFF1E1E1E);

  // --- FUNCIÓN PARA ELIMINAR CON SEGURIDAD ---
  void _eliminarPresupuesto(String docId) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: cardBlack,
        title: const Text("¿ELIMINAR REGISTRO?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Esta acción es irreversible. ¿Desea continuar?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandRed),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(c);
              try {
                await FirebaseFirestore.instance.collection('diagnosticos').doc(docId).delete();
                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(const SnackBar(content: Text("✅ REGISTRO ELIMINADO"), backgroundColor: Colors.green));
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(content: Text("❌ ERROR AL ELIMINAR: $e"), backgroundColor: Colors.red));
              }
            },
            child: const Text("ELIMINAR"),
          )
        ],
      ),
    );
  }

  // --- FUNCIÓN PARA EDITAR PRESUPUESTO ---
  void _abrirEditorPresupuesto(String docId, Map<String, dynamic> data) {
    final TextEditingController editSistema = TextEditingController(text: data['sistema_reparar']);
    final TextEditingController editDesc = TextEditingController(text: data['descripcion_falla']);
    final TextEditingController editGarantia = TextEditingController(text: data['garantia']);
    
    List<Map<String, dynamic>> editItems = (data['presupuesto_items'] as List).map((item) => {
      'item': TextEditingController(text: item['item']),
      'descripcion': TextEditingController(text: item['descripcion']),
      'cantidad': TextEditingController(text: item['cantidad'].toString()),
      'precio_unitario': TextEditingController(text: item['precio_unitario'].toString()),
    }).toList();

    showDialog(
      context: context,
      builder: (diagCtx) => StatefulBuilder(
        builder: (diagCtx, setDialogState) => AlertDialog(
          backgroundColor: cardBlack,
          title: Text("EDITAR: ${data['modelo_vehiculo'] ?? 'TRABAJO'}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 850,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEditField("SISTEMA A REPARAR", editSistema),
                  const SizedBox(height: 15),
                  _buildEditField("DESCRIPCIÓN TÉCNICA", editDesc, maxLines: 3),
                  const SizedBox(height: 15),
                  _buildEditField("TIEMPO DE GARANTÍA", editGarantia),
                  const Divider(color: Colors.white10, height: 40),
                  const Text("DESGLOSE DE ÍTEMS", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  ...editItems.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var row = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: _buildTableInput(row['item'], "Item")),
                          const SizedBox(width: 5),
                          Expanded(flex: 3, child: _buildTableInput(row['descripcion'], "Descripción")),
                          const SizedBox(width: 5),
                          Expanded(flex: 1, child: _buildTableInput(row['cantidad'], "Cant", isNum: true)),
                          const SizedBox(width: 5),
                          Expanded(flex: 1, child: _buildTableInput(row['precio_unitario'], "\$", isNum: true)),
                          IconButton(icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 20), onPressed: () => setDialogState(() => editItems.removeAt(idx)))
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setDialogState(() => editItems.add({'item': TextEditingController(), 'descripcion': TextEditingController(), 'cantidad': TextEditingController(text: "1"), 'precio_unitario': TextEditingController()})),
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    label: const Text("AGREGAR OTRO ÍTEM", style: TextStyle(color: Colors.green)),
                  )
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(diagCtx), child: const Text("CANCELAR")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(diagCtx);
                double nuevoTotal = 0;
                List<Map<String, dynamic>> itemsParaSubir = editItems.map((e) {
                  double c = double.tryParse(e['cantidad'].text) ?? 0;
                  double p = double.tryParse(e['precio_unitario'].text) ?? 0;
                  nuevoTotal += (c * p);
                  return {'item': e['item'].text.toUpperCase(), 'descripcion': e['descripcion'].text.toUpperCase(), 'cantidad': c, 'precio_unitario': p, 'subtotal': c * p};
                }).toList();

                try {
                  await FirebaseFirestore.instance.collection('diagnosticos').doc(docId).update({
                    'sistema_reparar': editSistema.text.toUpperCase(),
                    'descripcion_falla': editDesc.text.toUpperCase(),
                    'garantia': editGarantia.text.toUpperCase(),
                    'presupuesto_items': itemsParaSubir,
                    'total_reparacion': nuevoTotal,
                  });
                  if (!mounted) return;
                  navigator.pop();
                  messenger.showSnackBar(const SnackBar(content: Text("✅ ACTUALIZADO"), backgroundColor: Colors.blue));
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(content: Text("❌ ERROR: $e"), backgroundColor: Colors.red));
                }
              },
              child: const Text("GUARDAR CAMBIOS"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_clienteSeleccionadoId == null ? "HISTORIAL: SELECCIONAR CLIENTE" : "TRABAJOS DE: ${_clienteSeleccionadoNombre?.toUpperCase()}", 
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const Spacer(),
            if (_clienteSeleccionadoId != null)
              TextButton.icon(
                onPressed: () => setState(() { _clienteSeleccionadoId = null; }),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text("CAMBIAR CLIENTE"),
                style: TextButton.styleFrom(foregroundColor: brandRed),
              )
          ],
        ),
        const SizedBox(height: 25),
        _clienteSeleccionadoId == null ? _buildBuscadorClientes() : _buildListaPresupuestos(),
      ],
    );
  }

  Widget _buildBuscadorClientes() {
    return Expanded(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(10)),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() => _filtroNombre = val.toUpperCase()),
              decoration: InputDecoration(
                hintText: "BUSCAR CLIENTE POR NOMBRE...",
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                prefixIcon: const Icon(Icons.person_search, color: Colors.white54),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20)
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('clientes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs.where((doc) => doc['nombre'].toString().toUpperCase().contains(_filtroNombre)).toList();
                if (docs.isEmpty) return const Center(child: Text("No se encontraron clientes", style: TextStyle(color: Colors.white24)));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var c = docs[index];
                    return ListTile(
                      onTap: () => setState(() { _clienteSeleccionadoId = c.id; _clienteSeleccionadoNombre = c['nombre']; }),
                      leading: CircleAvatar(backgroundColor: brandRed, child: const Icon(Icons.person, color: Colors.white)),
                      title: Text(c['nombre'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text("Cédula: ${c.id}", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaPresupuestos() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('diagnosticos').where('cliente_id', isEqualTo: _clienteSeleccionadoId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("Sin trabajos registrados", style: TextStyle(color: Colors.white24)));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return _buildHistorialCard(docs[index].id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistorialCard(String docId, Map<String, dynamic> data) {
    bool aprobado = data['aprobado'] ?? false;
    
    // --- IDENTIFICADOR PRINCIPAL: MODELO ---
    String modeloText = (data['modelo_vehiculo'] != null && data['modelo_vehiculo'].toString().isNotEmpty)
        ? data['modelo_vehiculo'].toString().toUpperCase()
        : "VEHÍCULO SIN MODELO";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: ExpansionTile(
        iconColor: brandRed,
        collapsedIconColor: Colors.white54,
        title: Row(
          children: [
            _urgenciaBadge(data['urgencia']),
            const SizedBox(width: 15),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(modeloText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text("PLACA: ${data['placa_vehiculo'] ?? 'S/P'}", style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            ]),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text("\$${(data['total_reparacion'] ?? 0).toStringAsFixed(2)}", style: TextStyle(color: brandRed, fontWeight: FontWeight.bold, fontSize: 18)),
              Text(aprobado ? "APROBADO" : "PENDIENTE", style: TextStyle(color: aprobado ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
            ])
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(data['sistema_reparar'] ?? "SISTEMA GENERAL", style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black.withValues(alpha: 0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("GARANTÍA: ${data['garantia'] ?? 'N/A'}", style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                  Row(children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20), onPressed: () => _abrirEditorPresupuesto(docId, data)),
                    IconButton(icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20), onPressed: () => _eliminarPresupuesto(docId)),
                  ])
                ]),
                const SizedBox(height: 10),
                Text("DETALLES: ${data['descripcion_falla'] ?? ''}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 20),
                _buildTablePresupuesto(data['presupuesto_items'] ?? []),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGETS DE APOYO ---
  Widget _buildEditField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      TextField(controller: controller, maxLines: maxLines, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: InputDecoration(filled: true, fillColor: inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
    ]);
  }

  Widget _buildTableInput(TextEditingController c, String h, {bool isNum = false}) {
    return TextField(controller: c, keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: InputDecoration(hintText: h, hintStyle: const TextStyle(color: Colors.white10), isDense: true, filled: true, fillColor: inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none)));
  }

  Widget _buildTablePresupuesto(List items) {
    return Table(
      border: TableBorder.all(color: Colors.white10),
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(4), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1.5)},
      children: [
        TableRow(decoration: const BoxDecoration(color: Colors.white10), children: [_cellHeader("ITEM"), _cellHeader("DESCRIPCIÓN"), _cellHeader("CANT"), _cellHeader("TOTAL")]),
        ...items.map((item) => TableRow(children: [
          _cellItem(item['item'] ?? ""),
          _cellItem(item['descripcion'] ?? ""),
          _cellItem(item['cantidad']?.toString() ?? "0"),
          _cellItem("\$${(item['subtotal'] ?? 0).toStringAsFixed(2)}"),
        ])),
      ],
    );
  }

  Widget _cellHeader(String t) => Padding(padding: const EdgeInsets.all(8), child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)));
  Widget _cellItem(String t) => Padding(padding: const EdgeInsets.all(8), child: Text(t, style: const TextStyle(color: Colors.white70, fontSize: 11)));
  Widget _urgenciaBadge(String? u) => Container(width: 12, height: 12, decoration: BoxDecoration(color: u == 'Rojo' ? Colors.red : (u == 'Amarillo' ? Colors.amber : Colors.green), shape: BoxShape.circle));
}