// lib/home_controller.dart - Version mise à jour
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'location_service.dart';
import 'collection_models.dart';
import 'collection_manager.dart';

class HomeController extends ChangeNotifier {
  final LocationService _locationService;
  final CollectionManager _collectionManager = CollectionManager();

  // États exposés (existants)
  bool gpsEnabled = false;
  int? gpsAccuracy;
  String? lastSync;
  bool isOnline = true;
  LatLng userPosition = const LatLng(7.5, 10.5);

  // Anciens états ligne pour compatibilité (dépréciés)
  bool lineActive = false;
  bool linePaused = false;
  List<LatLng> linePoints = [];
  double lineTotalDistance = 0.0;

  StreamSubscription<LocationData>? _locationSub;

  HomeController({LocationService? locationService})
      : _locationService = locationService ?? LocationService() {
    // Écouter les changements du CollectionManager
    _collectionManager.addListener(_onCollectionChanged);
  }

  // Getters pour les nouvelles collectes
  LigneCollection? get ligneCollection => _collectionManager.ligneCollection;
  ChausseeCollection? get chausseeCollection =>
      _collectionManager.chausseeCollection;

  bool get hasActiveCollection => _collectionManager.hasActiveCollection;
  bool get hasPausedCollection => _collectionManager.hasPausedCollection;
  String? get activeCollectionType => _collectionManager.activeCollectionType;

  /// Appelé lorsque les collectes changent
  void _onCollectionChanged() {
    // Mettre à jour les anciens états pour compatibilité
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

  /// Appel depuis initState()
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
  }

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

  // === NOUVELLES MÉTHODES POUR LES COLLECTES ===

  /// Démarre une collecte de ligne/piste
  Future<void> startLigneCollection(
      String provisionalId, String provisionalName) async {
    if (!gpsEnabled) {
      throw Exception('Le GPS doit être activé pour commencer la collecte');
    }

    try {
      _collectionManager.startLigneCollection(
        provisionalName: provisionalName,
        initialPosition: userPosition,
        locationStream: _locationService.onLocationChanged(),
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Démarre une collecte de chaussée
  Future<void> startChausseeCollection(
      String provisionalId, String provisionalName) async {
    if (!gpsEnabled) {
      throw Exception('Le GPS doit être activé pour commencer la collecte');
    }

    try {
      _collectionManager.startChausseeCollection(
        provisionalName: provisionalName,
        initialPosition: userPosition,
        locationStream: _locationService.onLocationChanged(),
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Met en pause/reprend une collecte de ligne
  void toggleLigneCollection() {
    final ligne = _collectionManager.ligneCollection;
    if (ligne == null) return;

    if (ligne.isActive) {
      _collectionManager.pauseLigneCollection();
    } else if (ligne.isPaused) {
      try {
        _collectionManager
            .resumeLigneCollection(_locationService.onLocationChanged());
      } catch (e) {
        // Gérer l'erreur si une autre collecte est active
        rethrow;
      }
    }
  }

  /// Met en pause/reprend une collecte de chaussée
  void toggleChausseeCollection() {
    final chaussee = _collectionManager.chausseeCollection;
    if (chaussee == null) return;

    if (chaussee.isActive) {
      _collectionManager.pauseChausseeCollection();
    } else if (chaussee.isPaused) {
      try {
        _collectionManager
            .resumeChausseeCollection(_locationService.onLocationChanged());
      } catch (e) {
        // Gérer l'erreur si une autre collecte est active
        rethrow;
      }
    }
  }

  /// Termine une collecte de ligne
  Map<String, dynamic>? finishLigneCollection() {
    final result = _collectionManager.finishLigneCollection();
    if (result == null) return null;

    return {
      'points': result.points,
      'provisionalId': result.id,
      'provisionalName': result.provisionalName,
      'totalDistance': result.totalDistance,
      'startTime': result.startTime,
      'endTime': result.endTime,
    };
  }

  /// Termine une collecte de chaussée
  Map<String, dynamic>? finishChausseeCollection() {
    final result = _collectionManager.finishChausseeCollection();
    if (result == null) return null;

    return {
      'points': result.points,
      'provisionalId': result.id,
      'provisionalName': result.provisionalName,
      'totalDistance': result.totalDistance,
      'startTime': result.startTime,
      'endTime': result.endTime,
    };
  }

  /// Retourne le type de collecte active (pour les messages d'erreur)
  String? getActiveCollectionType() {
    return activeCollectionType;
  }

  // === MÉTHODES HÉRITÉES (pour compatibilité) ===

  /// @deprecated Utiliser startLigneCollection à la place
  void startLine() {
    lineActive = true;
    linePaused = false;
    linePoints = [userPosition];
    lineTotalDistance = 0.0;
    startLocationTracking();
    notifyListeners();
  }

  /// @deprecated Utiliser toggleLigneCollection à la place
  void toggleLine() {
    linePaused = !linePaused;
    if (linePaused) {
      stopLocationTracking();
    } else {
      startLocationTracking();
    }
    notifyListeners();
  }

  /// @deprecated Utiliser finishLigneCollection à la place
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

  /// Pour simulation/debug
  void simulateAddPointToLine() {
    if (lineActive && !linePaused) {
      final last = linePoints.isNotEmpty ? linePoints.last : userPosition;
      final newPt = LatLng(last.latitude + 0.0005, last.longitude + 0.0005);
      linePoints.add(newPt);
      lineTotalDistance += _haversineDistance(
          last.latitude, last.longitude, newPt.latitude, newPt.longitude);
      notifyListeners();
    }
  }

  /// Ajoute un point manuel pour debug
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

  double _deg2rad(double deg) => deg * (pi / 180.0);

  double _haversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
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
