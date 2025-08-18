import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'localite_model.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE localites(
            local_id INTEGER PRIMARY KEY AUTOINCREMENT,
            x_localite REAL NOT NULL,
            y_localite REAL NOT NULL,
            nom TEXT NOT NULL,
            type TEXT NOT NULL,
            enqueteur TEXT NOT NULL,
            date_creation TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // SOLUTION 3 - Alternative pour production (recommandée)
  Future<File> exportTablesToAppDocuments() async {
    try {
      final db = await database;
      final dir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${dir.path}/database_exports');

      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final exports = <String, String>{};

      for (final table in tables) {
        final tableName = table['name'] as String;
        if (tableName == 'sqlite_sequence') continue;

        final data = await db.query(tableName);
        final file = File('${exportDir.path}/$tableName.json');
        await file.writeAsString(jsonEncode(data));
        exports[tableName] = file.path;
      }

      print('✅ Export réussi dans: ${exportDir.path}');
      return File('${exportDir.path}/_all_tables_export.txt')..writeAsString(exports.toString());
    } catch (e) {
      print('❌ Erreur d\'export: $e');
      rethrow;
    }
  }

  // SOLUTION 4 - Lire les exports
  Future<List<Map<String, dynamic>>> readTableExport(String tableName, {bool fromLib = false}) async {
    try {
      final file = fromLib
          ? File('lib/exports/$tableName.json') // Pour développement
          : File('${(await getApplicationDocumentsDirectory()).path}/database_exports/$tableName.json');

      if (!await file.exists()) {
        throw Exception('Fichier d\'export introuvable');
      }

      final content = await file.readAsString();
      return List<Map<String, dynamic>>.from(jsonDecode(content));
    } catch (e) {
      print('❌ Erreur de lecture: $e');
      rethrow;
    }
  }

  // Méthodes CRUD de base
  Future<int> insertLocalite(Localite localite) async {
    final db = await database;
    return await db.insert('localites', localite.toMap());
  }

  Future<List<Localite>> getAllLocalites() async {
    final db = await database;
    final maps = await db.query('localites');
    return maps.map((map) => Localite.fromMap(map)).toList();
  }

  Future<void> close() async {
    if (_database != null) await _database!.close();
  }
}
