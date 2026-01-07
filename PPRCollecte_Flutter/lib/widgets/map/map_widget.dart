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
      top: 55, // Ajustez selon la position de vos autres contrôles
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

class DownloadedPistesToggle extends StatelessWidget {
  final bool isOn;
  final int count; // optionnel: nombre de polylignes téléchargées
  final ValueChanged<bool> onChanged;

  const DownloadedPistesToggle({
    super.key,
    required this.isOn,
    required this.onChanged,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    // même placement que "Satellite", juste en dessous (ajuste top si besoin)
    return Positioned(
      top: 100, // 👈 sous le bouton Satellite (qui est à 110 chez toi)
      right: 10,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onChanged(!isOn),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.alt_route, // ou Icons.route
                    size: 22,
                    color: isOn ? const Color(0xFFB86E1D) : Colors.grey, // brun-orangé quand ON
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pistes téléchargées',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOn ? const Color(0xFFB86E1D).withOpacity(0.12) : Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOn ? const Color(0xFFB86E1D) : Colors.grey,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isOn ? const Color(0xFFB86E1D) : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DownloadedChausseesToggle extends StatelessWidget {
  final bool isOn;
  final int count;
  final ValueChanged<bool> onChanged;

  const DownloadedChausseesToggle({
    super.key,
    required this.isOn,
    required this.onChanged,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    // même placement que le bouton Pistes, juste en dessous
    return Positioned(
      top: 206, // 👈 ajusté pour être exactement sous le bouton Pistes (160 + hauteur du bouton ~46)
      right: 10,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
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
            onTap: () => onChanged(!isOn),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.alt_route_rounded,
                    size: 22,
                    color: isOn
                        ? const Color(0xFFB86E1D) // même brun-orangé que pistes
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Chaussées téléchargées',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOn ? const Color(0xFFB86E1D).withOpacity(0.12) : Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOn ? const Color(0xFFB86E1D) : Colors.grey,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isOn ? const Color(0xFFB86E1D) : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
