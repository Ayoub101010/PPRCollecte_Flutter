// lib/simple_storage_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'piste_model.dart';
import 'chaussee_model.dart';
import 'dart:convert'; // Pour jsonEncode/jsonDecode
import 'package:flutter/material.dart'; // Pour Color
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Pour LatLng et Polyline
import 'api_service.dart';

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
            id INTEGER PRIMARY KEY ,
            code_piste TEXT NOT NULL,
            commune_rurale_id TEXT,
            user_login TEXT ,
            heure_debut TEXT ,
            heure_fin TEXT ,
            nom_origine_piste TEXT ,
            x_origine REAL ,
            y_origine REAL ,
            nom_destination_piste TEXT ,
            x_destination REAL ,
            y_destination REAL ,
            existence_intersection INTEGER DEFAULT 0, -- ← NOUVEAU
      x_intersection REAL,                      -- ← NOUVEAU
      y_intersection REAL,                      -- ← NOUVEAU
      intersection_piste_code TEXT,             -- ← NOUVEAU
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
            created_at TEXT ,
            updated_at TEXT,
            sync_status TEXT DEFAULT 'pending',
            login_id INTEGER,
            synced INTEGER DEFAULT 0,
            date_sync TEXT,
            downloaded INTEGER DEFAULT 0
            
          )
        ''');

        // Table Chaussées
        await db.execute('''
          CREATE TABLE chaussees (
            id INTEGER PRIMARY KEY ,
            code_piste TEXT NOT NULL,
            code_gps TEXT ,
            user_login TEXT ,
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
            created_at TEXT NOT NULL,
             updated_at TEXT, -- ← NOUVEAU
    
    sync_status TEXT DEFAULT 'pending', 
    login_id INTEGER, 
    synced INTEGER DEFAULT 0,
    date_sync TEXT,
    downloaded INTEGER DEFAULT 0

          )
        ''');
        // Table pour le cache des pistes affichées
        await db.execute('''
  CREATE TABLE IF NOT EXISTS displayed_pistes (
    id INTEGER PRIMARY KEY,
    points_json TEXT NOT NULL,
    color INTEGER NOT NULL,
    width INTEGER NOT NULL,
    created_at TEXT NOT NULL
  )
