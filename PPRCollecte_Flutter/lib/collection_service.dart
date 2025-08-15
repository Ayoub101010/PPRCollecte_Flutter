import 'dart:async';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'collection_models.dart';

class CollectionService {
  Timer? _collectionTimer;
  final Duration _collectionInterval = const Duration(seconds: 20);

  StreamController<LatLng>? _locationController;
  Stream<LatLng>? _locationStream;

  // Configuration pour le filtrage GPS
  static const double _minimumAccuracy = 30.0; // mètres
  static const double _minimumDistance = 5.0; // mètres entre points successifs
  static const double _significantDistance =
      20.0; // distance pour ajouter un point

  /// Démarre la collecte automatique de points
  void startCollection({
    required CollectionBase collection,
    required Stream<LocationData> locationStream,
    required Function(LatLng point, double distance) onPointAdded,
  }) {
    stopCollection(); // Arrêter toute collecte précédente

    _locationController = StreamController<LatLng>.broadcast();
    _locationStream = _locationController!.stream;

    // Écouter les changements de position
    late StreamSubscription<LocationData> locationSubscription;
    locationSubscription = locationStream.listen((locationData) {
      if (collection.isActive) {
        _processLocationUpdate(
          locationData,
          collection,
          onPointAdded,
        );
      }
    });

    // Timer pour la collecte automatique toutes les 20 secondes
    _collectionTimer = Timer.periodic(_collectionInterval, (timer) {
      if (!collection.isActive) {
        timer.cancel();
        locationSubscription.cancel();
        return;
      }

      // La collecte se fait via le stream de location en continu
      // Le timer sert de backup et de contrôle de fréquence
    });
  }

  /// Traite une mise à jour de localisation
  void _processLocationUpdate(
    LocationData locationData,
    CollectionBase collection,
    Function(LatLng point, double distance) onPointAdded,
  ) {
    if (locationData.latitude == null || locationData.longitude == null) {
      return;
    }

    final lat = locationData.latitude!;
    final lon = locationData.longitude!;
    final accuracy = locationData.accuracy ?? 999.0;

    // Filtrer selon la précision
    if (accuracy > _minimumAccuracy) {
      return;
    }

    // Vérifier les coordonnées valides
    if (lat.abs() > 90 || lon.abs() > 180) {
      return;
    }

    final newPoint = LatLng(lat, lon);

    // Si c'est le premier point
    if (collection.points.isEmpty) {
      onPointAdded(newPoint, 0.0);
      return;
    }

    final lastPoint = collection.points.last;
    final distanceFromLast = _haversineDistance(
      lastPoint.latitude,
      lastPoint.longitude,
      lat,
      lon,
    );

    // Filtrer les points trop proches si la précision n'est pas excellente
    if (distanceFromLast < _minimumDistance && accuracy > 15) {
      return;
    }

    // Ajouter le point si la distance est significative
    if (distanceFromLast >= _significantDistance) {
      onPointAdded(newPoint, distanceFromLast);
    }
  }

  /// Arrête la collecte
  void stopCollection() {
    _collectionTimer?.cancel();
    _collectionTimer = null;
    _locationController?.close();
    _locationController = null;
    _locationStream = null;
  }

  /// Calcule la distance entre deux points en utilisant la formule de Haversine
  double _haversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000.0; // Rayon de la Terre en mètres

    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degToRad(double degrees) {
    return degrees * (pi / 180.0);
  }

  /// Calcule la distance totale d'une liste de points
  double calculateTotalDistance(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += _haversineDistance(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return totalDistance;
  }

  /// Valide qu'une collecte peut se terminer
  bool canFinishCollection(CollectionBase collection) {
    return collection.points.length >= 2;
  }

  /// Génère un ID unique pour une collecte
  String generateCollectionId(CollectionType type) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (Random().nextDouble() * 9999).round();
    final prefix = type == CollectionType.ligne ? 'LIGNE' : 'CHAUSSEE';
    return '${prefix}_${timestamp}_$random';
  }

  /// Dispose des ressources
  void dispose() {
    stopCollection();
  }
}
