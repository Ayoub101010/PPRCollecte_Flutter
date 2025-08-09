import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'top_bar_widget.dart';
import 'map_widget.dart';
import 'map_controls_widget.dart';
import 'line_status_widget.dart';
import 'data_count_widget.dart';
import 'bottom_status_bar_widget.dart';
import 'bottom_buttons_widget.dart';

class HomePage extends StatefulWidget {
  final Function onLogout;
  const HomePage({Key? key, required this.onLogout}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  LatLng userPosition = LatLng(34.020882, -6.841650);
  bool gpsEnabled = true;

  bool lineActive = false;
  bool linePaused = false;
  List<LatLng> linePoints = [];

  List<Marker> collectedMarkers = [];
  List<Polyline> collectedPolylines = [];

  Completer<GoogleMapController> _controller = Completer();

  @override
  void initState() {
    super.initState();

    collectedMarkers.addAll([
      Marker(
        markerId: MarkerId('user'),
        position: userPosition,
        infoWindow: InfoWindow(title: 'Vous êtes ici'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: MarkerId('poi1'),
        position: LatLng(34.021, -6.841),
        infoWindow: InfoWindow(title: 'Point d\'intérêt 1', snippet: 'Infrastructure - Point'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    ]);

    collectedPolylines.add(Polyline(
      polylineId: PolylineId('piste1'),
      points: [
        LatLng(34.020, -6.840),
        LatLng(34.022, -6.842),
        LatLng(34.023, -6.843),
      ],
      color: Colors.blue.shade700,
      width: 3,
    ));
  }

  void addPointOfInterest() {
    final newPoint = LatLng(userPosition.latitude + 0.001, userPosition.longitude + 0.001);
    final markerId = 'poi${collectedMarkers.length + 1}';
    setState(() {
      collectedMarkers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: newPoint,
          infoWindow: InfoWindow(title: 'Nouveau point $markerId'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  void startLineCollection() {
    setState(() {
      lineActive = true;
      linePaused = false;
      linePoints = [
        userPosition
      ];
    });
  }

  void toggleLineCollection() {
    setState(() {
      linePaused = !linePaused;
    });
  }

  void finishLineCollection() {
    setState(() {
      if (linePoints.length > 1) {
        collectedPolylines.add(Polyline(
          polylineId: PolylineId('line${collectedPolylines.length + 1}'),
          points: List.from(linePoints),
          color: linePaused ? Colors.orange : Colors.green,
          width: 4,
          patterns: linePaused
              ? <PatternItem>[
                  PatternItem.dash(10),
                  PatternItem.gap(5)
                ]
              : <PatternItem>[],
        ));
      }
      lineActive = false;
      linePaused = false;
      linePoints = [];
    });
  }

  void simulateAddPointToLine() {
    if (lineActive && !linePaused) {
      setState(() {
        final last = linePoints.last;
        linePoints.add(LatLng(last.latitude + 0.0005, last.longitude + 0.0005));
      });
    }
  }

  void handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sauvegardé !')));
  }

  void handleSync() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Synchronisation lancée !')));
  }

  void handleMenuPress() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Menu ouvert')));
  }

  double _calculateDistance(List<LatLng> points) {
    double distance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      distance += _coordinateDistance(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return distance;
  }

  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - (cos((lat2 - lat1) * p) / 2) + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    final allPolylines = Set<Polyline>.from(collectedPolylines);
    if (lineActive && linePoints.length > 1) {
      allPolylines.add(Polyline(
        polylineId: PolylineId('currentLine'),
        points: linePoints,
        color: linePaused ? Colors.orange : Colors.green,
        width: 4,
        patterns: linePaused
            ? <PatternItem>[
                PatternItem.dash(10),
                PatternItem.gap(5)
              ]
            : <PatternItem>[],
      ));
    }

    return Scaffold(
      backgroundColor: Color(0xFFF0F8FF),
      body: SafeArea(
        child: Column(
          children: [
            TopBarWidget(onLogout: widget.onLogout),
            Expanded(
              child: Stack(
                children: [
                  MapWidget(
                    userPosition: userPosition,
                    gpsEnabled: gpsEnabled,
                    markers: Set<Marker>.from(collectedMarkers),
                    polylines: allPolylines,
                    onMapCreated: (controller) => _controller.complete(controller),
                  ),
                  MapControlsWidget(
                    lineActive: lineActive,
                    linePaused: linePaused,
                    addPointOfInterest: addPointOfInterest,
                    startLineCollection: startLineCollection,
                    toggleLineCollection: toggleLineCollection,
                    finishLineCollection: finishLineCollection,
                  ),
                  if (lineActive)
                    LineStatusWidget(
                      linePaused: linePaused,
                      linePointsCount: linePoints.length,
                      distance: _calculateDistance(linePoints),
                    ),
                  DataCountWidget(count: collectedMarkers.length + collectedPolylines.length),
                ],
              ),
            ),
            BottomStatusBarWidget(gpsEnabled: gpsEnabled),
            BottomButtonsWidget(
              onSave: handleSave,
              onSync: handleSync,
              onMenu: handleMenuPress,
            ),
          ],
        ),
      ),
      floatingActionButton: lineActive && !linePaused
          ? FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: simulateAddPointToLine,
              tooltip: "Ajouter un point à la ligne",
            )
          : null,
    );
  }
}