''');

        print('✅ Tables créées avec succès');
      },
    );
  }

// Sauvegarder une piste affichée
  Future<void> saveDisplayedPiste(List<LatLng> points, Color color, double width) async {
    try {
      final db = await database;
      final pointsJson = jsonEncode(points
          .map((p) => {
                'lat': p.latitude,
                'lng': p.longitude
              })
          .toList());

      await db.insert('displayed_pistes', {
        'points_json': pointsJson,
        'color': color.value,
        'width': width.toInt(),
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Piste affichée sauvegardée (${points.length} points)');
    } catch (e) {
      print('❌ Erreur sauvegarde piste affichée: $e');
    }
  }

  // Charger toutes les pistes affichées
  Future<List<Polyline>> loadDisplayedPistes() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('displayed_pistes');

      final List<Polyline> polylines = [];

      for (final map in maps) {
        final pointsData = jsonDecode(map['points_json']) as List;
        final List<LatLng> points = [];

        for (final p in pointsData) {
          final lat = p['lat'] as double?;
          final lng = p['lng'] as double?;
          if (lat != null && lng != null) {
            points.add(LatLng(lat, lng));
          }
        }

        if (points.isNotEmpty) {
          polylines.add(Polyline(
            polylineId: PolylineId('displayed_piste_${map['id']}'),
            points: points,
            color: Color(map['color'] as int),
            width: map['width'] as int, // ← ICI: Supprimez .toDouble()
          ));
        }
      }

      return polylines;
    } catch (e) {
      print('❌ Erreur chargement pistes affichées: $e');
      return [];
    }
  }

  /// Sauvegarder une piste depuis le formulaire
  Future<int?> savePiste(Map<String, dynamic> formData) async {
    try {
      final loginId = ApiService.userId;

      // Ajouter le login_id aux données du formulaire
      final formDataWithLoginId = Map<String, dynamic>.from(formData);
      formDataWithLoginId['login_id'] = loginId;
      print('🔄 Début sauvegarde piste...');
      print('📋 Données reçues:');
      formData.forEach((key, value) {
        // Ne pas logger les données trop longues (comme points_json)
        if (key != 'points' && key != 'points_json') {
          print('   $key: $value');
        }
      });

      final piste = PisteModel.fromFormData(formData);
      final db = await database;
      final id = await db.insert('pistes', piste.toMap());

      print('✅ Piste "${piste.codePiste}" sauvegardée avec ID: $id');

      // AFFICHER TOUS LES CHAMPS DE LA PISTE
      print('📊 Détails de la piste enregistrée:');
      final pisteMap = piste.toMap();
      pisteMap.forEach((key, value) {
        if (key != 'points_json') {
          // Éviter le JSON trop long
          print('   $key: $value');
        } else {
          print('   $key: [JSON contenant ${piste.pointsJson.length} caractères]');
        }
      });

      return id;
    } catch (e) {
      print('❌ Erreur sauvegarde piste: $e');
      print('📋 Données qui ont causé l\'erreur:');
      formData.forEach((key, value) {
        print('   $key: $value (type: ${value.runtimeType})');
      });
      return null;
    }
  }

// Dans SimpleStorageHelper, ajoutez cette méthode
  Future<void> debugPrintAllPistes() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> pistes = await db.query('pistes');

      print('📊 === LISTE COMPLÈTE DES PISTES ===');
      print('📈 Nombre total de pistes: ${pistes.length}');

      for (var i = 0; i < pistes.length; i++) {
        final piste = pistes[i];
        print('\n🎯 PISTE #${i + 1}');
        piste.forEach((key, value) {
          if (key != 'points_json') {
            print('   $key: $value');
          } else {
            final pointsJson = value.toString();
            print('   $key: [${pointsJson.length} caractères]');
            // Pour voir un extrait du JSON :
            if (pointsJson.length > 50) {
              print('        Extrait: ${pointsJson.substring(0, 50)}...');
            }
          }
        });
      }
      print('====================================');
    } catch (e) {
      print('❌ Erreur lecture pistes: $e');
    }
  }

  /// Sauvegarder une chaussée depuis le formulaire
  /// Sauvegarder une chaussée depuis le formulaire
  Future<int?> saveChaussee(Map<String, dynamic> formData) async {
    try {
      final loginId = ApiService.userId;

      // Vérifier si on est en mode édition
      final bool isEditing = formData['is_editing'] ?? false;
      final int? existingId = formData['id'];

      if (isEditing && existingId != null) {
        // MODE ÉDITION: Mise à jour
        await updateChaussee(formData);
        print('✅ Chaussée "${formData['code_piste']}" mise à jour (ID: $existingId)');
        return existingId;
      } else {
        // MODE CRÉATION: Insertion
        final formDataWithLoginId = Map<String, dynamic>.from(formData);
        formDataWithLoginId['login_id'] = loginId;

        final chaussee = ChausseeModel.fromFormData(formDataWithLoginId);
        final db = await database;
        final id = await db.insert('chaussees', chaussee.toMap());

        print('✅ Chaussée "${chaussee.codePiste}" sauvegardée avec ID: $id');
        return id;
      }
    } catch (e) {
      print('❌ Erreur sauvegarde chaussée: $e');
      return null;
    }
  }

  Future<void> updateChaussee(Map<String, dynamic> chausseeData) async {
    try {
      final db = await database;

      // Préparer les données pour la mise à jour
      final updateData = {
        'code_piste': chausseeData['code_piste'],
        'code_gps': chausseeData['code_gps'],
        'endroit': chausseeData['endroit'],
        'type_chaussee': chausseeData['type_chaussee'],
        'etat_piste': chausseeData['etat_piste'],
        'x_debut_chaussee': chausseeData['x_debut_chaussee'],
        'y_debut_chaussee': chausseeData['y_debut_chaussee'],
        'x_fin_chaussee': chausseeData['x_fin_chaussee'],
        'y_fin_chaussee': chausseeData['y_fin_chaussee'],
        'points_json': jsonEncode(chausseeData['points_collectes']),
        'distance_totale_m': chausseeData['distance_totale_m'],
        'nombre_points': chausseeData['nombre_points'],
        'updated_at': DateTime.now().toIso8601String(), // ← FORCER l'heure actuelle
        'user_login': chausseeData['user_login'],
        'login_id': chausseeData['login_id'],
      };

      await db.update(
        'chaussees',
        updateData,
        where: 'id = ?',
        whereArgs: [
          chausseeData['id']
        ],
      );

      print('✅ Chaussée ${chausseeData['id']} mise à jour avec succès');
    } catch (e) {
      print('❌ Erreur mise à jour chaussée: $e');
      rethrow;
    }
  }

// Dans SimpleStorageHelper class
  Future<void> debugPrintAllChaussees() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> chaussees = await db.query('chaussees');

      print('📊 === LISTE COMPLÈTE DES CHAUSSÉES ===');
      print('📈 Nombre total de chaussées: ${chaussees.length}');

      for (var i = 0; i < chaussees.length; i++) {
        final chaussee = chaussees[i];
        print('\n🎯 CHAUSSÉE #${i + 1}');
        chaussee.forEach((key, value) {
          if (key != 'points_json') {
            print('   $key: $value');
          } else {
            final pointsJson = value.toString();
            print('   $key: [${pointsJson.length} caractères]');
            // Pour voir un extrait du JSON :
            if (pointsJson.length > 50) {
              print('        Extrait: ${pointsJson.substring(0, 50)}...');
            }
          }
        });
      }
      print('=====================================');
    } catch (e) {
      print('❌ Erreur lecture chaussées: $e');
    }
  }

  /// Lister toutes les pistes (optionnel pour debug)
  Future<List<PisteModel>> getAllPistes() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('pistes', orderBy: 'created_at DESC');
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
      final List<Map<String, dynamic>> maps = await db.query('chaussees', orderBy: 'created_at DESC');
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
      final pisteCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pistes')) ?? 0;
      final chausseeCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM chaussees')) ?? 0;

      return {
        'pistes': pisteCount,
        'chaussees': chausseeCount,
        'total': pisteCount + chausseeCount,
      };
    } catch (e) {
      print('❌ Erreur comptage: $e');
      return {
        'pistes': 0,
        'chaussees': 0,
        'total': 0
      };
    }
  }

// Récupérer seulement les pistes créées par l'utilisateur (à synchroniser)
  Future<List<Map<String, dynamic>>> getUserPistes() async {
    final db = await database;
    return await db.query(
      'pistes',
      where: 'synced = ? AND downloaded = ?',
      whereArgs: [
        0,
        0
      ], // Créées par user, pas encore synchronisées
    );
  }

// Récupérer seulement les pistes téléchargées (autres users)
  Future<List<Map<String, dynamic>>> getDownloadedPistes() async {
    final db = await database;
    return await db.query(
      'pistes',
      where: 'synced = ? AND downloaded = ?',
      whereArgs: [
        0,
        1
      ], // Téléchargées, pas créées par cet user
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedPistes() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'pistes',
        where: 'synced = ? AND downloaded = ? AND login_id = ?',
        whereArgs: [
          0,
          0,
          ApiService.userId
        ],
        columns: [
          // ⭐⭐ SPÉCIFIEZ EXPLICITEMENT TOUTES LES COLONNES
          'id', 'code_piste', 'commune_rurale_id', 'user_login',
          'heure_debut', 'heure_fin', 'nom_origine_piste', 'x_origine',
          'y_origine', 'nom_destination_piste', 'x_destination', 'y_destination',
          'existence_intersection', 'x_intersection', 'y_intersection',
          'intersection_piste_code', 'type_occupation', 'debut_occupation',
          'fin_occupation', 'largeur_emprise', 'frequence_trafic', 'type_trafic',
          'travaux_realises', 'date_travaux', 'entreprise', 'points_json',
          'created_at', 'updated_at', 'login_id', 'synced', 'date_sync' // ⭐⭐ AJOUTEZ login_id ICI
        ],
      );

      // ⭐⭐ LOG POUR VÉRIFIER
      print('📊 Pistes non synchronisées trouvées: ${maps.length}');
      if (maps.isNotEmpty) {
        print('🔍 Premier piste - login_id: ${maps.first['login_id']}');
      }

      return maps;
    } catch (e) {
      print('❌ Erreur lecture pistes non synchronisées: $e');
      return [];
    }
  }

  Future<void> markPisteAsSynced(int pisteId) async {
    try {
      final db = await database;
      await db.update(
        'pistes',
        {
          'synced': 1,
          'downloaded': 0,
          'date_sync': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
        },
        where: 'id = ? AND login_id = ?',
        whereArgs: [
          pisteId,
          ApiService.userId
        ],
      );
      print('✅ Piste $pisteId marquée comme synchronisée');
    } catch (e) {
      print('❌ Erreur marquage piste synchronisée: $e');
    }
  }

  Future<int> getUnsyncedPistesCount() async {
    try {
      final db = await database;
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pistes WHERE synced = 0 AND downloaded = 0 AND login_id = ?', [
        ApiService.userId
      ]));
      return count ?? 0;
    } catch (e) {
      print('❌ Erreur comptage pistes non synchronisées: $e');
      return 0;
    }
  }

  // Ajouter cette méthode dans la classe SimpleStorageHelper
  Future<void> saveOrUpdatePiste(Map<String, dynamic> pisteData) async {
    try {
      final db = await database;
      final properties = pisteData['properties'];
      final geometry = pisteData['geometry'];

      // Extraire les coordonnées du MultiLineString GeoJSON
      final coordinates = geometry['coordinates'][0];
      final pointsJson = jsonEncode(coordinates
          .map((coord) => {
                'longitude': coord[0],
                'latitude': coord[1]
              })
          .toList());

      // Convertir les dates du format PostgreSQL
      String formatDate(String? dateString) {
        if (dateString == null) return '';
        return dateString.replaceFirst('T', ' ');
      }

      // Vérifier si la piste existe déjà (par id PostgreSQL)
      final existing = await db.query(
        'pistes',
        where: 'id = ?',
        whereArgs: [
          pisteData['id']
        ], // ID PostgreSQL
      );

      if (existing.isEmpty) {
        // Insertion nouvelle piste avec ID PostgreSQL
        await db.insert('pistes', {
          'id': pisteData['id'], // ← ID PostgreSQL devient ID SQLite
          'code_piste': properties['code_piste'],
          'commune_rurale_id': properties['communes_rurales_id']?.toString(),
          'user_login': properties['user_login'] ?? '',
          'heure_debut': properties['heure_debut'],
          'heure_fin': properties['heure_fin'],
          'nom_origine_piste': properties['nom_origine_piste'],
          'x_origine': properties['x_origine'],
          'y_origine': properties['y_origine'],
          'nom_destination_piste': properties['nom_destination_piste'],
          'x_destination': properties['x_destination'],
          'y_destination': properties['y_destination'],
          'existence_intersection': properties['existence_intersection'] ?? 0,
          'x_intersection': properties['x_intersection'],
          'y_intersection': properties['y_intersection'],
          'intersection_piste_code': properties['intersection_piste_code'],
          'type_occupation': properties['type_occupation'],
          'debut_occupation': formatDate(properties['debut_occupation']),
          'fin_occupation': formatDate(properties['fin_occupation']),
          'largeur_emprise': properties['largeur_emprise'],
          'frequence_trafic': properties['frequence_trafic'],
          'type_trafic': properties['type_trafic'],
          'travaux_realises': properties['travaux_realises'],
          'date_travaux': properties['date_travaux'],
          'entreprise': properties['entreprise'],
          'points_json': pointsJson,
          'created_at': formatDate(properties['created_at']),
          'updated_at': formatDate(properties['updated_at']),
          'login_id': properties['login_id'],
          'sync_status': 'downloaded',
          'synced': 0,
          'date_sync': DateTime.now().toIso8601String(),
          'downloaded': 1,
        });
        print('✅ Piste ${properties['code_piste']} sauvegardée (ID: ${pisteData['id']})');
      } else {
        // Mise à jour piste existante
        await db.update(
          'pistes',
          {
            'code_piste': properties['code_piste'],
            'commune_rurale_id': properties['communes_rurales_id']?.toString(),
            'heure_debut': properties['heure_debut'],
            'heure_fin': properties['heure_fin'],
            'nom_origine_piste': properties['nom_origine_piste'],
            'x_origine': properties['x_origine'],
            'y_origine': properties['y_origine'],
            'nom_destination_piste': properties['nom_destination_piste'],
            'x_destination': properties['x_destination'],
            'y_destination': properties['y_destination'],
            'existence_intersection': properties['existence_intersection'] ?? 0,
            'x_intersection': properties['x_intersection'],
            'y_intersection': properties['y_intersection'],
            'intersection_piste_code': properties['intersection_piste_code'],
            'type_occupation': properties['type_occupation'],
            'debut_occupation': formatDate(properties['debut_occupation']),
            'fin_occupation': formatDate(properties['fin_occupation']),
            'largeur_emprise': properties['largeur_emprise'],
            'frequence_trafic': properties['frequence_trafic'],
            'type_trafic': properties['type_trafic'],
            'travaux_realises': properties['travaux_realises'],
            'date_travaux': properties['date_travaux'],
            'entreprise': properties['entreprise'],
            'points_json': pointsJson,
            'updated_at': DateTime.now().toIso8601String(),
            'login_id': properties['login_id'],
            'sync_status': 'downloaded',
            'synced': 0,
            'date_sync': DateTime.now().toIso8601String(),
            'downloaded': 1,
          },
          where: 'id = ?',
          whereArgs: [
            pisteData['id']
          ],
        );
        print('🔄 Piste ${properties['code_piste']} mise à jour (ID: ${pisteData['id']})');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde piste: $e');
      print('📋 Données problématiques: ${jsonEncode(pisteData)}');
    }
  }

  // Dans SimpleStorageHelper class
  Future<List<Map<String, dynamic>>> getAllPistesMaps() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('pistes', orderBy: 'created_at DESC');
      return maps;
    } catch (e) {
      print('❌ Erreur lecture pistes: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllChausseesMaps() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('chaussees', orderBy: 'created_at DESC');
      return maps;
    } catch (e) {
      print('❌ Erreur lecture chaussées: $e');
      return [];
    }
  }

  Future<void> updatePiste(Map<String, dynamic> pisteData) async {
    try {
      final db = await database;

      // ✅ PRÉPARER UNIQUEMENT LES CHAMPS MODIFIABLES
      final updateData = {
        'code_piste': pisteData['code_piste'],
        'commune_rurale_id': pisteData['commune_rurale_id'],
        'user_login': pisteData['user_login'],
        'heure_debut': pisteData['heure_debut'],
        'heure_fin': pisteData['heure_fin'],
        'nom_origine_piste': pisteData['nom_origine_piste'],
        'x_origine': pisteData['x_origine'],
        'y_origine': pisteData['y_origine'],
        'nom_destination_piste': pisteData['nom_destination_piste'],
        'x_destination': pisteData['x_destination'],
        'y_destination': pisteData['y_destination'],
        'existence_intersection': pisteData['existence_intersection'],
        'x_intersection': pisteData['x_intersection'],
        'y_intersection': pisteData['y_intersection'],
        'intersection_piste_code': pisteData['intersection_piste_code'],
        'type_occupation': pisteData['type_occupation'],
        'debut_occupation': pisteData['debut_occupation'],
        'fin_occupation': pisteData['fin_occupation'],
        'largeur_emprise': pisteData['largeur_emprise'],
        'frequence_trafic': pisteData['frequence_trafic'],
        'type_trafic': pisteData['type_trafic'],
        'travaux_realises': pisteData['travaux_realises'],
        'date_travaux': pisteData['date_travaux'],
        'entreprise': pisteData['entreprise'],
        'points_json': jsonEncode(pisteData['points']), // ← CONVERTIR en JSON
        'updated_at': pisteData['updated_at'],
        'login_id': pisteData['login_id'],
      };

      // ✅ NE PAS METTRE À JOUR L'ID - juste l'utiliser pour WHERE
      await db.update(
        'pistes',
        updateData, // ← SEULEMENT les champs modifiables
        where: 'id = ?',
        whereArgs: [
          pisteData['id']
        ], // ← ID seulement pour WHERE
      );

      print('✅ Piste ${pisteData['id']} mise à jour avec succès');
    } catch (e) {
      print('❌ Erreur mise à jour piste: $e');
      rethrow;
    }
  }

  Future<void> deletePiste(int id) async {
    final db = await database;
    await db.delete(
      'pistes',
      where: 'id = ?',
      whereArgs: [
        id
      ],
    );
  }

  // Dans SimpleStorageHelper
  Future<List<Map<String, dynamic>>> getUnsyncedChaussees() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'chaussees',
        where: 'synced = ? AND downloaded = ? AND login_id = ?',
        whereArgs: [
          0,
          0,
          ApiService.userId
        ],
        columns: [
          // ⭐⭐ SPÉCIFIEZ EXPLICITEMENT LES COLONNES ⭐⭐
          'id',
          'code_piste',
          'code_gps',
          'user_login',
          'endroit',
          'type_chaussee',
          'etat_piste',
          'x_debut_chaussee',
          'y_debut_chaussee',
          'x_fin_chaussee',
          'y_fin_chaussee',
          'points_json',
          'distance_totale_m',
          'nombre_points',
          'created_at',
          'updated_at',
          'sync_status',
          'login_id',
          'synced',
          'date_sync'
          // ⭐⭐ NE INCLUEZ PAS downloaded ⭐⭐
        ],
      );

      print('📊 Chaussées non synchronisées trouvées: ${maps.length}');
      return maps;
    } catch (e) {
      print('❌ Erreur lecture chaussées non synchronisées: $e');
      return [];
    }
  }

  // Dans SimpleStorageHelper
  Future<void> markChausseeAsSynced(int chausseeId) async {
    try {
      final db = await database;
      await db.update(
        'chaussees',
        {
          'synced': 1,
          'downloaded': 0,
          'date_sync': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
        },
        where: 'id = ? AND login_id = ?',
        whereArgs: [
          chausseeId,
          ApiService.userId
        ],
      );
      print('✅ Chaussée $chausseeId marquée comme synchronisée');
    } catch (e) {
      print('❌ Erreur marquage chaussée synchronisée: $e');
    }
  }

  // Dans SimpleStorageHelper
  Future<int> getUnsyncedChausseesCount() async {
    try {
      final db = await database;
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM chaussees WHERE synced = 0 AND downloaded = 0 AND login_id = ?', [
        ApiService.userId
      ]));
      return count ?? 0;
    } catch (e) {
      print('❌ Erreur comptage chaussées non synchronisées: $e');
      return 0;
    }
  }

  Future<void> saveOrUpdateChausseeTest(Map<String, dynamic> chausseeData) async {
    try {
      final db = await database;
      final properties = chausseeData['properties'];
      final geometry = chausseeData['geometry'];

      // Extraire les coordonnées du MultiLineString GeoJSON
      final coordinates = geometry['coordinates'][0];
      final pointsJson = jsonEncode(coordinates
          .map((coord) => {
                'longitude': coord[0],
                'latitude': coord[1]
              })
          .toList());

      // Vérifier si la chaussée existe déjà (par id PostgreSQL)
      final existing = await db.query(
        'chaussees',
        where: 'id = ?',
        whereArgs: [
          chausseeData['id']
        ], // ID PostgreSQL
      );

      if (existing.isEmpty) {
        // Insertion nouvelle chaussée avec ID PostgreSQL
        await db.insert('chaussees', {
          'id': chausseeData['id'], // ← ID PostgreSQL
          'code_piste': properties['code_piste'],
          'code_gps': properties['code_gps'],
          'user_login': properties['login']?.toString() ?? 'Autre utilisateur',
          'endroit': properties['endroit'],
          'type_chaussee': properties['type_chaus'],
          'etat_piste': properties['etat_piste'],
          'x_debut_chaussee': properties['x_debut_ch'],
          'y_debut_chaussee': properties['y_debut_ch'],
          'x_fin_chaussee': properties['x_fin_ch'],
          'y_fin_chaussee': properties['y_fin_chau'],
          'points_json': pointsJson,
          'distance_totale_m': 0.0, // À calculer si nécessaire
          'nombre_points': coordinates.length,
          'created_at': properties['created_at'],
          'updated_at': properties['updated_at'],
          'sync_status': 'downloaded',
          'login_id': properties['login'],
          'synced': 0,
          'date_sync': DateTime.now().toIso8601String(),
          'downloaded': 1, // ← MARQUÉ COMME TÉLÉCHARGÉ
        });
        print('✅ Chaussée ${properties['code_piste']} téléchargée (ID: ${chausseeData['id']})');
      } else {
        // Mise à jour chaussée existante
        await db.update(
          'chaussees',
          {
            'code_piste': properties['code_piste'],
            'code_gps': properties['code_gps'],
            'user_login': properties['login']?.toString() ?? 'Autre utilisateur',
            'endroit': properties['endroit'],
            'type_chaussee': properties['type_chaus'],
            'etat_piste': properties['etat_piste'],
            'x_debut_chaussee': properties['x_debut_ch'],
            'y_debut_chaussee': properties['y_debut_ch'],
            'x_fin_chaussee': properties['x_fin_ch'],
            'y_fin_chaussee': properties['y_fin_chau'],
            'points_json': pointsJson,
            'updated_at': properties['updated_at'],
            'sync_status': 'downloaded',
            'downloaded': 1,
          },
          where: 'id = ?',
          whereArgs: [
            chausseeData['id']
          ],
        );
        print('🔄 Chaussée ${properties['code_piste']} mise à jour (ID: ${chausseeData['id']})');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde chaussée téléchargée: $e');
    }
  }

  // Dans piste_chaussee_db_helper.dart
  Future<void> deleteChaussee(int id) async {
    final db = await database;
    await db.delete(
      'chaussees',
      where: 'id = ?',
      whereArgs: [
        id
      ],
    );
  }
}
