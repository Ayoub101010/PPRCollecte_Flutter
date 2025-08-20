import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;
  static bool _isInitializing = false;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      try {
        await _database!.rawQuery('SELECT 1');
        return _database!;
      } catch (e) {
        print('❌ Connexion DB invalide, fermeture: $e');
        await _database!.close();
        _database = null;
      }
    }

    if (_isInitializing) {
      await Future.delayed(const Duration(milliseconds: 100));
      return database;
    }

    _isInitializing = true;
    try {
      _database = await _initDatabase();
      return _database!;
    } finally {
      _isInitializing = false;
    }
  }

  Future<Database> _initDatabase() async {
    final directory = await getExternalStorageDirectory();
    final path = join(directory!.path, 'app_database.db');
    print('📂 Chemin absolu DB: $path');

    final dbFile = File(path);
    if (await dbFile.exists()) {
      print('🗑️  Suppression de l\'ancienne DB corrompue...');
      try {
        await dbFile.delete();
        final walFile = File('$path-wal');
        final shmFile = File('$path-shm');
        if (await walFile.exists()) await walFile.delete();
        if (await shmFile.exists()) await shmFile.delete();
        print('✅ Ancienne DB supprimée');
      } catch (e) {
        print('⚠️ Erreur suppression DB: $e');
      }
    }

    if (!await Directory(directory.path).exists()) {
      await Directory(directory.path).create(recursive: true);
      print('📁 Répertoire créé: ${directory.path}');
    }

    return await openDatabase(
      path,
      version: 10, // Version augmentée pour la fusion
      onCreate: (db, version) async {
        print('🆕 Création de toutes les tables pour la version $version');
        await _createAllTables(db);
        await _insertDefaultUser(db); // Ajout de l'utilisateur par défaut
        await _logTableSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        print('🔄 Migration $oldVersion → $newVersion');
        if (oldVersion < 10) {
          await _createAllTables(db);
          await _insertDefaultUser(db);
        }
        await _logTableSchema(db);
      },
      onOpen: (db) async {
        print('🔌 Base de données ouverte avec succès');
        await _testDatabaseIntegrity(db);
        await _logTableSchema(db);
      },
    );
  }

  Future<void> _createAllTables(Database db) async {
    print('🏗️  Début de la création des tables...');

    // ============ TABLE USERS (pour le login) ============
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT,
        prenom TEXT,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT,
        date_creation TEXT
      )
    ''');
    print('✅ Table users créée');

    // ============ TABLES FORMULAIRES ============

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
    print('✅ Table localites créée');

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
    print('✅ Table ecoles créée');

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
    print('✅ Table marches créée');

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
    print('✅ Table services_santes créée');

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
    print('✅ Table batiments_administratifs créée');

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
    print('✅ Table infrastructures_hydrauliques créée');

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
    print('✅ Table autres_infrastructures créée');

    // Table ponts
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ponts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        x_pont REAL NOT NULL,
        y_pont REAL NOT NULL,
        nom TEXT NOT NULL,
        situation_pont TEXT NOT NULL,
        type_pont TEXT NOT NULL,
        nom_cours_eau TEXT NOT NULL,
        enqueteur TEXT NOT NULL,
        date_creation TEXT NOT NULL,
        date_modification TEXT,
        code_piste TEXT
      )
    ''');
    print('✅ Table ponts créée');

    // Table bacs
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bacs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        x_debut_traversee_bac REAL NOT NULL,
        y_debut_traversee_bac REAL NOT NULL,
        x_fin_traversee_bac REAL NOT NULL,
        y_fin_traversee_bac REAL NOT NULL,
        nom TEXT NOT NULL,
        type_bac TEXT NOT NULL,
        nom_cours_eau TEXT NOT NULL,
        enqueteur TEXT NOT NULL,
        date_creation TEXT NOT NULL,
        date_modification TEXT,
        code_piste TEXT
      )
    ''');
    print('✅ Table bacs créée');

    // Table buses
    await db.execute('''
      CREATE TABLE IF NOT EXISTS buses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        x_buse REAL NOT NULL,
        y_buse REAL NOT NULL,
        nom TEXT NOT NULL,
        enqueteur TEXT NOT NULL,
        date_creation TEXT NOT NULL,
        date_modification TEXT,
        code_piste TEXT
      )
    ''');
    print('✅ Table buses créée');

    // Table dalots
    await db.execute('''
      CREATE TABLE IF NOT EXISTS dalots(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        x_dalot REAL NOT NULL,
        y_dalot REAL NOT NULL,
        nom TEXT NOT NULL,
        situation_dalot TEXT NOT NULL,
        enqueteur TEXT NOT NULL,
        date_creation TEXT NOT NULL,
        date_modification TEXT,
        code_piste TEXT
      )
    ''');
    print('✅ Table dalots créée');

    // Table passages_submersibles
    await db.execute('''
      CREATE TABLE IF NOT EXISTS passages_submersibles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        x_debut_passage_submersible REAL NOT NULL,
        y_debut_passage_submersible REAL NOT NULL,
        x_fin_passage_submersible REAL NOT NULL,
        y_fin_passage_submersible REAL NOT NULL,
        nom TEXT NOT NULL,
        type_materiau TEXT NOT NULL,
        enqueteur TEXT NOT NULL,
        date_creation TEXT NOT NULL,
        date_modification TEXT,
        code_piste TEXT
      )
    ''');
    print('✅ Table passages_submersibles créée');

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
    print('✅ Table points_critiques créée');

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
    print('✅ Table points_coupures créée');

    print("🎉 Toutes les tables ont été créées avec succès !");
  }

  Future<void> _insertDefaultUser(Database db) async {
    try {
      await db.insert(
        'users',
        {
          'nom': 'Agent',
          'prenom': 'Test',
          'email': 'test@ppr.com',
          'password': '12345678',
          'role': 'enqueteur',
          'date_creation': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ Utilisateur par défaut inséré');
    } catch (e) {
      print('⚠️ Erreur insertion utilisateur: $e');
    }
  }

  Future<void> _testDatabaseIntegrity(Database db) async {
    try {
      await db.execute('CREATE TABLE IF NOT EXISTS test (id INTEGER)');
      await db.insert('test', {
        'id': 1
      });
      final results = await db.query('test');
      await db.delete('test', where: 'id = ?', whereArgs: [
        1
      ]);
      print('✅ Accès en écriture confirmé - ${results.length} résultat(s)');
    } catch (e) {
      print('❌ ERREUR ÉCRITURE: $e');
      rethrow;
    }
  }

  Future<void> _logTableSchema(Database db) async {
    print('\n📊 SCHEMA COMPLET DE LA BASE DE DONNÉES:');
    print('=' * 50);

    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';");

    print('📋 Nombre de tables: ${tables.length}');

    for (var t in tables) {
      final tableName = t['name'] as String;
      print('\n📑 Table: $tableName');
      print('─' * 30);

      final columns = await db.rawQuery('PRAGMA table_info($tableName)');

      for (var col in columns) {
        final name = col['name'] as String;
        final type = col['type'] as String;
        final pk = col['pk'] as int;
        final notnull = col['notnull'] as int;

        print('   ├─ $name ($type)'
            '${pk == 1 ? ' [PRIMARY KEY]' : ''}'
            '${notnull == 1 ? ' [NOT NULL]' : ''}');
      }
    }
    print('=' * 50);
  }

  // ============ MÉTHODES USERS (LOGIN) ============

  Future<String?> getAgentFullName(String email) async {
    try {
      final db = await database;
      final result = await db.query(
        'users',
        columns: [
          'prenom',
          'nom'
        ],
        where: 'email = ?',
        whereArgs: [
          email
        ],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final prenom = result.first['prenom'] as String? ?? '';
        final nom = result.first['nom'] as String? ?? '';
        return '$prenom $nom'.trim();
      }
      return null;
    } catch (e) {
      print("❌ Erreur getAgentFullName: $e");
      return null;
    }
  }

  Future<bool> validateUser(String email, String password) async {
    try {
      final db = await database;
      final result = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [
          email,
          password
        ],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      print("❌ Erreur validateUser: $e");
      return false;
    }
  }

  Future<int> insertUser(String prenom, String nom, String email, String password, {String? role}) async {
    try {
      final db = await database;
      return await db.insert(
        'users',
        {
          'prenom': prenom,
          'nom': nom,
          'email': email,
          'password': password,
          'role': role ?? 'enqueteur',
          'date_creation': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print("❌ Erreur insertUser: $e");
      return -1;
    }
  }

  Future<int> deleteAllUsers() async {
    try {
      final db = await database;
      return await db.delete('users');
    } catch (e) {
      print("❌ Erreur deleteAllUsers: $e");
      return -1;
    }
  }

  Future<void> resetDatabase() async {
    try {
      final db = await database;
      await db.close();
      _database = null;
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'app_database.db');
      await deleteDatabase(path);
      print('✅ Base de données réinitialisée');
    } catch (e) {
      print("❌ Erreur resetDatabase: $e");
    }
  }

  // ============ MÉTHODES FORMULAIRES (CRUD) ============

  Future<int> insertEntity(String tableName, Map<String, dynamic> data) async {
    final db = await database;
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, 'app_database.db');
    print('🗂️ Insertion dans: $dbPath');
    print('📋 Table: $tableName');

    final id = await db.insert(tableName, data);
    print("✅ Entité insérée dans $tableName (ID: $id)");
    return id;
  }

  Future<List<Map<String, dynamic>>> getEntities(String tableName) async {
    final db = await database;
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, 'app_database.db');
    print('🗂️ Lecture depuis: $dbPath');
    print('📋 Table: $tableName');

    final List<Map<String, dynamic>> maps = await db.query(tableName);
    print("📊 ${maps.length} entité(s) dans $tableName:");
    for (var entity in maps) {
      print("   ➡️ $entity");
    }

    return maps;
  }

  Future<List<Map<String, dynamic>>> getAllPoints() async {
    final db = await database;
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, 'app_database.db');
    print('🗂️ Scan complet depuis: $dbPath');

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
          point.addAll(_getCoordinatesMapFromPoint(point));
          allPoints.add(point);
        }
        print("📍 ${points.length} point(s) récupérés de $table");
      } catch (e) {
        print("⚠️ Table $table non trouvée ou erreur: $e");
      }
    }

    print("🎯 Total des points récupérés: ${allPoints.length}");
    return allPoints;
  }

  String _getEntityTypeFromTable(String tableName) {
    const entityTypes = {
      'localites': 'Localité',
      'ecoles': 'École',
      'marches': 'Marché',
      'services_santes': 'Service de Santé',
      'batiments_administratifs': 'Bâtiment Administratif',
      'infrastructures_hydrauliques': 'Infrastructure Hydraulique',
      'autres_infrastructures': 'Autre Infrastructure',
      'ponts': 'Pont',
      'bacs': 'Bac',
      'buses': 'Buse',
      'dalots': 'Dalot',
      'passages_submersibles': 'Passage Submersible',
      'points_critiques': 'Point Critique',
      'points_coupures': 'Point de Coupure',
    };
    return entityTypes[tableName] ?? tableName;
  }

  Map<String, dynamic> _getCoordinatesMapFromPoint(Map<String, dynamic> point) {
    final tableName = point['table_name'];

    final coordinateMappings = {
      'localites': {
        'lat': 'x_localite',
        'lng': 'y_localite'
      },
      'ecoles': {
        'lat': 'x_ecole',
        'lng': 'y_ecole'
      },
      'marches': {
        'lat': 'x_marche',
        'lng': 'y_marche'
      },
      'services_santes': {
        'lat': 'x_sante',
        'lng': 'y_sante'
      },
      'batiments_administratifs': {
        'lat': 'x_batiment_administratif',
        'lng': 'y_batiment_administratif'
      },
      'infrastructures_hydrauliques': {
        'lat': 'x_infrastructure_hydraulique',
        'lng': 'y_infrastructure_hydraulique'
      },
      'autres_infrastructures': {
        'lat': 'x_autre_infrastructure',
        'lng': 'y_autre_infrastructure'
      },
      'ponts': {
        'lat': 'x_pont',
        'lng': 'y_pont'
      },
      'buses': {
        'lat': 'x_buse',
        'lng': 'y_buse'
      },
      'dalots': {
        'lat': 'x_dalot',
        'lng': 'y_dalot'
      },
      'points_critiques': {
        'lat': 'x_point_critique',
        'lng': 'y_point_critique'
      },
      'points_coupures': {
        'lat': 'x_point_coupure',
        'lng': 'y_point_coupure'
      },
    };

    final multiPointMappings = {
      'bacs': {
        'lat': 'x_debut_traversee_bac',
        'lng': 'y_debut_traversee_bac',
        'lat_fin': 'x_fin_traversee_bac',
        'lng_fin': 'y_fin_traversee_bac'
      },
      'passages_submersibles': {
        'lat': 'x_debut_passage_submersible',
        'lng': 'y_debut_passage_submersible',
        'lat_fin': 'x_fin_passage_submersible',
        'lng_fin': 'y_fin_passage_submersible'
      },
    };

    if (multiPointMappings.containsKey(tableName)) {
      final mapping = multiPointMappings[tableName]!;
      return {
        'lat': point[mapping['lat']],
        'lng': point[mapping['lng']],
        'lat_fin': point[mapping['lat_fin']],
        'lng_fin': point[mapping['lng_fin']],
      };
    }

    if (coordinateMappings.containsKey(tableName)) {
      final mapping = coordinateMappings[tableName]!;
      return {
        'lat': point[mapping['lat']],
        'lng': point[mapping['lng']],
      };
    }

    return {
      'lat': 0,
      'lng': 0
    };
  }

  Future<int> deleteEntity(String tableName, int id) async {
    final db = await database;
    final result = await db.delete(tableName, where: 'id = ?', whereArgs: [
      id
    ]);
    print("🗑️  Entité supprimée de $tableName (ID: $id)");
    return result;
  }

  Future<int> updateEntity(String tableName, int id, Map<String, dynamic> data) async {
    final db = await database;
    final result = await db.update(tableName, data, where: 'id = ?', whereArgs: [
      id
    ]);
    print("✏️  Entité mise à jour dans $tableName (ID: $id)");
    return result;
  }

  Future<int> countEntities(String tableName) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $tableName');
    final count = Sqflite.firstIntValue(result) ?? 0;
    print("🔢 $tableName contient $count entité(s)");
    return count;
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
        print("📦 Données exportées de $table: ${data.length} entité(s)");
      } catch (e) {
        print("⚠️ Erreur lors de l'export de $table: $e");
      }
    }

    print("📤 Export complet terminé: ${allData.length} tables exportées");
    return allData;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print("🔒 Base de données fermée");
    }
  }
}
