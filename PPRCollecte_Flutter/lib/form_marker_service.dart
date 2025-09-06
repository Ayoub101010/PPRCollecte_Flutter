// lib/services/form_marker_service.dart
/*import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'database_helper.dart';

class FormMarkerService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // 1. Méthode pour récupérer UNIQUEMENT les données non synchronisées
  Future<List<Map<String, dynamic>>> _getUnsyncedPoints() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> unsyncedPoints = [];

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
          // ⭐⭐ MÉTHODE SÉCURISÉE - rawQuery au lieu de query ⭐⭐
          final points = await db.rawQuery('''
            SELECT * FROM $table 
            WHERE (synced = 0 OR synced IS NULL) 
            AND (downloaded = 0 OR downloaded IS NULL)
          ''');

          for (var point in points) {
            point['table_name'] = table;
            point['entity_type'] = _getEntityTypeFromTable(table);
            point.addAll(_getCoordinatesMapFromPoint(point));
            unsyncedPoints.add(point);
          }
        } catch (e) {
          print("⚠️ Erreur sur table $table: $e");
        }
      }

      return unsyncedPoints;
    } catch (e) {
      print('❌ Erreur récupération données: $e');
      return [];
    }
  }

  // 2. Convertir en marqueurs VIOLETS (non synchronisés)
  Future<Set<Marker>> getUnsyncedMarkers() async {
    try {
      final unsyncedPoints = await _getUnsyncedPoints();
      final markers = unsyncedPoints.map(_entityToMarker).toSet();

      print('📍 ${markers.length} marqueurs non synchronisés créés (VIOLETS)');
      return markers;
    } catch (e) {
      print('❌ Erreur création marqueurs non synchronisés: $e');
      return {};
    }
  }

  // 3. Méthode de conversion avec couleur VIOLETTE
  Marker _entityToMarker(Map<String, dynamic> entity) {
    final tableName = entity['table_name'];
    final entityType = entity['entity_type'];
    final lat = entity['lat'] as double;
    final lng = entity['lng'] as double;
    final id = entity['id'];
    final nom = entity['nom'] ?? 'Sans nom';

    return Marker(
      markerId: MarkerId('unsynced_${tableName}_$id'),
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(
        title: '$entityType: $nom',
        snippet: 'Non synchronisé | ID: $id',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
    );
  }

  // 4. Méthodes utilitaires que vous avez ajoutées
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
        'lng': point[mapping['lng']]
      };
    }

    return {
      'lat': 0,
      'lng': 0
    };
  }

  // 5. Méthode pour rafraîchir
  Future<Set<Marker>> refreshFormMarkers() async {
    return await getUnsyncedMarkers();
  }

  // 6. ⭐⭐ SUPPRIMEZ L'ANCIENNE MÉTHODE PROBLEMATIQUE ⭐⭐
  // Future<Set<Marker>> getAllFormMarkers() async {...} ← SUPPRIMEZ-LA !
} */
