import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatelessWidget {
  final LatLng userPosition;
  final bool gpsEnabled;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Function(GoogleMapController) onMapCreated;
  final Set<Marker> formMarkers;
  final MapType mapType;

  const MapWidget({
    super.key,
    required this.userPosition,
    required this.gpsEnabled,
    required this.markers,
    required this.polylines,
    required this.onMapCreated,
    required this.formMarkers,
    this.mapType = MapType.normal,
  });

  @override
  Widget build(BuildContext context) {
    // Fusionner tous les marqueurs
    final allMarkers = {
      ...markers,
      ...formMarkers
    };
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: userPosition, zoom: 15),
      markers: allMarkers,
      polylines: polylines,
      myLocationEnabled: gpsEnabled,
      myLocationButtonEnabled: true,
      compassEnabled: true,
      onMapCreated: (controller) => onMapCreated(controller),
      mapType: mapType,
    );
  }
}

class MapTypeToggle extends StatelessWidget {
  final MapType currentMapType;
  final Function(MapType) onMapTypeChanged;

  const MapTypeToggle({
    super.key,
    required this.currentMapType,
    required this.onMapTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSatellite = currentMapType == MapType.satellite;

    return Positioned(
      top: 110, // Ajustez selon la position de vos autres contrôles
      right: 10,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              // Basculer entre normal et satellite
              final newType = isSatellite ? MapType.normal : MapType.satellite;
              onMapTypeChanged(newType);
            },
            child: Container(
              padding: EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSatellite ? Icons.map : Icons.satellite,
                    size: 24,
                    color: isSatellite ? Colors.blue : Colors.orange,
                  ),
                  SizedBox(width: 8),
                  Text(
                    isSatellite ? 'Carte' : 'Satellite',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
