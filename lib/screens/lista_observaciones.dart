import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db.dart';
import '../models/observacion.dart';
import 'detalle_observacion.dart';
import 'nueva_observacion.dart';

class ListaObservacionesScreen extends StatefulWidget {
  const ListaObservacionesScreen({super.key});

  @override
  State<ListaObservacionesScreen> createState() =>
      _ListaObservacionesScreenState();
}

class _ListaObservacionesScreenState
    extends State<ListaObservacionesScreen> {
  List<Observacion> _obs = [];
  bool _cargando = true;

  String _filtroCategoria = '';
  String _filtroLugar = '';
  String _filtroFechaDesde = '';
  String _filtroFechaHasta = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final lista = await DBHelper.instance.fetchObservaciones(
      categoria: _filtroCategoria.isEmpty ? null : _filtroCategoria,
      lugar: _filtroLugar.isEmpty ? null : _filtroLugar,
      fechaDesde: _filtroFechaDesde.isEmpty ? null : _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta.isEmpty ? null : _filtroFechaHasta,
    );
    setState(() {
      _obs = lista;
      _cargando = false;
    });
  }

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A2744),
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FiltrosSheet(
        categoriaInicial: _filtroCategoria,
        lugarInicial: _filtroLugar,
        fechaDesdeInicial: _filtroFechaDesde,
        fechaHastaInicial: _filtroFechaHasta,
        onAplicar: (cat, lugar, desde, hasta) {
          setState(() {
            _filtroCategoria = cat;
            _filtroLugar = lugar;
            _filtroFechaDesde = desde;
            _filtroFechaHasta = hasta;
          });
          _cargar();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌠 Mis Observaciones'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _filtroCategoria.isNotEmpty ||
                  _filtroLugar.isNotEmpty ||
                  _filtroFechaDesde.isNotEmpty,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _abrirFiltros,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _obs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.nights_stay,
                          size: 60, color: Colors.white24),
                      SizedBox(height: 12),
                      Text('Sin observaciones registradas',
                          style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _obs.length,
                    itemBuilder: (ctx, i) => _ObsCard(
                      obs: _obs[i],
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DetalleObservacionScreen(
                                  id: _obs[i].id!)),
                        );
                        if (result == true) _cargar();
                      },
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7B8CDE),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const NuevaObservacionScreen()),
          );
          if (result == true) _cargar();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
    );
  }
}

class _ObsCard extends StatelessWidget {
  final Observacion obs;
  final VoidCallback onTap;

  const _ObsCard({required this.obs, required this.onTap});

  Color _catColor(String cat) {
    switch (cat) {
      case 'Astronomía':
        return const Color(0xFF7B8CDE);
      case 'Fenómeno atmosférico':
        return const Color(0xFF5EC9C9);
      case 'Aves migratorias':
        return const Color(0xFF82C77A);
      case 'Aeronave / Objeto artificial':
        return const Color(0xFFE8A838);
      default:
        return Colors.white54;
    }
  }

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'Astronomía':
        return Icons.star;
      case 'Fenómeno atmosférico':
        return Icons.wb_cloudy;
      case 'Aves migratorias':
        return Icons.flutter_dash;
      case 'Aeronave / Objeto artificial':
        return Icons.airplanemode_active;
      default:
        return Icons.remove_red_eye;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _catColor(obs.categoria);
    final fechaHora = DateTime.tryParse(obs.fechaHora) ?? DateTime.now();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_catIcon(obs.categoria), color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(obs.titulo,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 12, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(fechaHora),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (obs.ubicacionTexto != null ||
                      (obs.lat != null && obs.lng != null))
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 12, color: Colors.white38),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            obs.ubicacionTexto ??
                                '${obs.lat!.toStringAsFixed(4)}, ${obs.lng!.toStringAsFixed(4)}',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Column(
              children: [
                if (obs.fotoPath != null)
                  const Icon(Icons.photo, size: 14, color: Colors.white38),
                if (obs.audioPath != null)
                  const Icon(Icons.mic, size: 14, color: Colors.white38),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filtros Sheet ───────────────────────────────────────────────

class _FiltrosSheet extends StatefulWidget {
  final String categoriaInicial;
  final String lugarInicial;
  final String fechaDesdeInicial;
  final String fechaHastaInicial;
  final Function(String, String, String, String) onAplicar;

  const _FiltrosSheet({
    required this.categoriaInicial,
    required this.lugarInicial,
    required this.fechaDesdeInicial,
    required this.fechaHastaInicial,
    required this.onAplicar,
  });

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  late String _cat;
  late TextEditingController _lugarCtrl;
  String _desde = '';
  String _hasta = '';

  @override
  void initState() {
    super.initState();
    _cat = widget.categoriaInicial;
    _lugarCtrl = TextEditingController(text: widget.lugarInicial);
    _desde = widget.fechaDesdeInicial;
    _hasta = widget.fechaHastaInicial;
  }

  Future<void> _pickDate(bool isDesde) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) =>
          Theme(data: ThemeData.dark(), child: child!),
    );
    if (picked != null) {
      final s = DateFormat('yyyy-MM-dd').format(picked);
      setState(() => isDesde ? _desde = s : _hasta = s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filtrar Observaciones',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Categoría
          const Text('Categoría',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          DropdownButtonFormField<String>(
            value: _cat.isEmpty ? null : _cat,
            dropdownColor: const Color(0xFF1A2744),
            style: const TextStyle(color: Colors.white),
            hint: const Text('Todas',
                style: TextStyle(color: Colors.white54)),
            items: ['', ...const [
              'Fenómeno atmosférico',
              'Astronomía',
              'Aves migratorias',
              'Aeronave / Objeto artificial',
              'Otro',
            ]]
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.isEmpty ? 'Todas' : c,
                          style:
                              const TextStyle(color: Colors.white)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _cat = v ?? ''),
          ),
          const SizedBox(height: 12),

          // Lugar
          const Text('Lugar (texto)',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          TextField(
            controller: _lugarCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Ej: Santo Domingo',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          const SizedBox(height: 12),

          // Fechas
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Desde',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    GestureDetector(
                      onTap: () => _pickDate(true),
                      child: Text(
                        _desde.isEmpty ? 'Seleccionar' : _desde,
                        style: TextStyle(
                            color: _desde.isEmpty
                                ? Colors.white38
                                : Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hasta',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    GestureDetector(
                      onTap: () => _pickDate(false),
                      child: Text(
                        _hasta.isEmpty ? 'Seleccionar' : _hasta,
                        style: TextStyle(
                            color: _hasta.isEmpty
                                ? Colors.white38
                                : Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onAplicar('', '', '', '');
                    Navigator.pop(context);
                  },
                  child: const Text('Limpiar',
                      style: TextStyle(color: Colors.white54)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B8CDE)),
                  onPressed: () {
                    widget.onAplicar(
                        _cat, _lugarCtrl.text, _desde, _hasta);
                    Navigator.pop(context);
                  },
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
