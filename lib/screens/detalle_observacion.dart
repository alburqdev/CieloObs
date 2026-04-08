import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import '../db.dart';
import '../models/observacion.dart';
import 'nueva_observacion.dart';

class DetalleObservacionScreen extends StatefulWidget {
  final int id;
  const DetalleObservacionScreen({super.key, required this.id});

  @override
  State<DetalleObservacionScreen> createState() =>
      _DetalleObservacionScreenState();
}

class _DetalleObservacionScreenState
    extends State<DetalleObservacionScreen> {
  Observacion? _obs;
  bool _cargando = true;
  final _player = AudioPlayer();
  bool _reproduciendo = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final obs = await DBHelper.instance.fetchObservacion(widget.id);
    setState(() {
      _obs = obs;
      _cargando = false;
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    if (_obs?.audioPath == null) return;
    if (_reproduciendo) {
      await _player.stop();
      setState(() => _reproduciendo = false);
    } else {
      try {
        await _player.setFilePath(_obs!.audioPath!);
        _player.play();
        setState(() => _reproduciendo = true);
        _player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            setState(() => _reproduciendo = false);
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al reproducir audio')),
        );
      }
    }
  }

  Future<void> _eliminar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2744),
        title: const Text('¿Eliminar observación?',
            style: TextStyle(color: Colors.white)),
        content: const Text('Esta acción no se puede deshacer.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DBHelper.instance.deleteObservacion(widget.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _compartir() async {
    if (_obs == null) return;
    final json = jsonEncode(_obs!.toMap());
    await Share.share(
      '📡 Observación del Cielo\n\n'
      'Título: ${_obs!.titulo}\n'
      'Categoría: ${_obs!.categoria}\n'
      'Fecha: ${_obs!.fechaHora}\n'
      'Ubicación: ${_obs!.ubicacionTexto ?? "${_obs!.lat}, ${_obs!.lng}"}\n'
      'Descripción: ${_obs!.descripcion}\n\n'
      'JSON:\n$json',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (_obs == null) {
      return const Scaffold(
          body: Center(child: Text('Observación no encontrada')));
    }
    final obs = _obs!;
    final fecha = DateTime.tryParse(obs.fechaHora) ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(obs.titulo,
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
              icon: const Icon(Icons.share_outlined), onPressed: _compartir),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => NuevaObservacionScreen(
                        observacionExistente: obs)),
              );
              if (result == true) _cargar();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _eliminar,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Foto
          if (obs.fotoPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(obs.fotoPath!),
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),

          const SizedBox(height: 16),

          // Categoría badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B8CDE).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF7B8CDE).withOpacity(0.5)),
                ),
                child: Text(obs.categoria,
                    style: const TextStyle(
                        color: Color(0xFF7B8CDE), fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(obs.condicionesCielo,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Info cards
          _infoCard([
            _infoRow(Icons.access_time, 'Fecha y hora',
                DateFormat('dd/MM/yyyy HH:mm').format(fecha)),
            if (obs.duracionSeg != null)
              _infoRow(Icons.timer_outlined, 'Duración',
                  _formatDuracion(obs.duracionSeg!)),
            _infoRow(
              Icons.location_on_outlined,
              'Ubicación',
              obs.ubicacionTexto ??
                  (obs.lat != null
                      ? '${obs.lat!.toStringAsFixed(5)}, ${obs.lng!.toStringAsFixed(5)}'
                      : 'No registrada'),
            ),
          ]),

          const SizedBox(height: 12),

          // Descripción
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📝 Descripción',
                    style: TextStyle(
                        color: Color(0xFF7B8CDE),
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(obs.descripcion,
                    style: const TextStyle(
                        color: Colors.white, height: 1.5)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Audio
          if (obs.audioPath != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Color(0xFF7B8CDE)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('🎤 Nota de voz',
                        style: TextStyle(color: Colors.white)),
                  ),
                  IconButton(
                    icon: Icon(
                      _reproduciendo
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      color: const Color(0xFF7B8CDE),
                      size: 30,
                    ),
                    onPressed: _toggleAudio,
                  ),
                ],
              ),
            ),

          // Mapa
          if (obs.lat != null && obs.lng != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter:
                        LatLng(obs.lat!, obs.lng!),
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(obs.lat!, obs.lng!),
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.redAccent,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF7B8CDE)),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _formatDuracion(int seg) {
    if (seg < 60) return '$seg segundos';
    final min = seg ~/ 60;
    final s = seg % 60;
    return s == 0 ? '$min minutos' : '$min min $s seg';
  }
}
