// lib/home_controller.dart - Version complète et optimisée
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'location_service.dart';
import 'collection_models.dart';
import 'collection_manager.dart';
//import 'form_marker_service.dart';

class HomeController extends ChangeNotifier {
  final LocationService _locationService;
  final CollectionManager _collectionManager = CollectionManager();
//  final FormMarkerService _formMarkerService = FormMarkerService();

  // États exposés
  bool gpsEnabled = false;
  int? gpsAccuracy;
  String? lastSync;
  bool isOnline = true;
  LatLng userPosition = const LatLng(7.5, 10.5);
  Set<Marker> formMarkers = {}; // Marqueurs des formulaires enregistrés

  // Anciens états ligne pour compatibilité
  bool lineActive = false;
  bool linePaused = false;
  List<LatLng> linePoints = [];
  double lineTotalDistance = 0.0;

  StreamSubscription<LocationData>? _locationSub;

  HomeController({LocationService? locationService}) : _locationService = locationService ?? LocationService() {
    _collectionManager.addListener(_onCollectionChanged);
  }

  // Getters pour les nouvelles collectes
  LigneCollection? get ligneCollection => _collectionManager.ligneCollection;
  ChausseeCollection? get chausseeCollection => _collectionManager.chausseeCollection;
  bool get hasActiveCollection => _collectionManager.hasActiveCollection;
  bool get hasPausedCollection => _collectionManager.hasPausedCollection;
  String? get activeCollectionType => _collectionManager.activeCollectionType;

  /// Appelé lorsque les collectes changent
  void _onCollectionChanged() {
    final ligne = _collectionManager.ligneCollection;
    if (ligne != null) {
      lineActive = ligne.isActive;
      linePaused = ligne.isPaused;
      linePoints = List<LatLng>.from(ligne.points);
      lineTotalDistance = ligne.totalDistance;
    } else {
      lineActive = false;
      linePaused = false;
      linePoints = [];
      lineTotalDistance = 0.0;
    }
    notifyListeners();
  }

  /// Initialisation du contrôleur
  Future<void> initialize() async {
    try {
      final ok = await _locationService.requestPermissionAndService();
      if (!ok) {
        gpsEnabled = false;
        notifyListeners();
        return;
      }

      gpsEnabled = true;
      final loc = await _locationService.getCurrent();
      if (loc.latitude != null && loc.longitude != null) {
        userPosition = LatLng(loc.latitude!, loc.longitude!);
      }

      gpsAccuracy = loc.accuracy?.round();
      lastSync = _formatTimeNow();
      notifyListeners();
    } catch (e) {
      gpsEnabled = false;
      notifyListeners();
    }

    startLocationTracking();
    updateStatus();
    // loadFormMarkers(); // Charger les marqueurs au démarrage
  }

  /// Charge les marqueurs des formulaires enregistrés
  /*Future<void> loadFormMarkers() async {
    try {
      // ⭐⭐ UTILISEZ getUnsyncedMarkers() AU LIEU DE L'ANCIENNE MÉTHODE ⭐⭐
      final markers = await _formMarkerService.getUnsyncedMarkers();

      formMarkers = markers;
      print('✅ ${markers.length} marqueurs NON synchronisés chargés');
      notifyListeners();
    } catch (e) {
      print('❌ Erreur lors du chargement des marqueurs non synchronisés: $e');
    }
  }*/

