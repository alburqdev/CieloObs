import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../db.dart';
import '../models/observacion.dart';

const List<String> kCategorias = [
  'Fenómeno atmosférico',
  'Astronomía',
  'Aves migratorias',
  'Aeronave / Objeto artificial',
  'Otro',
];

const List<String> kCondiciones = [
  'Despejado',
  'Parcialmente nublado',
  'Nublado',
  'Bruma',
  'Lluvia ligera',
];

class NuevaObservacionScreen extends StatefulWidget {
  final Observacion? observacionExistente;
  const NuevaObservacionScreen({super.key, this.observacionExistente});

  @override
  State<NuevaObservacionScreen> createState() =>
      _NuevaObservacionScreenState();
}

class _NuevaObservacionScreenState extends State<NuevaObservacionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _duracionCtrl = TextEditingController();
  final _ubicacionTextoCtrl = TextEditingController();

  DateTime _fechaHora = DateTime.now();
  String _categoria = kCategorias[0];
  String _condicion = kCondiciones[0];

  double? _lat;
  double? _lng;
  String? _fotoPath;
  String? _audioPath;

  bool _grabandoAudio = false;
  bool _cargando = false;
  final _audioRecorder = Record();

  @override
  void initState() {
    super.initState();
    final obs = widget.observacionExistente;
    if (obs != null) {
      _tituloCtrl.text = obs.titulo;
      _descripcionCtrl.text = obs.descripcion;
      _duracionCtrl.text = obs.duracionSeg?.toString() ?? '';
      _ubicacionTextoCtrl.text = obs.ubicacionTexto ?? '';
      _fechaHora = DateTime.parse(obs.fechaHora);
      _categoria = obs.categoria;
      _condicion = obs.condicionesCielo;
      _lat = obs.lat;
      _lng = obs.lng;
      _fotoPath = obs.fotoPath;
      _audioPath = obs.audioPath;
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _duracionCtrl.dispose();
    _ubicacionTextoCtrl.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // ── GPS ────────────────────────────────────────────────────────

  Future<void> _capturarGPS() async {
    setState(() => _cargando = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Activa el servicio de ubicación', isError: true);
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        _showSnack('Permiso de ubicación denegado', isError: true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      _showSnack('GPS capturado: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}');
    } catch (e) {
      _showSnack('Error al obtener GPS', isError: true);
    } finally {
      setState(() => _cargando = false);
    }
  }

  // ── Foto ───────────────────────────────────────────────────────

  Future<void> _tomarFoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1A2744),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading:
                const Icon(Icons.camera_alt, color: Color(0xFF7B8CDE)),
            title: const Text('Cámara',
                style: TextStyle(color: Colors.white)),
            onTap: () =>
                Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library,
                color: Color(0xFF7B8CDE)),
            title: const Text('Galería',
                style: TextStyle(color: Colors.white)),
            onTap: () =>
                Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
    if (source == null) return;
    final img =
        await picker.pickImage(source: source, imageQuality: 70);
    if (img != null) {
      setState(() => _fotoPath = img.path);
    }
  }

  // ── Audio ──────────────────────────────────────────────────────

  Future<void> _toggleGrabar() async {
    if (_grabandoAudio) {
      final path = await _audioRecorder.stop();
      setState(() {
        _audioPath = path;
        _grabandoAudio = false;
      });
      _showSnack('Nota de voz guardada');
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
          path: filePath,
          encoder: AudioEncoder.aacLc,
        );
        setState(() => _grabandoAudio = true);
      } else {
        _showSnack('Permiso de micrófono denegado', isError: true);
      }
    }
  }

  // ── Guardar ────────────────────────────────────────────────────

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now().toIso8601String();
    final obs = Observacion(
      id: widget.observacionExistente?.id,
      titulo: _tituloCtrl.text.trim(),
      fechaHora: _fechaHora.toIso8601String(),
      lat: _lat,
      lng: _lng,
      ubicacionTexto: _ubicacionTextoCtrl.text.trim().isEmpty
          ? null
          : _ubicacionTextoCtrl.text.trim(),
      duracionSeg: int.tryParse(_duracionCtrl.text),
      categoria: _categoria,
      condicionesCielo: _condicion,
      descripcion: _descripcionCtrl.text.trim(),
      fotoPath: _fotoPath,
      audioPath: _audioPath,
      creadoEn: widget.observacionExistente?.creadoEn ?? now,
    );

    if (widget.observacionExistente != null) {
      await DBHelper.instance.updateObservacion(obs);
    } else {
      await DBHelper.instance.insertObservacion(obs);
    }
    if (mounted) {
      _showSnack('Observación guardada ✅');
      Navigator.pop(context, true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  Future<void> _seleccionarFechaHora() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fechaHora,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark(),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fechaHora),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark(),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() {
      _fechaHora =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.observacionExistente == null
            ? '✨ Nueva Observación'
            : '✏️ Editar Observación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _guardar,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSection('📌 Información Básica', [
                    _buildField(
                      controller: _tituloCtrl,
                      label: 'Título de la observación',
                      hint: 'Ej: Halo solar, Nube lenticular...',
                      icon: Icons.star_outline,
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown('Categoría', kCategorias, _categoria,
                        (v) => setState(() => _categoria = v!),
                        Icons.category_outlined),
                    const SizedBox(height: 12),
                    // Fecha y hora
                    GestureDetector(
                      onTap: _seleccionarFechaHora,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: _fieldDecoration(),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: Color(0xFF7B8CDE), size: 20),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Fecha y hora',
                                    style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11)),
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm')
                                      .format(_fechaHora),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.edit_calendar,
                                color: Colors.white38, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _duracionCtrl,
                      label: 'Duración estimada (segundos)',
                      hint: 'Ej: 120',
                      icon: Icons.timer_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ]),

                  _buildSection('🌤️ Condiciones del Cielo', [
                    _buildDropdown('Condición', kCondiciones, _condicion,
                        (v) => setState(() => _condicion = v!),
                        Icons.wb_cloudy_outlined),
                  ]),

                  _buildSection('📍 Ubicación', [
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: _ubicacionTextoCtrl,
                            label: 'Sector / Municipio / Provincia',
                            hint: 'Ej: Santo Domingo Este',
                            icon: Icons.location_city,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF7B8CDE).withOpacity(0.3),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _capturarGPS,
                              icon: const Icon(Icons.gps_fixed, size: 16),
                              label: const Text('GPS',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            if (_lat != null)
                              Text(
                                '${_lat!.toStringAsFixed(4)}\n${_lng!.toStringAsFixed(4)}',
                                style: const TextStyle(
                                    color: Colors.green, fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ]),

                  _buildSection('📝 Descripción', [
                    TextFormField(
                      controller: _descripcionCtrl,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText:
                            'Describe lo observado, dirección (N/S/E/O), altura estimada...',
                        hintStyle:
                            const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF7B8CDE)),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Agrega una descripción'
                          : null,
                    ),
                  ]),

                  _buildSection('📷 Foto', [
                    if (_fotoPath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_fotoPath!),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF7B8CDE).withOpacity(0.2),
                        foregroundColor: Colors.white,
                        minimumSize:
                            const Size(double.infinity, 44),
                      ),
                      onPressed: _tomarFoto,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(_fotoPath == null
                          ? 'Agregar foto (opcional)'
                          : 'Cambiar foto'),
                    ),
                    if (_fotoPath != null)
                      TextButton.icon(
                        onPressed: () => setState(() => _fotoPath = null),
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent, size: 16),
                        label: const Text('Quitar foto',
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                  ]),

                  _buildSection('🎤 Nota de Voz', [
                    if (_audioPath != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mic,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            const Text('Audio grabado',
                                style: TextStyle(color: Colors.green)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent, size: 18),
                              onPressed: () =>
                                  setState(() => _audioPath = null),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _grabandoAudio
                            ? Colors.redAccent.withOpacity(0.3)
                            : const Color(0xFF7B8CDE).withOpacity(0.2),
                        foregroundColor: Colors.white,
                        minimumSize:
                            const Size(double.infinity, 44),
                      ),
                      onPressed: _toggleGrabar,
                      icon: Icon(_grabandoAudio
                          ? Icons.stop_rounded
                          : Icons.mic_none_outlined),
                      label: Text(_grabandoAudio
                          ? '⏹ Detener grabación'
                          : '🎤 Grabar nota de voz'),
                    ),
                  ]),

                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B8CDE),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _guardar,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Guardar Observación',
                        style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(
                color: Color(0xFF7B8CDE),
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: const Color(0xFF7B8CDE), size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF7B8CDE)),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
          : null,
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value,
      ValueChanged<String?> onChanged, IconData icon) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: _fieldDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          dropdownColor: const Color(0xFF1A2744),
          icon: const Icon(Icons.expand_more, color: Colors.white54),
          items: items
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Icon(icon,
                            color: const Color(0xFF7B8CDE), size: 18),
                        const SizedBox(width: 10),
                        Text(c,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  BoxDecoration _fieldDecoration() => BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      );
}
