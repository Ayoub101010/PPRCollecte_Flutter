import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatelessWidget {
  final LatLng userPosition;
  final bool gpsEnabled;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Function(GoogleMapController) onMapCreated;

  const MapWidget({
    super.key,
    required this.userPosition,
    required this.gpsEnabled,
    required this.markers,
    required this.polylines,
    required this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: userPosition, zoom: 15),
      markers: markers,
      polylines: polylines,
      myLocationEnabled: gpsEnabled,
      myLocationButtonEnabled: true,
      compassEnabled: true,
      onMapCreated: (controller) => onMapCreated(controller),
    );
  }
}
