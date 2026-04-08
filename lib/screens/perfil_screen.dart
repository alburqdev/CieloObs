import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../db.dart';
import '../models/perfil.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Perfil? _perfil;
  bool _editando = false;
  bool _cargando = true;

  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _matriculaCtrl = TextEditingController();
  final _fraseCtrl = TextEditingController();
  String? _fotoPath;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final p = await DBHelper.instance.fetchPerfil();
    setState(() {
      _perfil = p;
      _cargando = false;
      if (p != null) {
        _nombreCtrl.text = p.nombre;
        _apellidoCtrl.text = p.apellido;
        _matriculaCtrl.text = p.matricula;
        _fraseCtrl.text = p.frase;
        _fotoPath = p.fotoPath;
      } else {
        // Defaults for this student
        _matriculaCtrl.text = '20240191';
        _fraseCtrl.text =
            '"El cielo es el punto de partida de toda curiosidad científica. Observar es el primer paso hacia entender el universo."';
        _editando = true;
      }
    });
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty ||
        _apellidoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nombre y apellido son requeridos'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }
    final p = Perfil(
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      matricula: _matriculaCtrl.text.trim(),
      fotoPath: _fotoPath,
      frase: _fraseCtrl.text.trim(),
    );
    await DBHelper.instance.savePerfil(p);
    setState(() {
      _perfil = p;
      _editando = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Perfil guardado ✅'),
            backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _fotoPath = img.path);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _matriculaCtrl.dispose();
    _fraseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👤 Acerca del Observador'),
        actions: [
          if (!_editando && _perfil != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editando = true),
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _editando ? _buildForm() : _buildVistaInfo(),
            ),
    );
  }

  Widget _buildVistaInfo() {
    if (_perfil == null) {
      return const Center(
        child:
            Text('No hay perfil configurado', style: TextStyle(color: Colors.white54)),
      );
    }
    return Column(
      children: [
        // Foto
        Center(
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF7B8CDE), width: 3),
            ),
            child: ClipOval(
              child: _fotoPath != null
                  ? Image.file(File(_fotoPath!), fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFF1A2744),
                      child: const Icon(Icons.person,
                          size: 60, color: Color(0xFF7B8CDE)),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${_perfil!.nombre} ${_perfil!.apellido}',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Matrícula: ${_perfil!.matricula}',
          style: const TextStyle(color: Color(0xFF7B8CDE), fontSize: 15),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF7B8CDE).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.format_quote,
                  color: Color(0xFF7B8CDE), size: 28),
              const SizedBox(height: 8),
              Text(
                _perfil!.frase,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // App info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.nights_stay,
                      color: Color(0xFF7B8CDE), size: 20),
                  SizedBox(width: 8),
                  Text('Cielo Obs 20240191',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'App de Observaciones del Cielo\nRepública Dominicana 🇩🇴\nVersión 1.0.0',
                style: TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: GestureDetector(
            onTap: _seleccionarFoto,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF7B8CDE), width: 2),
                  ),
                  child: ClipOval(
                    child: _fotoPath != null
                        ? Image.file(File(_fotoPath!), fit: BoxFit.cover)
                        : Container(
                            color: const Color(0xFF1A2744),
                            child: const Icon(Icons.person,
                                size: 50, color: Color(0xFF7B8CDE)),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF7B8CDE),
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _campo(_nombreCtrl, 'Nombre', Icons.person_outline),
        const SizedBox(height: 12),
        _campo(_apellidoCtrl, 'Apellido', Icons.person_outline),
        const SizedBox(height: 12),
        _campo(_matriculaCtrl, 'Matrícula', Icons.badge_outlined),
        const SizedBox(height: 12),
        TextFormField(
          controller: _fraseCtrl,
          style: const TextStyle(color: Colors.white),
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Frase motivadora',
            labelStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.format_quote,
                color: Color(0xFF7B8CDE)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7B8CDE)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7B8CDE),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _guardar,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Guardar Perfil',
              style: TextStyle(fontSize: 16)),
        ),
        if (_editando && _perfil != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _editando = false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
        ],
      ],
    );
  }

  Widget _campo(
      TextEditingController ctrl, String label, IconData icon) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon:
            Icon(icon, color: const Color(0xFF7B8CDE), size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7B8CDE)),
        ),
      ),
    );
  }
}
