// lib/services/form_marker_service.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'database_helper.dart';

class FormMarkerService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Convertir une entité de formulaire en marqueur
  Marker _entityToMarker(Map<String, dynamic> entity) {
    final tableName = entity['table_name'];
    final entityType = entity['entity_type'];
    final lat = entity['lat'] as double;
    final lng = entity['lng'] as double;
    final id = entity['id'];
    final nom = entity['nom'] ?? 'Sans nom';

    return Marker(
      markerId: MarkerId('form_${tableName}_$id'),
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(
        title: '$entityType: $nom',
        snippet: 'ID: $id | Table: $tableName',
      ),
      icon: _getMarkerIconForEntityType(entityType),
    );
  }

  // Obtenir l'icône appropriée selon le type d'entité
  BitmapDescriptor _getMarkerIconForEntityType(String entityType) {
    switch (entityType) {
      case 'Localité':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'École':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'Marché':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'Service de Santé':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'Bâtiment Administratif':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case 'Infrastructure Hydraulique':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case 'Pont':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case 'Bac':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
      case 'Point Critique':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
      case 'Point de Coupure':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  // Récupérer tous les formulaires et les convertir en marqueurs
  Future<Set<Marker>> getAllFormMarkers() async {
    try {
      final allPoints = await _dbHelper.getAllPoints();
      final markers = allPoints.map(_entityToMarker).toSet();

      print('📍 ${markers.length} marqueurs de formulaires chargés');
      return markers;
    } catch (e) {
      print('❌ Erreur lors du chargement des marqueurs: $e');
      return {};
    }
  }

  // Rafraîchir les marqueurs (pour mettre à jour après un nouvel enregistrement)
  Future<Set<Marker>> refreshFormMarkers() async {
    return await getAllFormMarkers();
  }
}
