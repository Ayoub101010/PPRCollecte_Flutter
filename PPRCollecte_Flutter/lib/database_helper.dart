import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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
    // Utilisation du chemin de base de données interne
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');
    print('📂 Chemin absolu DB: $path');

    // CORRECTION: On ne supprime plus la DB existante automatiquement
    // On vérifie seulement si elle existe pour logging
    final dbExists = await databaseExists(path);
    print(dbExists ? '📁 Base de données existante' : '🆕 Nouvelle base de données');

    // CORRECTION: Création du répertoire si nécessaire
    final dbDir = Directory(dbPath);
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
      print('📁 Répertoire créé: $dbPath');
    }

    return await openDatabase(
      path,
      version: 11, // Version augmentée pour la fusion
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

    // ============ TABLE USERS ============
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

    // ============ TABLE LOCALITES ============
    await db.execute('''
    CREATE TABLE IF NOT EXISTS localites(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      x_localite REAL NOT NULL,
      y_localite REAL NOT NULL,
      nom TEXT NOT NULL,
      type TEXT NOT NULL,
      enqueteur TEXT NOT NULL,
      date_creation TEXT NOT NULL,
      date_modification TEXT,
      code_piste TEXT,
      synced INTEGER DEFAULT 0,      -- ← COLONNE AJOUTÉE
      date_sync TEXT                 -- ← COLONNE AJOUTÉE
    )
  ''');
    print('✅ Table localites créée');

    // ============ TABLE ECOLES ============
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
      code_piste TEXT,
      synced INTEGER DEFAULT 0,      -- ← COLONNE AJOUTÉE
      date_sync TEXT                 -- ← COLONNE AJOUTÉE
    )
  ''');
    print('✅ Table ecoles créée');

    // ============ TABLE MARCHES ============
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
      code_piste TEXT,
      synced INTEGER DEFAULT 0,      -- ← COLONNE AJOUTÉE
      date_sync TEXT                 -- ← COLONNE AJOUTÉE
    )
  ''');
    print('✅ Table marches créée');

    // ============ TABLE SERVICES_SANTES ============
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
      code_piste TEXT,
      synced INTEGER DEFAULT 0,      -- ← COLONNE AJOUTÉE
      date_sync TEXT                 -- ← COLONNE AJOUTÉE
    )
  ''');
    print('✅ Table services_santes créée');

    // ============ TABLE BATIMENTS_ADMINISTRATIFS ============
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
      code_piste TEXT,
      synced INTEGER DEFAULT 0,      -- ← COLONNE AJOUTÉE
      date_sync TEXT                 -- ← COLONNE AJOUTÉE
    )
  ''');
    print('✅ Table batiments_administratifs créée');

    // ============ TABLE INFRASTRUCTURES_HYDRAULIQUES ============
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
      code_piste TEXT,
      synced INTEGER DEFAULT 0,      -- ← COLONNE AJOUTÉE
      date_sync TEXT                 -- ← COLONNE AJOUTÉE
    )
  ''');
    print('✅ Table infrastructures_hydrauliques créée');

    // ============ TABLE AUTRES_INFRASTRUCTURES ============
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
      code_piste TEXT,
      synced INTEGER DEFAULT 0,      -- ← COLONNE AJOUTÉE
      date_sync TEXT                 -- ← COLONNE AJOUTÉE
    )
  ''');
    print('✅ Table autres_infrastructures créée');

    // ============ TABLE PONTS ============
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
      code_piste TEXT,
      synced INTEGER DEFAULT 0,      -- ← COLONNE AJOUTÉE
      date_sync TEXT                 -- ← COLONNE AJOUTÉE
    )
  ''');
    print('✅ Table ponts créée');

    // ============ TABLE BACS ============
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
      code_piste TEXT,
      synced INTEGER DEFAULT 0,      -- ← COLONNE AJOUTÉE
      date_sync TEXT                 -- ← COLONNE AJOUTÉE
    )
  ''');
    print('✅ Table bacs créée');

    // ============ TABLE BUSES ============
    await db.execute('''
    CREATE TABLE IF NOT EXISTS buses(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      x_buse REAL NOT NULL,
      y_buse REAL NOT NULL,
      nom TEXT NOT NULL,
      enqueteur TEXT NOT NULL,
      date_creation TEXT NOT NULL,
      date_modification TEXT,
      code_piste TEXT,
      synced INTEGER DEFAULT 0,      -- ← COLONNE AJOUTÉE
      date_sync TEXT                 -- ← COLONNE AJOUTÉE
    )
  ''');
    print('✅ Table buses créée');

    // ============ TABLE DALOTS ============
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
      code_piste TEXT,
      synced INTEGER DEFAULT 0,      -- ← COLONNE AJOUTÉE
      date_sync TEXT                 -- ← COLONNE AJOUTÉE
    )
  ''');
    print('✅ Table dalots créée');

    // ============ TABLE PASSAGES_SUBMERSIBLES ============
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
      code_piste TEXT,
      synced INTEGER DEFAULT 0,      -- ← COLONNE AJOUTÉE
      date_sync TEXT                 -- ← COLONNE AJOUTÉE
    )
  ''');
    print('✅ Table passages_submersibles créée');

    // ============ TABLE POINTS_CRITIQUES ============
    await db.execute('''
    CREATE TABLE IF NOT EXISTS points_critiques(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      x_point_critique REAL NOT NULL,
      y_point_critique REAL NOT NULL,
      type_point_critique TEXT NOT NULL,
      enqueteur TEXT NOT NULL,
      date_creation TEXT NOT NULL,
      date_modification TEXT,
      code_piste TEXT,
      synced INTEGER DEFAULT 0,      -- ← COLONNE AJOUTÉE
      date_sync TEXT                 -- ← COLONNE AJOUTÉE
    )
  ''');
    print('✅ Table points_critiques créée');

    // ============ TABLE POINTS_COUPURES ============
    await db.execute('''
    CREATE TABLE IF NOT EXISTS points_coupures(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      x_point_coupure REAL NOT NULL,
      y_point_coupure REAL NOT NULL,
      causes_coupures TEXT NOT NULL,
      enqueteur TEXT NOT NULL,
      date_creation TEXT NOT NULL,
      date_modification TEXT,
      code_piste TEXT,
      synced INTEGER DEFAULT 0,      -- ← COLONNE AJOUTÉE
      date_sync TEXT                 -- ← COLONNE AJOUTÉE
    )
  ''');
    print('✅ Table points_coupures créée');

    // ============ TABLE TEST ============
    await db.execute('CREATE TABLE IF NOT EXISTS test (id INTEGER)');
    print('✅ Table test créée');

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
      // CORRECTION: On utilise la table test qui a été créée dans _createAllTables
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
      // NOUVEAU: Afficher le contenu de la table (sauf pour les tables système)
      if (tableName != 'android_metadata' && tableName != 'test') {
        try {
          final content = await db.query(tableName);
          print('   └─ 📊 CONTENU (${content.length} enregistrement(s)):');

          if (content.isEmpty) {
            print('      └─ Aucune donnée');
          } else {
            for (var i = 0; i < content.length; i++) {
              final row = content[i];
              print('      ${i + 1}.');
              row.forEach((key, value) {
                print('         ├─ $key: $value');
              });
              if (i < content.length - 1) {
                print('         │');
              }
            }
          }
        } catch (e) {
          print('   └─ ❌ Erreur lecture contenu: $e');
        }
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

      // CORRECTION: Utilisation du bon chemin pour la suppression
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'app_database.db');

      if (await databaseExists(path)) {
        await deleteDatabase(path);
      }

      print('✅ Base de données réinitialisée');
    } catch (e) {
      print("❌ Erreur resetDatabase: $e");
    }
  }

  // ============ MÉTHODES FORMULAIRES (CRUD) ============

  Future<int> insertEntity(String tableName, Map<String, dynamic> data) async {
    final db = await database;
    // CORRECTION: Utilisation du bon chemin
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');
    print('🗂️ Insertion dans: $path');
    print('📋 Table: $tableName');
    // NOUVEAU: Afficher les champs et valeurs qui seront insérés
    print('📝 Champs à insérer:');
    data.forEach((key, value) {
      print('   ├─ $key: $value (${value.runtimeType})');
    });

    final id = await db.insert(tableName, data);
    print("✅ Entité insérée dans $tableName (ID: $id)");
    return id;
  }

  Future<List<Map<String, dynamic>>> getEntities(String tableName) async {
    final db = await database;
    // CORRECTION: Utilisation du bon chemin
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');
    print('🗂️ Lecture depuis: $path');
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
    // CORRECTION: Utilisation du bon chemin
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');
    print('🗂️ Scan complet depuis: $path');

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

  // Dans la classe DatabaseHelper, ajoutez:

  Future<List<Map<String, dynamic>>> getUnsyncedEntities(String tableName) async {
    final db = await database;

    // Vérifier si la table a une colonne 'synced'
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final hasSyncedColumn = columns.any((col) => col['name'] == 'synced');

    if (hasSyncedColumn) {
      return await db.query(tableName, where: 'synced = ? OR synced IS NULL', whereArgs: [
        0
      ]);
    } else {
      // Si la table n'a pas de colonne synced, retourner toutes les données
      return await db.query(tableName);
    }
  }

  Future<void> markAsSynced(String tableName, int id) async {
    final db = await database;

    // Vérifier si la table a une colonne 'synced'
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final hasSyncedColumn = columns.any((col) => col['name'] == 'synced');
    final hasDateSyncColumn = columns.any((col) => col['name'] == 'date_sync');

    if (hasSyncedColumn && hasDateSyncColumn) {
      await db.update(
          tableName,
          {
            'synced': 1,
            'date_sync': DateTime.now().toIso8601String()
          },
          where: 'id = ?',
          whereArgs: [
            id
          ]);
    } else if (hasSyncedColumn) {
      await db.update(
          tableName,
          {
            'synced': 1
          },
          where: 'id = ?',
          whereArgs: [
            id
          ]);
    }
    // Si la table n'a pas de colonne synced, on ne fait rien
  }

  /// Sauvegarde ou met à jour une localité depuis PostgreSQL
  Future<void> saveOrUpdateLocalite(Map<String, dynamic> geoJsonData) async {
    final db = await database;

    try {
      // Extraire les données du GeoJSON
      final properties = geoJsonData['properties'];
      final geometry = geoJsonData['geometry'];
      final sqliteId = properties['sqlite_id'];

      final existing = await db.query(
        'localites',
        where: 'id = ?',
        whereArgs: [
          sqliteId
        ],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert(
          'localites',
          {
            'id': properties['sqlite_id'], // ID original de SQLite
            'x_localite': geometry['coordinates'][0], // longitude
            'y_localite': geometry['coordinates'][1], // latitude
            'nom': properties['nom'] ?? 'Sans nom',
            'type': properties['type'] ?? 'Non spécifié',
            'enqueteur': properties['enqueteur'] ?? 'Sync',
            'date_creation': properties['created_at'] ?? 'Non spécifié',
            'date_modification': properties['updated_at'] ?? 'Non spécifié',
            'code_piste': properties['code_piste'] ?? 'Non spécifié',
            'synced': 1, // Déjà synchronisé
            'date_sync': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        print('✅ Localité sauvegardée: ${properties['nom']}');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde localité: $e');
      rethrow;
    }
  }

  /// Sauvegarde ou met à jour une école depuis PostgreSQL
  Future<void> saveOrUpdateEcole(Map<String, dynamic> geoJsonData) async {
    final db = await database;

    try {
      // Extraire les données du GeoJSON
      final properties = geoJsonData['properties'];
      final geometry = geoJsonData['geometry'];
      final sqliteId = properties['sqlite_id'];

      final existing = await db.query(
        'ecoles',
        where: 'id = ?',
        whereArgs: [
          sqliteId
        ],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert(
          'ecoles',
          {
            'id': properties['sqlite_id'],
            'x_ecole': geometry['coordinates'][0],
            'y_ecole': geometry['coordinates'][1],
            'nom': properties['nom'] ?? 'Sans nom',
            'type': properties['type'] ?? 'Non spécifié',
            'enqueteur': properties['enqueteur'] ?? 'Sync',
            'date_creation': properties['created_at'] ?? 'Non spécifié',
            'date_modification': properties['updated_at'] ?? 'Non spécifié',
            'code_piste': properties['code_piste'] ?? 'Non spécifié',
            'synced': 1,
            'date_sync': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('✅ école sauvegardée: ${properties['nom']}');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde école: $e');
      rethrow;
    }
  }

  /// Sauvegarde ou met à jour une marché depuis PostgreSQL
  Future<void> saveOrUpdateMarche(Map<String, dynamic> geoJsonData) async {
    final db = await database;

    try {
      // Extraire les données du GeoJSON
      final properties = geoJsonData['properties'];
      final geometry = geoJsonData['geometry'];
      final sqliteId = properties['sqlite_id'];

      final existing = await db.query(
        'marches',
        where: 'id = ?',
        whereArgs: [
          sqliteId
        ],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert(
          'marches',
          {
            'id': properties['sqlite_id'],
            'x_marche': geometry['coordinates'][0],
            'y_marche': geometry['coordinates'][1],
            'nom': properties['nom'] ?? 'Sans nom',
            'type': properties['type'] ?? 'Non spécifié',
            'enqueteur': properties['enqueteur'] ?? 'Sync',
            'date_creation': properties['created_at'] ?? 'Non spécifié',
            'date_modification': properties['updated_at'] ?? 'Non spécifié',
            'code_piste': properties['code_piste'] ?? 'Non spécifié',
            'synced': 1,
            'date_sync': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('✅ Marché sauvegardée: ${properties['nom']}');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde Marché: $e');
      rethrow;
    }
  }

  // ============ SERVICES SANTES ============
  Future<void> saveOrUpdateServiceSante(Map<String, dynamic> geoJsonData) async {
    final db = await database;

    try {
      // Extraire les données du GeoJSON
      final properties = geoJsonData['properties'];
      final geometry = geoJsonData['geometry'];
      final sqliteId = properties['sqlite_id'];

      final existing = await db.query(
        'services_santes',
        where: 'id = ?',
        whereArgs: [
          sqliteId
        ],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert(
          'services_santes',
          {
            'id': properties['sqlite_id'],
            'x_sante': geometry['coordinates'][0],
            'y_sante': geometry['coordinates'][1],
            'nom': properties['nom'] ?? 'Sans nom',
            'type': properties['type'] ?? 'Non spécifié',
            'enqueteur': properties['enqueteur'] ?? 'Sync',
            'date_creation': properties['created_at'] ?? 'Non spécifié',
            'date_modification': properties['updated_at'] ?? 'Non spécifié',
            'code_piste': properties['code_piste'] ?? 'Non spécifié',
            'synced': 1,
            'date_sync': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('✅ services_santes sauvegardée: ${properties['nom']}');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde services_santes: $e');
      rethrow;
    }
  }

// ============ BATIMENTS ADMINISTRATIFS ============
  Future<void> saveOrUpdateBatimentAdministratif(Map<String, dynamic> geoJsonData) async {
    final db = await database;
    try {
      // Extraire les données du GeoJSON
      final properties = geoJsonData['properties'];
      final geometry = geoJsonData['geometry'];
      final sqliteId = properties['sqlite_id'];

      final existing = await db.query(
        'batiments_administratifs',
        where: 'id = ?',
        whereArgs: [
          sqliteId
        ],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert(
          'batiments_administratifs',
          {
            'id': properties['sqlite_id'],
            'x_batiment_administratif': geometry['coordinates'][0],
            'y_batiment_administratif': geometry['coordinates'][1],
            'nom': properties['nom'] ?? 'Sans nom',
            'type': properties['type'] ?? 'Non spécifié',
            'enqueteur': properties['enqueteur'] ?? 'Sync',
            'date_creation': properties['created_at'] ?? 'Non spécifié',
            'date_modification': properties['updated_at'] ?? 'Non spécifié',
            'code_piste': properties['code_piste'] ?? 'Non spécifié',
            'synced': 1,
            'date_sync': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('✅ batiments_administratifs sauvegardée: ${properties['nom']}');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde batiments_administratifs: $e');
      rethrow;
    }
  }

// ============ INFRASTRUCTURES HYDRAULIQUES ============
  Future<void> saveOrUpdateInfrastructureHydraulique(Map<String, dynamic> geoJsonData) async {
    final db = await database;
    try {
      // Extraire les données du GeoJSON
      final properties = geoJsonData['properties'];
      final geometry = geoJsonData['geometry'];
      final sqliteId = properties['sqlite_id'];

      final existing = await db.query(
        'infrastructures_hydrauliques',
        where: 'id = ?',
        whereArgs: [
          sqliteId
        ],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert(
          'infrastructures_hydrauliques',
          {
            'id': properties['sqlite_id'],
            'x_infrastructure_hydraulique': geometry['coordinates'][0],
            'y_infrastructure_hydraulique': geometry['coordinates'][1],
            'nom': properties['nom'] ?? 'Sans nom',
            'type': properties['type'] ?? 'Non spécifié',
            'enqueteur': properties['enqueteur'] ?? 'Sync',
            'date_creation': properties['created_at'] ?? 'Non spécifié',
            'date_modification': properties['updated_at'] ?? 'Non spécifié',
            'code_piste': properties['code_piste'] ?? 'Non spécifié',
            'synced': 1,
            'date_sync': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('✅ infrastructures_hydrauliques sauvegardée: ${properties['nom']}');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde infrastructures_hydrauliques: $e');
      rethrow;
    }
  }

// ============ AUTRES INFRASTRUCTURES ============
  Future<void> saveOrUpdateAutreInfrastructure(Map<String, dynamic> geoJsonData) async {
    final db = await database;
    try {
      // Extraire les données du GeoJSON
      final properties = geoJsonData['properties'];
      final geometry = geoJsonData['geometry'];
      final sqliteId = properties['sqlite_id'];

      final existing = await db.query(
        'autres_infrastructures',
        where: 'id = ?',
        whereArgs: [
          sqliteId
        ],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert(
          'autres_infrastructures',
          {
            'id': properties['sqlite_id'],
            'x_autre_infrastructure': geometry['coordinates'][0],
            'y_autre_infrastructure': geometry['coordinates'][1],
            'nom': properties['nom'] ?? 'Sans nom',
            'type': properties['type'] ?? 'Non spécifié',
            'enqueteur': properties['enqueteur'] ?? 'Sync',
            'date_creation': properties['created_at'] ?? 'Non spécifié',
            'date_modification': properties['updated_at'] ?? 'Non spécifié',
            'code_piste': properties['code_piste'] ?? 'Non spécifié',
            'synced': 1,
            'date_sync': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('✅ autres_infrastructures sauvegardée: ${properties['nom']}');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde autres_infrastructures: $e');
      rethrow;
    }
  }

// ============ PONTS ============
  Future<void> saveOrUpdatePont(Map<String, dynamic> geoJsonData) async {
    final db = await database;
    try {
      // Extraire les données du GeoJSON
      final properties = geoJsonData['properties'];
      final geometry = geoJsonData['geometry'];
      final sqliteId = properties['sqlite_id'];

      final existing = await db.query(
        'ponts',
        where: 'id = ?',
        whereArgs: [
          sqliteId
        ],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert(
          'ponts',
          {
            'id': properties['sqlite_id'],
            'x_pont': geometry['coordinates'][0],
            'y_pont': geometry['coordinates'][1],
            'nom': properties['nom'] ?? 'Sans nom',
            'situation_pont': properties['situation_pont'] ?? 'Non spécifié',
            'type_pont': properties['type_pont'] ?? 'Non spécifié',
            'nom_cours_eau': properties['nom_cours_eau'] ?? 'Non spécifié',
            'enqueteur': properties['enqueteur'] ?? 'Sync',
            'date_creation': properties['created_at'] ?? 'Non spécifié',
            'date_modification': properties['updated_at'] ?? 'Non spécifié',
            'code_piste': properties['code_piste'] ?? 'Non spécifié',
            'synced': 1,
            'date_sync': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('✅ ponts sauvegardée: ${properties['nom']}');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde ponts: $e');
      rethrow;
    }
  }

// ============ BACS ============
  Future<void> saveOrUpdateBac(Map<String, dynamic> geoJsonData) async {
    final db = await database;
    try {
      // Extraire les données du GeoJSON
      final properties = geoJsonData['properties'];
      final geometry = geoJsonData['geometry'];
      final sqliteId = properties['sqlite_id'];

      final existing = await db.query(
        'bacs',
        where: 'id = ?',
        whereArgs: [
          sqliteId
        ],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert(
          'bacs',
          {
            'id': properties['sqlite_id'],
            'x_debut_traversee_bac': geometry['coordinates'][0],
            'y_debut_traversee_bac': geometry['coordinates'][1],
            'x_fin_traversee_bac': properties['x_fin_traversee_bac'] ?? 'Non spécifié',
            'y_fin_traversee_bac': properties['y_fin_traversee_bac'] ?? 'Non spécifié',
            'nom': properties['nom'] ?? 'Sans nom',
            'type_bac': properties['type_bac'] ?? 'Non spécifié',
            'nom_cours_eau': properties['nom_cours_eau'] ?? 'Non spécifié',
            'enqueteur': properties['enqueteur'] ?? 'Sync',
            'date_creation': properties['created_at'] ?? 'Non spécifié',
            'date_modification': properties['updated_at'] ?? 'Non spécifié',
            'code_piste': properties['code_piste'] ?? 'Non spécifié',
            'synced': 1,
            'date_sync': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('✅ bacs sauvegardée: ${properties['nom']}');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde bacs: $e');
      rethrow;
    }
  }

// ============ BUSES ============
  Future<void> saveOrUpdateBuse(Map<String, dynamic> geoJsonData) async {
    final db = await database;
    try {
      // Extraire les données du GeoJSON
      final properties = geoJsonData['properties'];
      final geometry = geoJsonData['geometry'];
      final sqliteId = properties['sqlite_id'];

      final existing = await db.query(
        'buses',
        where: 'id = ?',
        whereArgs: [
          sqliteId
        ],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert(
          'buses',
          {
            'id': properties['sqlite_id'],
            'x_buse': geometry['coordinates'][0] ?? 'Non spécifié',
            'y_buse': geometry['coordinates'][1] ?? 'Non spécifié',
            'nom': properties['nom'] ?? 'Sans nom',
            'enqueteur': properties['enqueteur'] ?? 'Sync',
            'date_creation': properties['created_at'] ?? 'Non spécifié',
            'date_modification': properties['updated_at'] ?? 'Non spécifié',
            'code_piste': properties['code_piste'] ?? 'Non spécifié',
            'synced': 1,
            'date_sync': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('✅ buses sauvegardée: ${properties['nom']}');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde buses: $e');
      rethrow;
    }
  }

// ============ DALOTS ============
  Future<void> saveOrUpdateDalot(Map<String, dynamic> geoJsonData) async {
    final db = await database;
    try {
      // Extraire les données du GeoJSON
      final properties = geoJsonData['properties'];
      final geometry = geoJsonData['geometry'];
      final sqliteId = properties['sqlite_id'];

      final existing = await db.query(
        'dalots',
        where: 'id = ?',
        whereArgs: [
          sqliteId
        ],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert(
          'dalots',
          {
            'id': properties['sqlite_id'],
            'x_dalot': geometry['coordinates'][0] ?? 'Non spécifié',
            'y_dalot': geometry['coordinates'][1] ?? 'Non spécifié',
            'nom': properties['nom'] ?? 'Sans nom',
            'situation_dalot': properties['situation_dalot'] ?? 'Non spécifié',
            'enqueteur': properties['enqueteur'] ?? 'Sync',
            'date_creation': properties['created_at'] ?? 'Non spécifié',
            'date_modification': properties['updated_at'] ?? 'Non spécifié',
            'code_piste': properties['code_piste'] ?? 'Non spécifié',
            'synced': 1,
            'date_sync': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('✅ dalots sauvegardée: ${properties['nom']}');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde dalots: $e');
      rethrow;
    }
  }

// ============ PASSAGES SUBMERSIBLES ============
  Future<void> saveOrUpdatePassageSubmersible(Map<String, dynamic> geoJsonData) async {
    final db = await database;
    try {
      // Extraire les données du GeoJSON
      final properties = geoJsonData['properties'];
      final geometry = geoJsonData['geometry'];
      final sqliteId = properties['sqlite_id'];

      final existing = await db.query(
        'passages_submersibles',
        where: 'id = ?',
        whereArgs: [
          sqliteId
        ],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert(
          'passages_submersibles',
          {
            'id': properties['sqlite_id'],
            'x_debut_passage_submersible': geometry['coordinates'][0],
            'y_debut_passage_submersible': geometry['coordinates'][1],
            'x_fin_passage_submersible': properties['x_fin_passage_submersible'] ?? 'Non spécifié',
            'y_fin_passage_submersible': properties['y_fin_passage_submersible'] ?? 'Non spécifié',
            'nom': properties['nom'] ?? 'Sans nom',
            'type_materiau': properties['type_materiau'] ?? 'Non spécifié',
            'enqueteur': properties['enqueteur'] ?? 'Sync',
            'date_creation': properties['created_at'] ?? 'Non spécifié',
            'date_modification': properties['updated_at'] ?? 'Non spécifié',
            'code_piste': properties['code_piste'] ?? 'Non spécifié',
            'synced': 1,
            'date_sync': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('✅ passages_submersibles sauvegardée: ${properties['nom']}');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde passages_submersibles: $e');
      rethrow;
    }
  }

// ============ POINTS CRITIQUES ============
  Future<void> saveOrUpdatePointCritique(Map<String, dynamic> geoJsonData) async {
    final db = await database;
    try {
      // Extraire les données du GeoJSON
      final properties = geoJsonData['properties'];
      final geometry = geoJsonData['geometry'];
      final sqliteId = properties['sqlite_id'];

      final existing = await db.query(
        'points_critiques',
        where: 'id = ?',
        whereArgs: [
          sqliteId
        ],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert(
          'points_critiques',
          {
            'id': properties['sqlite_id'],
            'x_point_critique': geometry['coordinates'][0],
            'y_point_critique': geometry['coordinates'][1],
            'type_point_critique': properties['type_point_critique'] ?? 'Non spécifié',
            'enqueteur': properties['enqueteur'] ?? 'Sync',
            'date_creation': properties['created_at'] ?? 'Non spécifié',
            'date_modification': properties['updated_at'] ?? 'Non spécifié',
            'code_piste': properties['code_piste'] ?? 'Non spécifié',
            'synced': 1,
            'date_sync': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('✅ points_critiques sauvegardée: ${properties['nom']}');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde points_critiques: $e');
      rethrow;
    }
  }

// ============ POINTS COUPURES ============
  Future<void> saveOrUpdatePointCoupure(Map<String, dynamic> geoJsonData) async {
    final db = await database;
    try {
      // Extraire les données du GeoJSON
      final properties = geoJsonData['properties'];
      final geometry = geoJsonData['geometry'];
      final sqliteId = properties['sqlite_id'];

      final existing = await db.query(
        'points_coupures',
        where: 'id = ?',
        whereArgs: [
          sqliteId
        ],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert(
          'points_coupures',
          {
            'id': properties['sqlite_id'],
            'x_point_coupure': geometry['coordinates'][0],
            'y_point_coupure': geometry['coordinates'][1],
            'causes_coupures': properties['causes_coupures'] ?? 'Non spécifié',
            'enqueteur': properties['enqueteur'] ?? 'Sync',
            'date_creation': properties['created_at'] ?? 'Non spécifié',
            'date_modification': properties['updated_at'] ?? 'Non spécifié',
            'code_piste': properties['code_piste'] ?? 'Non spécifié',
            'synced': 1,
            'date_sync': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('✅ points_coupures sauvegardée: ${properties['nom']}');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde points_coupures: $e');
      rethrow;
    }
  }
}
