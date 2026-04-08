import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/observacion.dart';
import '../models/perfil.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cielo_obs.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE observacion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        fecha_hora TEXT NOT NULL,
        lat REAL,
        lng REAL,
        ubicacion_texto TEXT,
        duracion_seg INTEGER,
        categoria TEXT NOT NULL,
        condiciones_cielo TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        foto_path TEXT,
        audio_path TEXT,
        creado_en TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE perfil (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        apellido TEXT NOT NULL,
        matricula TEXT NOT NULL,
        foto_path TEXT,
        frase TEXT NOT NULL
      )
    ''');
  }

  // ── Observaciones ──────────────────────────────────────────────

  Future<int> insertObservacion(Observacion obs) async {
    final db = await instance.database;
    return await db.insert('observacion', obs.toMap());
  }

  Future<List<Observacion>> fetchObservaciones({
    String? categoria,
    String? fechaDesde,
    String? fechaHasta,
    String? lugar,
  }) async {
    final db = await instance.database;
    String whereStr = '';
    List<dynamic> whereArgs = [];

    if (categoria != null && categoria.isNotEmpty) {
      whereStr += (whereStr.isEmpty ? '' : ' AND ') + "categoria = ?";
      whereArgs.add(categoria);
    }
    if (fechaDesde != null && fechaDesde.isNotEmpty) {
      whereStr += (whereStr.isEmpty ? '' : ' AND ') + "fecha_hora >= ?";
      whereArgs.add(fechaDesde);
    }
    if (fechaHasta != null && fechaHasta.isNotEmpty) {
      whereStr += (whereStr.isEmpty ? '' : ' AND ') + "fecha_hora <= ?";
      whereArgs.add('${fechaHasta}T23:59:59');
    }
    if (lugar != null && lugar.isNotEmpty) {
      whereStr +=
          (whereStr.isEmpty ? '' : ' AND ') + "ubicacion_texto LIKE ?";
      whereArgs.add('%$lugar%');
    }

    final maps = await db.query(
      'observacion',
      where: whereStr.isEmpty ? null : whereStr,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'fecha_hora DESC',
    );
    return maps.map((m) => Observacion.fromMap(m)).toList();
  }

  Future<Observacion?> fetchObservacion(int id) async {
    final db = await instance.database;
    final maps =
        await db.query('observacion', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Observacion.fromMap(maps.first);
    return null;
  }

  Future<int> updateObservacion(Observacion obs) async {
    final db = await instance.database;
    return await db.update('observacion', obs.toMap(),
        where: 'id = ?', whereArgs: [obs.id]);
  }

  Future<int> deleteObservacion(int id) async {
    final db = await instance.database;
    return await db
        .delete('observacion', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllObservaciones() async {
    final db = await instance.database;
    // Delete associated files first
    final maps = await db.query('observacion');
    for (final m in maps) {
      final obs = Observacion.fromMap(m);
      if (obs.fotoPath != null) {
        try {
          File(obs.fotoPath!).deleteSync();
        } catch (_) {}
      }
      if (obs.audioPath != null) {
        try {
          File(obs.audioPath!).deleteSync();
        } catch (_) {}
      }
    }
    await db.delete('observacion');
  }

  // ── Perfil ─────────────────────────────────────────────────────

  Future<Perfil?> fetchPerfil() async {
    final db = await instance.database;
    final maps = await db.query('perfil', limit: 1);
    if (maps.isNotEmpty) return Perfil.fromMap(maps.first);
    return null;
  }

  Future<void> savePerfil(Perfil perfil) async {
    final db = await instance.database;
    final existing = await fetchPerfil();
    if (existing == null) {
      await db.insert('perfil', {...perfil.toMap(), 'id': 1});
    } else {
      await db.update('perfil', perfil.toMap(),
          where: 'id = ?', whereArgs: [1]);
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
