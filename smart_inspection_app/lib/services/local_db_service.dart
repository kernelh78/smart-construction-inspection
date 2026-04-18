import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDbService {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'smart_inspection_local.db');
    return openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE pending_inspections (
          id TEXT PRIMARY KEY,
          site_id TEXT NOT NULL,
          inspector_id TEXT NOT NULL,
          category TEXT NOT NULL,
          status TEXT NOT NULL,
          memo TEXT,
          created_at TEXT NOT NULL,
          is_synced INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE pending_defects (
          id TEXT PRIMARY KEY,
          inspection_id TEXT NOT NULL,
          severity TEXT NOT NULL,
          description TEXT NOT NULL,
          created_at TEXT NOT NULL,
          is_synced INTEGER NOT NULL DEFAULT 0
        )
      ''');
    });
  }

  // ── Inspections ──

  static Future<void> saveInspection(Map<String, dynamic> data) async {
    final d = await db;
    await d.insert('pending_inspections', {
      'id': data['id'],
      'site_id': data['site_id'],
      'inspector_id': data['inspector_id'],
      'category': data['category'],
      'status': data['status'] ?? 'pending',
      'memo': data['memo'],
      'created_at': DateTime.now().toIso8601String(),
      'is_synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getPendingInspections() async {
    final d = await db;
    return d.query('pending_inspections', where: 'is_synced = 0');
  }

  static Future<void> markInspectionSynced(String id) async {
    final d = await db;
    await d.update('pending_inspections', {'is_synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  // ── Defects ──

  static Future<void> saveDefect(Map<String, dynamic> data) async {
    final d = await db;
    await d.insert('pending_defects', {
      'id': data['id'],
      'inspection_id': data['inspection_id'],
      'severity': data['severity'],
      'description': data['description'],
      'created_at': DateTime.now().toIso8601String(),
      'is_synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getPendingDefects() async {
    final d = await db;
    return d.query('pending_defects', where: 'is_synced = 0');
  }

  static Future<void> markDefectSynced(String id) async {
    final d = await db;
    await d.update('pending_defects', {'is_synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }
}
