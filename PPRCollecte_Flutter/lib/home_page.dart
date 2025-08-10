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
import 'home_controller.dart';
import 'point_form_screen.dart';

class HomePage extends StatefulWidget {
  final Function onLogout;
  const HomePage({super.key, required this.onLogout});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  LatLng userPosition = const LatLng(34.020882, -6.841650);
  bool gpsEnabled = true;

  bool lineActive = false;
  bool linePaused = false;
  List<LatLng> linePoints = [];

  List<Marker> collectedMarkers = [];
  List<Polyline> collectedPolylines = [];

  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _lastCameraPosition;
  late final HomeController homeController;

  @override
  void initState() {
    super.initState();
    homeController = HomeController();

    homeController.addListener(() {
      setState(() {
        userPosition = homeController.userPosition;
        gpsEnabled = homeController.gpsEnabled;
        lineActive = homeController.lineActive;
        linePaused = homeController.linePaused;
        linePoints = List<LatLng>.from(homeController.linePoints);
      });

      // déplace la caméra à la nouvelle position
      _moveCameraIfNeeded();
    });

    homeController.initialize();

    collectedMarkers.addAll([
      Marker(
        markerId: const MarkerId('poi1'),
        position: const LatLng(34.021, -6.841),
        infoWindow: const InfoWindow(title: 'Point d\'intérêt 1', snippet: 'Infrastructure - Point'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    ]);

    collectedPolylines.add(Polyline(
      polylineId: const PolylineId('piste1'),
      points: const [
        LatLng(34.020, -6.840),
        LatLng(34.022, -6.842),
        LatLng(34.023, -6.843),
      ],
      color: Colors.blue,
      width: 3,
    ));
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }

    // 📍 Centrer immédiatement si la position utilisateur est déjà connue
    if (userPosition.latitude != 34.020882 || userPosition.longitude != -6.841650) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: userPosition, zoom: 17),
        ),
      );
      _lastCameraPosition = userPosition;
    }
  }

  Future<void> _moveCameraIfNeeded() async {
    if (!_controller.isCompleted) return;
    try {
      final controller = await _controller.future;
      final shouldMove = _lastCameraPosition == null ||
          _coordinateDistance(
                _lastCameraPosition!.latitude,
                _lastCameraPosition!.longitude,
                userPosition.latitude,
                userPosition.longitude,
              ) >
              20;
      if (shouldMove) {
        await controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: userPosition, zoom: 17),
        ));
        _lastCameraPosition = userPosition;
      }
    } catch (_) {}
  }

  Future<void> addPointOfInterest() async {
    // Récupérer la position actuelle
    final current = homeController.userPosition;

    // Naviguer vers l'écran du formulaire et attendre le résultat
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PointFormScreen(
          pointData: {
            'latitude': current.latitude,
            'longitude': current.longitude,
            'accuracy': 10.0, // ou récupère la vraie précision
            'timestamp': DateTime.now().toIso8601String(),
          },
        ),
      ),
    );

    // Si on reçoit des données, on ajoute un marker sur la carte
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        collectedMarkers.add(
          Marker(
            markerId: MarkerId('poi${collectedMarkers.length + 1}'),
            position: LatLng(result['latitude'], result['longitude']),
            infoWindow: InfoWindow(title: result['nom'] ?? 'Nouveau point'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      });
    }
  }

  void startLineCollection() {
    if (!homeController.gpsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez activer le GPS")));
      return;
    }
    homeController.startLine();
  }

  void toggleLineCollection() {
    homeController.toggleLine();
  }

  void finishLineCollection() {
    final finished = homeController.finishLine();
    if (finished == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Une piste doit contenir au moins 2 points.")));
      return;
    }

    setState(() {
      collectedPolylines.add(Polyline(
        polylineId: PolylineId('line${collectedPolylines.length + 1}'),
        points: finished,
        color: linePaused ? Colors.orange : Colors.green,
        width: 4,
        patterns: linePaused
            ? <PatternItem>[
                PatternItem.dash(10),
                PatternItem.gap(5)
              ]
            : <PatternItem>[],
      ));
    });
  }

  void simulateAddPointToLine() {
    homeController.simulateAddPointToLine();
  }

  void handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sauvegardé !')));
  }

  void handleSync() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Synchronisation lancée !')));
  }

  void handleMenuPress() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu ouvert')));
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
  void dispose() {
    homeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Set<Marker> markersSet = Set<Marker>.from(collectedMarkers);
    markersSet.removeWhere((m) => m.markerId.value == 'user');
    markersSet.add(Marker(
      markerId: const MarkerId('user'),
      position: userPosition,
      infoWindow: const InfoWindow(title: 'Vous êtes ici'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ));

    final allPolylines = Set<Polyline>.from(collectedPolylines);
    if (lineActive && linePoints.length > 1) {
      allPolylines.add(Polyline(
        polylineId: const PolylineId('currentLine'),
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
      backgroundColor: const Color(0xFFF0F8FF),
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
                    markers: markersSet,
                    polylines: allPolylines,
                    onMapCreated: _onMapCreated,
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
              onPressed: simulateAddPointToLine,
              tooltip: "Ajouter un point à la ligne",
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
