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
  late final HomeController homeController;

  @override
  void initState() {
    super.initState();
// instanciation du controller
    homeController = HomeController();

    // écoute simple : quand le controller notifie -> setState pour redessiner
    homeController.addListener(() {
      setState(() {
        // on synchronise les états locaux si tu veux les garder pour d'autres usages
        userPosition = homeController.userPosition;
        gpsEnabled = homeController.gpsEnabled;
        lineActive = homeController.lineActive;
        linePaused = homeController.linePaused;
        linePoints = List<LatLng>.from(homeController.linePoints);
        // lineTotalDistance si tu l'utilises ailleurs
      });
    });

    // initialise (permission + position initiale + load data)
    homeController.initialize();
    collectedMarkers.addAll([
      Marker(
        markerId: const MarkerId('user'),
        position: userPosition,
        infoWindow: const InfoWindow(title: 'Vous êtes ici'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
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
    // vérification GPS locale (optionnelle) :
    if (!homeController.gpsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez activer le GPS")));
      return;
    }
    homeController.startLine();
    // plus besoin de setState() : la listener du controller s'en charge
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

    // ajouter la polyline dans ta collection locale pour l'affichage
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

    // la controller a déjà remis linePoints à [] et notifié.
  }

  void simulateAddPointToLine() {
    homeController.simulateAddPointToLine();
    // listener mettra à jour UI
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
              onPressed: simulateAddPointToLine,
              tooltip: "Ajouter un point à la ligne",
              child: Icon(Icons.add),
            )
          : null,
    );
  }
}
