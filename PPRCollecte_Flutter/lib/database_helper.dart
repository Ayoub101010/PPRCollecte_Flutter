import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'localite_model.dart';
import 'dart:convert';
import 'dart:io';

class DatabaseHelper {
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
    print('📂 Chemin de la DB: $path');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        print('🆕 Création de la table localites');
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
      onOpen: (db) async {
        print('🔌 Base de données ouverte');
      },
    );
  }

  /// 📂 Fichier JSON dans le stockage interne
  Future<File> _getJsonFile() async {
    final dir = await getApplicationDocumentsDirectory(); // dossier interne de l'app
    final path = join(dir.path, 'localites.json');
    return File(path);
  }

  /// ➕ Insérer une Localite dans SQLite
  Future<int> insertLocalite(Localite localite) async {
    final db = await database;
    final id = await db.insert('localites', localite.toMap());
    print("✅ Localité insérée: ${localite.nom}");
    return id;
  }

  /// 📖 Lire toutes les Localités depuis SQLite
  Future<List<Localite>> getLocalites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('localites');
    List<Localite> localites = maps.map((map) => Localite.fromMap(map)).toList();

    // 👀 Affichage console
    print("📊 Localités dans SQLite:");
    for (var loc in localites) {
      print("➡️ ${loc.localId} | ${loc.nom} | ${loc.type} | ${loc.dateCreation} | ${loc.enqueteur}");
    }

    return localites;
  }

  /// 🔄 Exporter TOUTES les localités SQLite vers JSON
  Future<void> exportLocalitesToJson() async {
    try {
      final localites = await getLocalites();
      final file = await _getJsonFile();

      List<dynamic> data = localites.map((loc) => loc.toJson()).toList();
      await file.writeAsString(json.encode(data), flush: true);

      print("✅ Export JSON terminé → ${file.path}");
    } catch (e) {
      print("❌ Erreur export JSON: $e");
    }
  }
}
