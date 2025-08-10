// lib/home/home_controller.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'location_service.dart';

class HomeController extends ChangeNotifier {
  final LocationService _locationService;

  // états exposés
  bool gpsEnabled = false;
  int? gpsAccuracy;
  String? lastSync;
  bool isOnline = true;

  LatLng userPosition = const LatLng(7.5, 10.5);

  // ligne en cours
  bool lineActive = false;
  bool linePaused = false;
  List<LatLng> linePoints = [];
  double lineTotalDistance = 0.0;

  StreamSubscription<LocationData>? _locationSub;

  HomeController({LocationService? locationService}) : _locationService = locationService ?? LocationService();

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

    // Start a light tracking to keep the userPosition updated on the map (not the same as line collection)
    startLocationTracking();

    updateStatus();
  }

  void startLocationTracking() {
    // stop previous if any
    stopLocationTracking();
    _locationSub = _locationService.onLocationChanged().listen((loc) {
      if (loc.latitude == null || loc.longitude == null) return;

      // filtrer coordonnées impossibles ou mock importantes
      final lat = loc.latitude!;
      final lon = loc.longitude!;
      if (lat.abs() > 90 || lon.abs() > 180) return;

      userPosition = LatLng(lat, lon);
      gpsAccuracy = loc.accuracy != null ? loc.accuracy!.round() : gpsAccuracy;
      lastSync = _formatTimeNow();

      // si on est en collecte active, ajouter un point à la ligne
      if (lineActive && !linePaused) {
        _addPointToLineFromLocation(loc);
      }

      notifyListeners();
    });
  }

  void stopLocationTracking() {
    _locationSub?.cancel();
    _locationSub = null;
  }

  // --- API utilisée par l'UI ---
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

  /// Termine et retourne la liste de points si ok, sinon null
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

  // simulation (pour debug / bouton +)
  void simulateAddPointToLine() {
    if (lineActive && !linePaused) {
      final last = linePoints.isNotEmpty ? linePoints.last : userPosition;
      final newPt = LatLng(last.latitude + 0.0005, last.longitude + 0.0005);
      linePoints.add(newPt);
      lineTotalDistance += _haversineDistance(last.latitude, last.longitude, newPt.latitude, newPt.longitude);
      notifyListeners();
    }
  }

  // logique interne d'ajout de point depuis LocationData
  void _addPointToLineFromLocation(LocationData coords) {
    if (!lineActive || linePaused) return;

    final lat = coords.latitude!;
    final lon = coords.longitude!;
    final currentAccuracy = coords.accuracy ?? 999.0;

    if (currentAccuracy > 30) return;

    if (linePoints.isEmpty) {
      linePoints.add(LatLng(lat, lon));
      lineTotalDistance = 0.0;
      notifyListeners();
      return;
    }

    final last = linePoints.last;
    final distanceFromLast = _haversineDistance(last.latitude, last.longitude, lat, lon);

    if (distanceFromLast < 5 && currentAccuracy > 15) {
      return;
    }

    if (distanceFromLast >= 20) {
      linePoints.add(LatLng(lat, lon));
      lineTotalDistance += distanceFromLast;
      notifyListeners();
    }
  }

  // utilitaires
  String _formatTimeNow() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
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
    super.dispose();
  }
}
