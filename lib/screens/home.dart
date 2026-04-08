import 'package:flutter/material.dart';
import 'lista_observaciones.dart';
import 'nueva_observacion.dart';
import 'perfil_screen.dart';
import '../db.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _confirmarBorrarTodo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2744),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Borrar Todo', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          '¿Estás seguro? Esta acción eliminará TODAS las observaciones '
          'guardadas en el dispositivo. No se puede deshacer.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () async {
              await DBHelper.instance.deleteAllObservaciones();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Todos los datos han sido eliminados.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Borrar Todo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B2A), Color(0xFF1A2744), Color(0xFF0D1B2A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.nights_stay,
                            color: Color(0xFF7B8CDE), size: 36),
                        SizedBox(width: 10),
                        Text(
                          'Cielo Obs',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'República Dominicana 🇩🇴',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Matrícula: 20240191',
                      style: TextStyle(
                          color: Color(0xFF7B8CDE),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              // Stars decoration
              const _StarsDivider(),

              const SizedBox(height: 24),

              // Main menu grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MenuCard(
                              icon: Icons.add_circle_outline,
                              label: 'Nueva\nObservación',
                              color: const Color(0xFF7B8CDE),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const NuevaObservacionScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _MenuCard(
                              icon: Icons.list_alt_rounded,
                              label: 'Mis\nObservaciones',
                              color: const Color(0xFF5E8AC9),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ListaObservacionesScreen()),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _MenuCard(
                              icon: Icons.person_outline,
                              label: 'Acerca\ndel Observador',
                              color: const Color(0xFF4A7CC0),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PerfilScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _MenuCard(
                              icon: Icons.delete_forever_rounded,
                              label: 'Borrar\nTodo',
                              color: Colors.redAccent.shade700,
                              onTap: () => _confirmarBorrarTodo(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '⭐ Observa · Registra · Descubre ⭐',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarsDivider extends StatelessWidget {
  const _StarsDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        9,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            i % 3 == 0 ? Icons.star : Icons.star_border,
            size: 10,
            color: const Color(0xFF7B8CDE).withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
