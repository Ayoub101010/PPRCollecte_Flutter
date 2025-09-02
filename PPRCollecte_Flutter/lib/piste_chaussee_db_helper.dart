// lib/simple_storage_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'piste_model.dart';
import 'chaussee_model.dart';
import 'dart:convert'; // Pour jsonEncode/jsonDecode
import 'package:flutter/material.dart'; // Pour Color
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Pour LatLng et Polyline

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
            sync_status TEXT DEFAULT 'pending'
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
}
