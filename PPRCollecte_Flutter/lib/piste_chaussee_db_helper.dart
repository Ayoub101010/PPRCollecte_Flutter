// lib/simple_storage_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'piste_model.dart';
import 'chaussee_model.dart';

class SimpleStorageHelper {
  static final SimpleStorageHelper _instance = SimpleStorageHelper._internal();
  factory SimpleStorageHelper() => _instance;
  static Database? _database;

  SimpleStorageHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'piste_chaussee_storage.db');
    print('📂 Base SQLite Piste/Chaussée: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        print('🔨 Création tables Piste et Chaussée...');

        // Table Pistes
        await db.execute('''
          CREATE TABLE pistes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code_piste TEXT NOT NULL,
            commune_rurale_id TEXT,
            user_login TEXT NOT NULL,
            heure_debut TEXT NOT NULL,
            heure_fin TEXT NOT NULL,
            nom_origine_piste TEXT NOT NULL,
            x_origine REAL NOT NULL,
            y_origine REAL NOT NULL,
            nom_destination_piste TEXT NOT NULL,
            x_destination REAL NOT NULL,
            y_destination REAL NOT NULL,
            type_occupation TEXT,
            debut_occupation TEXT,
            fin_occupation TEXT,
            largeur_emprise REAL,
            frequence_trafic TEXT,
            type_trafic TEXT,
            travaux_realises TEXT,
            date_travaux TEXT,
            entreprise TEXT,
            points_json TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // Table Chaussées
        await db.execute('''
          CREATE TABLE chaussees (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code_piste TEXT NOT NULL,
            code_gps TEXT NOT NULL,
            endroit TEXT NOT NULL,
            type_chaussee TEXT,
            etat_piste TEXT,
            x_debut_chaussee REAL NOT NULL,
            y_debut_chaussee REAL NOT NULL,
            x_fin_chaussee REAL NOT NULL,
            y_fin_chaussee REAL NOT NULL,
            points_json TEXT NOT NULL,
            distance_totale_m REAL NOT NULL,
            nombre_points INTEGER NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        print('✅ Tables créées avec succès');
      },
    );
  }

  /// Sauvegarder une piste depuis le formulaire
  Future<int?> savePiste(Map<String, dynamic> formData) async {
    try {
      final piste = PisteModel.fromFormData(formData);
      final db = await database;
      final id = await db.insert('pistes', piste.toMap());

      print('✅ Piste "${piste.codePiste}" sauvegardée avec ID: $id');
      return id;
    } catch (e) {
      print('❌ Erreur sauvegarde piste: $e');
      return null;
    }
  }

  /// Sauvegarder une chaussée depuis le formulaire
  Future<int?> saveChaussee(Map<String, dynamic> formData) async {
    try {
      final chaussee = ChausseeModel.fromFormData(formData);
      final db = await database;
      final id = await db.insert('chaussees', chaussee.toMap());

      print('✅ Chaussée "${chaussee.codePiste}" sauvegardée avec ID: $id');
      return id;
    } catch (e) {
      print('❌ Erreur sauvegarde chaussée: $e');
      return null;
    }
  }

  /// Lister toutes les pistes (optionnel pour debug)
  Future<List<PisteModel>> getAllPistes() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps =
          await db.query('pistes', orderBy: 'created_at DESC');
      return maps.map((map) => PisteModel.fromMap(map)).toList();
    } catch (e) {
      print('❌ Erreur lecture pistes: $e');
      return [];
    }
  }

  /// Lister toutes les chaussées (optionnel pour debug)
  Future<List<ChausseeModel>> getAllChaussees() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps =
          await db.query('chaussees', orderBy: 'created_at DESC');
      return maps.map((map) => ChausseeModel.fromMap(map)).toList();
    } catch (e) {
      print('❌ Erreur lecture chaussées: $e');
      return [];
    }
  }

  /// Compter le total d'éléments sauvegardés (optionnel pour debug)
  Future<Map<String, int>> getCount() async {
    try {
      final db = await database;
      final pisteCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM pistes')) ??
          0;
      final chausseeCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM chaussees')) ??
          0;

      return {
        'pistes': pisteCount,
        'chaussees': chausseeCount,
        'total': pisteCount + chausseeCount,
      };
    } catch (e) {
      print('❌ Erreur comptage: $e');
      return {'pistes': 0, 'chaussees': 0, 'total': 0};
    }
  }
}