  /// Rafraîchit les marqueurs après un nouvel enregistrement
  /*Future<void> refreshFormMarkers() async {
    try {
      final markers = await _formMarkerService.refreshFormMarkers();
      formMarkers = markers;
      notifyListeners();
      print('🔄 Marqueurs rafraîchis: ${markers.length} formulaires');
    } catch (e) {
      print('❌ Erreur lors du rafraîchissement des marqueurs: $e');
    }
  }*/

//  Une methode pour tester les  pistes dans l'emulateur à supprimer après
  void addRealisticPisteSimulation() async {
    // ← async ajouté ici
    if (!hasActiveCollection) return;

    final random = Random();
    final numberOfPoints = 100 + random.nextInt(100); // 100 à 200 points

    double currentLat = userPosition.latitude;
    double currentLng = userPosition.longitude;
    double angle = random.nextDouble() * 2 * pi;
    double curveIntensity = 0.08;

    for (int i = 0; i < numberOfPoints; i++) {
      // Distance entre points (15-25m)
      final distance = 0.00015 + (random.nextDouble() * 0.00005);

      // Courbure variable
      final curveVariation = (random.nextDouble() - 0.5) * curveIntensity;
      angle += curveVariation;

      // Déplacement avec angle
      currentLat += distance * cos(angle);
      currentLng += distance * sin(angle);

      // Ajout du point
      addManualPointToCollection(activeCollectionType == 'ligne' ? CollectionType.ligne : CollectionType.chaussee);

      // Délai progressif - MAINTENANT AVEC await
      await Future.delayed(Duration(milliseconds: 20 + random.nextInt(30)));
    }

    print('✅ $numberOfPoints points réalistes simulés');
    notifyListeners();
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000.0;
    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) + cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180.0);
  void startLocationTracking() {
    stopLocationTracking();
    _locationSub = _locationService.onLocationChanged().listen((loc) {
      if (loc.latitude == null || loc.longitude == null) return;

      final lat = loc.latitude!;
      final lon = loc.longitude!;
      if (lat.abs() > 90 || lon.abs() > 180) return;

      userPosition = LatLng(lat, lon);
      gpsAccuracy = loc.accuracy != null ? loc.accuracy!.round() : gpsAccuracy;
      lastSync = _formatTimeNow();
      notifyListeners();
    });
  }

  void stopLocationTracking() {
    _locationSub?.cancel();
    _locationSub = null;
  }

  // === MÉTHODES DE COLLECTE ===

  Future<void> startLigneCollection(String codePiste) async {
    if (!gpsEnabled) {
      throw Exception('Le GPS doit être activé pour commencer la collecte');
    }
    try {
      _collectionManager.startLigneCollection(
        codePiste: codePiste,
        initialPosition: userPosition,
        locationStream: _locationService.onLocationChanged(),
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> startChausseeCollection() async {
    if (!gpsEnabled) {
      throw Exception('Le GPS doit être activé pour commencer la collecte');
    }
    try {
      _collectionManager.startChausseeCollection(
        initialPosition: userPosition,
        locationStream: _locationService.onLocationChanged(),
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  void toggleLigneCollection() {
    final ligne = _collectionManager.ligneCollection;
    if (ligne == null) return;

    if (ligne.isActive) {
      _collectionManager.pauseLigneCollection();
    } else if (ligne.isPaused) {
      try {
        _collectionManager.resumeLigneCollection(_locationService.onLocationChanged());
      } catch (e) {
        rethrow;
      }
    }
  }

  void toggleChausseeCollection() {
    final chaussee = _collectionManager.chausseeCollection;
    if (chaussee == null) return;

    if (chaussee.isActive) {
      _collectionManager.pauseChausseeCollection();
    } else if (chaussee.isPaused) {
      try {
        _collectionManager.resumeChausseeCollection(_locationService.onLocationChanged());
      } catch (e) {
        rethrow;
      }
    }
  }

  Map<String, dynamic>? finishLigneCollection() {
    final result = _collectionManager.finishLigneCollection();
    if (result == null) return null;

    return {
      'points': result.points,
      'id': result.id,
      'codePiste': result.codePiste,
      'totalDistance': result.totalDistance,
      'startTime': result.startTime,
      'endTime': result.endTime,
    };
  }

  Map<String, dynamic>? finishChausseeCollection() {
    final result = _collectionManager.finishChausseeCollection();
    if (result == null) return null;

    return {
      'points': result.points,
      'id': result.id,
      'totalDistance': result.totalDistance,
      'startTime': result.startTime,
      'endTime': result.endTime,
    };
  }

  String? getActiveCollectionType() {
    return activeCollectionType;
  }

  // === MÉTHODES DE COMPATIBILITÉ (dépréciées) ===

  void startLine() {
    lineActive = true;
    linePaused = false;
    linePoints = [
      userPosition
    ];
    lineTotalDistance = 0.0;
    startLocationTracking();
    notifyListeners();
  }

  void toggleLine() {
    linePaused = !linePaused;
    if (linePaused) {
      stopLocationTracking();
    } else {
      startLocationTracking();
    }
    notifyListeners();
  }

  List<LatLng>? finishLine() {
    if (linePoints.length < 2) {
      return null;
    }
    final finished = List<LatLng>.from(linePoints);
    lineActive = false;
    linePaused = false;
    linePoints = [];
    lineTotalDistance = 0.0;
    stopLocationTracking();
    notifyListeners();
    return finished;
  }

  void simulateAddPointToLine() {
    if (lineActive && !linePaused) {
      final last = linePoints.isNotEmpty ? linePoints.last : userPosition;
      final newPt = LatLng(last.latitude + 0.0005, last.longitude + 0.0005);
      linePoints.add(newPt);
      lineTotalDistance += _haversineDistance(last.latitude, last.longitude, newPt.latitude, newPt.longitude);
      notifyListeners();
    }
  }

  void addManualPointToCollection(CollectionType type) {
    final offset = Random().nextDouble() * 0.001;
    final point = LatLng(
      userPosition.latitude + offset,
      userPosition.longitude + offset,
    );
    _collectionManager.addManualPoint(type, point);
  }

  // === MÉTHODES UTILITAIRES ===

  String _formatTimeNow() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  void updateStatus() {
    isOnline = Random().nextDouble() > 0.2;
    lastSync = _formatTimeNow();
    notifyListeners();
  }

  @override
  void dispose() {
    stopLocationTracking();
    _collectionManager.removeListener(_onCollectionChanged);
    _collectionManager.dispose();
    super.dispose();
  }
}
