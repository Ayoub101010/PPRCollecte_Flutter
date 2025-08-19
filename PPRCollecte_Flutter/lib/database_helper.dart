import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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
      version: 6,
      onCreate: (db, version) async {
        print('🆕 Création de toutes les tables');
        await _createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 6) {
          print('🔄 Mise à jour de la base de données vers la version 3');
          await _addMissingColumns(db);
        }
      },
      onOpen: (db) async {
        print('🔌 Base de données ouverte');
      },
    );
  }

  Future<void> _createAllTables(Database db) async {
    // Table localites
    await db.execute('''
    CREATE TABLE IF NOT EXISTS localites(
      local_id INTEGER PRIMARY KEY AUTOINCREMENT,
      x_localite REAL NOT NULL,
      y_localite REAL NOT NULL,
      nom TEXT NOT NULL,
      type TEXT NOT NULL,
      enqueteur TEXT NOT NULL,
      date_creation TEXT NOT NULL,
      date_modification TEXT,
      code_piste TEXT
    )
  ''');

    // Table ecoles
    await db.execute('''
    CREATE TABLE IF NOT EXISTS ecoles(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      x_ecole REAL NOT NULL,
      y_ecole REAL NOT NULL,
      nom TEXT NOT NULL,
      type TEXT NOT NULL,
      enqueteur TEXT NOT NULL,
      date_creation TEXT NOT NULL,
      date_modification TEXT,
      code_piste TEXT
    )
  ''');

    // Table marches
    await db.execute('''
    CREATE TABLE IF NOT EXISTS marches(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      x_marche REAL NOT NULL,
      y_marche REAL NOT NULL,
      nom TEXT NOT NULL,
      type TEXT NOT NULL,
      enqueteur TEXT NOT NULL,
      date_creation TEXT NOT NULL,
      date_modification TEXT,
      code_piste TEXT
    )
  ''');

    // Table services_santes
    await db.execute('''
    CREATE TABLE IF NOT EXISTS services_santes(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      x_sante REAL NOT NULL,
      y_sante REAL NOT NULL,
      nom TEXT NOT NULL,
      type TEXT NOT NULL,
      enqueteur TEXT NOT NULL,
      date_creation TEXT NOT NULL,
      date_modification TEXT,
      code_piste TEXT
    )
  ''');

    // Table batiments_administratifs
    await db.execute('''
    CREATE TABLE IF NOT EXISTS batiments_administratifs(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      x_batiment_administratif REAL NOT NULL,
      y_batiment_administratif REAL NOT NULL,
      nom TEXT NOT NULL,
      type TEXT NOT NULL,
      enqueteur TEXT NOT NULL,
      date_creation TEXT NOT NULL,
      date_modification TEXT,
      code_piste TEXT
    )
  ''');

    // Table infrastructures_hydrauliques
    await db.execute('''
    CREATE TABLE IF NOT EXISTS infrastructures_hydrauliques(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      x_infrastructure_hydraulique REAL NOT NULL,
      y_infrastructure_hydraulique REAL NOT NULL,
      nom TEXT NOT NULL,
      type TEXT NOT NULL,
      enqueteur TEXT NOT NULL,
      date_creation TEXT NOT NULL,
      date_modification TEXT,
      code_piste TEXT
    )
  ''');

    // Table autres_infrastructures
    await db.execute('''
    CREATE TABLE IF NOT EXISTS autres_infrastructures(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      x_autre_infrastructure REAL NOT NULL,
      y_autre_infrastructure REAL NOT NULL,
      nom TEXT NOT NULL,
      type TEXT NOT NULL,
      enqueteur TEXT NOT NULL,
      date_creation TEXT NOT NULL,
      date_modification TEXT,
      code_piste TEXT
    )
  ''');

    // Table ponts
    await db.execute('''
    CREATE TABLE IF NOT EXISTS ponts(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      x_pont REAL NOT NULL,
      y_pont REAL NOT NULL,
      situation_pont TEXT NOT NULL,
      type_pont TEXT NOT NULL,
      nom_cours_eau TEXT NOT NULL,
      enqueteur TEXT NOT NULL,
      date_creation TEXT NOT NULL,
      date_modification TEXT,
      code_piste TEXT
    )
  ''');

    // Table bacs
    await db.execute('''
    CREATE TABLE IF NOT EXISTS bacs(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      x_debut_traversee_bac REAL NOT NULL,
      y_debut_traversee_bac REAL NOT NULL,
      x_fin_traversee_bac REAL NOT NULL,
      y_fin_traversee_bac REAL NOT NULL,
      type_bac TEXT NOT NULL,
      nom_cours_eau TEXT NOT NULL,
      enqueteur TEXT NOT NULL,
      date_creation TEXT NOT NULL,
      date_modification TEXT,
      code_piste TEXT
    )
  ''');

    // Table buses
    await db.execute('''
    CREATE TABLE IF NOT EXISTS buses(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      x_buse REAL NOT NULL,
      y_buse REAL NOT NULL,
      enqueteur TEXT NOT NULL,
      date_creation TEXT NOT NULL,
      date_modification TEXT,
      code_piste TEXT
    )
  ''');

    // Table dalots
    await db.execute('''
    CREATE TABLE IF NOT EXISTS dalots(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      x_dalot REAL NOT NULL,
      y_dalot REAL NOT NULL,
      situation_dalot TEXT NOT NULL,
      enqueteur TEXT NOT NULL,
      date_creation TEXT NOT NULL,
      date_modification TEXT,
      code_piste TEXT
    )
  ''');

    // Table passages_submersibles
    await db.execute('''
    CREATE TABLE IF NOT EXISTS passages_submersibles(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      x_debut_passage_submersible REAL NOT NULL,
      y_debut_passage_submersible REAL NOT NULL,
      x_fin_passage_submersible REAL NOT NULL,
      y_fin_passage_submersible REAL NOT NULL,
      type_materiau TEXT NOT NULL,
      enqueteur TEXT NOT NULL,
      date_creation TEXT NOT NULL,
      date_modification TEXT,
      code_piste TEXT
    )
  ''');

    // Table points_critiques
    await db.execute('''
    CREATE TABLE IF NOT EXISTS points_critiques(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      x_point_critique REAL NOT NULL,
      y_point_critique REAL NOT NULL,
      type_point_critique TEXT NOT NULL,
      enqueteur TEXT NOT NULL,
      date_creation TEXT NOT NULL,
      date_modification TEXT,
      code_piste TEXT
    )
  ''');

    // Table points_coupures
    await db.execute('''
    CREATE TABLE IF NOT EXISTS points_coupures(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      x_point_coupure REAL NOT NULL,
      y_point_coupure REAL NOT NULL,
      causes_coupures TEXT NOT NULL,
      enqueteur TEXT NOT NULL,
      date_creation TEXT NOT NULL,
      date_modification TEXT,
      code_piste TEXT
    )
  ''');
  }

  Future<void> _addMissingColumns(Database db) async {
    print('🔄 Vérification et ajout des colonnes manquantes...');

    final tables = [
      'localites',
      'ecoles',
      'marches',
      'services_santes',
      'batiments_administratifs',
      'infrastructures_hydrauliques',
      'autres_infrastructures',
      'ponts',
      'bacs',
      'buses',
      'dalots',
      'passages_submersibles',
      'points_critiques',
      'points_coupures'
    ];

    for (var table in tables) {
      try {
        final columns = await db.rawQuery('PRAGMA table_info($table)');

        // Vérifier si date_modification existe
        final hasDate = columns.any((col) => col['name'] == 'date_modification');
        if (!hasDate) {
          await db.execute('ALTER TABLE $table ADD COLUMN date_modification TEXT');
          print('✅ Colonne date_modification ajoutée à $table');
        }

        // Vérifier si code_piste existe
        final hasCodePiste = columns.any((col) => col['name'] == 'code_piste');
        if (!hasCodePiste) {
          await db.execute('ALTER TABLE $table ADD COLUMN code_piste TEXT');
          print('✅ Colonne code_piste ajoutée à $table');
        }
      } catch (e) {
        print('⚠️ Erreur avec la table $table: $e');
      }
    }
  }

  // ============ MÉTHODES CRUD ============

  Future<int> insertEntity(String tableName, Map<String, dynamic> data) async {
    final db = await database;
    final id = await db.insert(tableName, data);
    print("✅ Entité insérée dans $tableName: $data");
    return id;
  }

  Future<List<Map<String, dynamic>>> getEntities(String tableName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);

    print("📊 Entités dans $tableName:");
    for (var entity in maps) {
      print("➡️ $entity");
    }

    return maps;
  }

  Future<List<Map<String, dynamic>>> getAllPoints() async {
    final db = await database;

    final List<Map<String, dynamic>> allPoints = [];

    final tables = [
      'localites',
      'ecoles',
      'marches',
      'services_santes',
      'batiments_administratifs',
      'infrastructures_hydrauliques',
      'autres_infrastructures',
      'ponts',
      'bacs',
      'buses',
      'dalots',
      'passages_submersibles',
      'points_critiques',
      'points_coupures'
    ];

    for (var table in tables) {
      try {
        final points = await db.query(table);
        for (var point in points) {
          point['table_name'] = table;
          point['entity_type'] = _getEntityTypeFromTable(table);

          final coords = _getCoordinatesMapFromPoint(point);
          point.addAll(coords);

          allPoints.add(point);
        }
      } catch (e) {
        print("⚠️ Table $table non trouvée ou erreur: $e");
      }
    }

    print("📍 Total des points récupérés: ${allPoints.length}");
    return allPoints;
  }

  String _getEntityTypeFromTable(String tableName) {
    switch (tableName) {
      case 'localites':
        return 'Localité';
      case 'ecoles':
        return 'École';
      case 'marches':
        return 'Marché';
      case 'services_santes':
        return 'Service de Santé';
      case 'batiments_administratifs':
        return 'Bâtiment Administratif';
      case 'infrastructures_hydrauliques':
        return 'Infrastructure Hydraulique';
      case 'autres_infrastructures':
        return 'Autre Infrastructure';
      case 'ponts':
        return 'Pont';
      case 'bacs':
        return 'Bac';
      case 'buses':
        return 'Buse';
      case 'dalots':
        return 'Dalot';
      case 'passages_submersibles':
        return 'Passage Submersible';
      case 'points_critiques':
        return 'Point Critique';
      case 'points_coupures':
        return 'Point de Coupure';
      default:
        return tableName;
    }
  }

  Map<String, dynamic> _getCoordinatesMapFromPoint(Map<String, dynamic> point) {
    final tableName = point['table_name'];
    Map<String, dynamic> coordinates = {};

    switch (tableName) {
      case 'localites':
        coordinates = {
          'lat': point['x_localite'],
          'lng': point['y_localite']
        };
        break;
      case 'ecoles':
        coordinates = {
          'lat': point['x_ecole'],
          'lng': point['y_ecole']
        };
        break;
      case 'marches':
        coordinates = {
          'lat': point['x_marche'],
          'lng': point['y_marche']
        };
        break;
      case 'services_santes':
        coordinates = {
          'lat': point['x_sante'],
          'lng': point['y_sante']
        };
        break;
      case 'batiments_administratifs':
        coordinates = {
          'lat': point['x_batiment_administratif'],
          'lng': point['y_batiment_administratif']
        };
        break;
      case 'infrastructures_hydrauliques':
        coordinates = {
          'lat': point['x_infrastructure_hydraulique'],
          'lng': point['y_infrastructure_hydraulique']
        };
        break;
      case 'autres_infrastructures':
        coordinates = {
          'lat': point['x_autre_infrastructure'],
          'lng': point['y_autre_infrastructure']
        };
        break;
      case 'ponts':
        coordinates = {
          'lat': point['x_pont'],
          'lng': point['y_pont']
        };
        break;
      case 'bacs':
        coordinates = {
          'lat': point['x_debut_traversee_bac'],
          'lng': point['y_debut_traversee_bac'],
          'lat_fin': point['x_fin_traversee_bac'],
          'lng_fin': point['y_fin_traversee_bac']
        };
        break;
      case 'buses':
        coordinates = {
          'lat': point['x_buse'],
          'lng': point['y_buse']
        };
        break;
      case 'dalots':
        coordinates = {
          'lat': point['x_dalot'],
          'lng': point['y_dalot']
        };
        break;
      case 'passages_submersibles':
        coordinates = {
          'lat': point['x_debut_passage_submersible'],
          'lng': point['y_debut_passage_submersible'],
          'lat_fin': point['x_fin_passage_submersible'],
          'lng_fin': point['y_fin_passage_submersible']
        };
        break;
      case 'points_critiques':
        coordinates = {
          'lat': point['x_point_critique'],
          'lng': point['y_point_critique']
        };
        break;
      case 'points_coupures':
        coordinates = {
          'lat': point['x_point_coupure'],
          'lng': point['y_point_coupure']
        };
        break;
      default:
        coordinates = {
          'lat': 0,
          'lng': 0
        };
    }

    return coordinates;
  }

  Future<int> deleteEntity(String tableName, int id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [
        id
      ],
    );
  }

  Future<int> updateEntity(String tableName, int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      tableName,
      data,
      where: 'id = ?',
      whereArgs: [
        id
      ],
    );
  }

  Future<int> countEntities(String tableName) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, dynamic>> exportAllData() async {
    final Map<String, dynamic> allData = {};
    final tables = [
      'localites',
      'ecoles',
      'marches',
      'services_santes',
      'batiments_administratifs',
      'infrastructures_hydrauliques',
      'autres_infrastructures',
      'ponts',
      'bacs',
      'buses',
      'dalots',
      'passages_submersibles',
      'points_critiques',
      'points_coupures'
    ];

    for (var table in tables) {
      try {
        final data = await getEntities(table);
        allData[table] = data;
      } catch (e) {
        print("⚠️ Erreur lors de l'export de $table: $e");
      }
    }

    return allData;
  }
}
