import 'dart:async';
import 'package:location/location.dart';

class LocationService {
  final Location _location = Location();

  /// Demande service + permission et retourne true si tout OK.
  Future<bool> requestPermissionAndService() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }

    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted) return false;
    }

    return true;
  }

  Future<LocationData> getCurrent() => _location.getLocation();

  /// Stream de positions
  Stream<LocationData> onLocationChanged() => _location.onLocationChanged;
}
