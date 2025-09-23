import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'top_bar_widget.dart';
import 'map_widget.dart';
import 'map_controls_widget.dart';
import 'data_count_widget.dart';
import 'bottom_status_bar_widget.dart';
import 'bottom_buttons_widget.dart';
import 'home_controller.dart';
import 'Point_form_screen.dart';
import 'collection_exports.dart';
import 'sync_service.dart';
import 'dart:ui'; // Pour ImageFilter
import 'login_page.dart';
import 'data_categories_page.dart';
import 'package:flutter/foundation.dart'; // Pour kDebugMode
import 'piste_chaussee_db_helper.dart';
import 'database_helper.dart';
import 'api_service.dart';
import 'dart:convert'; // ⭐⭐ AJOUTEZ CET IMPORT ⭐⭐
import 'special_line_form_page.dart'; // ← AJOUTEZ CET IMPORT

class HomePage extends StatefulWidget {
  final Function onLogout;
  final String agentName;
  const HomePage({
    super.key,
    required this.onLogout,
    required this.agentName,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  LatLng userPosition = const LatLng(34.020882, -6.841650);
  bool gpsEnabled = true;

  List<Marker> collectedMarkers = [];
  List<Polyline> collectedPolylines = [];
  List<Polyline> _finishedPistes = []; // ← AJOUTEZ ICI
  List<Polyline> _finishedChaussees = [];
  Set<Marker> formMarkers = {};
  bool isSyncing = false;
  bool isDownloading = false;
  SyncResult? lastSyncResult;
  double _progressValue = 0.0;
  String _currentOperation = "Préparation de la sauvegarde...";
  int _totalItems = 0;
  int _processedItems = 0;
  double _syncProgressValue = 0.0;
  String _currentSyncOperation = "Préparation de la synchronisation...";
  int _syncTotalItems = 0;
  int _syncProcessedItems = 0;
  Set<Marker> _displayedPointsMarkers = {};
  String? _currentNearestPisteCode;
  bool _isSpecialCollection = false;
  String? _specialCollectionType;
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _lastCameraPosition;
  late final HomeController homeController;
  final DisplayedPointsService _pointsService = DisplayedPointsService();
  final SpecialLinesService _specialLinesService = SpecialLinesService();
  Set<Polyline> _displayedSpecialLines = {};
  final DownloadedPointsService _downloadedPointsService = DownloadedPointsService();
  Set<Marker> _downloadedPointsMarkers = {};
  bool _showDownloadedPoints = true;
  @override
  void initState() {
    super.initState();
    homeController = HomeController();
    //_cleanupDisplayedPoints();
    _loadDisplayedPistes();
    _loadDisplayedPoints();
    _loadDisplayedChaussees();
    _loadDisplayedSpecialLines();
    _loadDownloadedPoints();

    homeController.addListener(() {
      setState(() {
        userPosition = homeController.userPosition;
        gpsEnabled = homeController.gpsEnabled;
        formMarkers = homeController.formMarkers;
      });

      _moveCameraIfNeeded();
    });

    homeController.initialize();

    // Données de test initiales
    /* collectedMarkers.addAll([
      Marker(
        markerId: const MarkerId('poi1'),
        position: const LatLng(34.021, -6.841),
        infoWindow: const InfoWindow(title: 'Point d\'intérêt 1', snippet: 'Infrastructure - Point'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    ]);*/

    /* collectedPolylines.add(const Polyline(
      polylineId: PolylineId('piste1'),
      points: [
        LatLng(34.020, -6.840),
        LatLng(34.022, -6.842),
        LatLng(34.023, -6.843),
      ],
      color: Colors.blue,
      width: 3,
    ));*/
  }

  Future<void> _refreshAllPoints() async {
    print('🔄 Rafraîchissement de tous les points...');
    await _loadDisplayedPoints(); // Points locaux (rouges)
    await _loadDownloadedPoints(); // Points téléchargés (verts)
  }

  Future<void> _loadDownloadedPoints() async {
    try {
      final markers = await _downloadedPointsService.getDownloadedPointsMarkers();
      setState(() {
        _downloadedPointsMarkers = markers;
      });
      print('✅ ${markers.length} points téléchargés chargés (verts)');
    } catch (e) {
      print('❌ Erreur chargement points téléchargés: $e');
    }
  }

// Dans _HomePageState (home_page.dart)
// ⭐⭐ AJOUTER CETTE MÉTHODE SEULEMENT ⭐⭐
  Future<void> _refreshAfterNavigation() async {
    print('🔄 Rafraîchissement après navigation...');
    await _loadDisplayedSpecialLines();
    await _refreshAllPoints(); // Seulement les lignes spéciales
  }

  Future<void> _loadDisplayedSpecialLines() async {
    try {
      await DatabaseHelper().debugDisplayedSpecialLines();
      print('🟣 Début chargement lignes spéciales...');
      final specialLines = await _specialLinesService.getDisplayedSpecialLines();
      await Future.delayed(const Duration(milliseconds: 100));
      print('🟣 Lignes récupérées: ${specialLines.length}');
      for (var line in specialLines) {
        print('  - ${line.polylineId.value} : ${line.points.length} points');
      }

      setState(() {
        _displayedSpecialLines = specialLines;
      });
      print('✅ ${specialLines.length} lignes spéciales chargées');
    } catch (e) {
      print('❌ Erreur chargement lignes spéciales: $e');
    }
  }

// Dans _HomePageState
  // Remplacer startSpecialLineCollection par :
  Future<void> startSpecialCollection(String type) async {
    if (!homeController.gpsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez activer le GPS")),
      );
      return;
    }

    if (homeController.hasActiveCollection) {
      final activeType = homeController.activeCollectionType;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez mettre en pause la collecte de $activeType en cours'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await homeController.startSpecialCollection(type);

      setState(() {
        _isSpecialCollection = true;
        _specialCollectionType = type;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Collecte de $type démarrée'),
          backgroundColor: Colors.purple, // Couleur différente
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Remplacer finishSpecialLigneCollection par :
  Future<void> finishSpecialCollection() async {
    final result = homeController.finishSpecialCollection();

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Une ligne doit contenir au moins 2 points.")),
      );
      return;
    }

    // ⭐⭐ AJOUTEZ CES LIGNES DE DEBUG ⭐⭐
    print('=== DEBUG FINISH SPECIAL ===');
    print('Result codePiste: ${result.codePiste}');
    print('HomeController activePisteCode: ${homeController.activePisteCode}');
    print('Special type: $_specialCollectionType');
    final current = homeController.userPosition;
    final nearestPisteCode = await SimpleStorageHelper().findNearestPisteCode(current, activePisteCode: homeController.activePisteCode // ← MÊME APPEL
        );

    print('📍 Code piste pour spécial: $nearestPisteCode');

    final formResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SpecialLineFormPage(
          linePoints: result.points,
          provisionalCode: result.codePiste ?? '',
          startTime: result.startTime,
          endTime: result.endTime,
          agentName: widget.agentName,
          specialType: _specialCollectionType!,
          totalDistance: result.totalDistance,
          activePisteCode: homeController.activePisteCode, // ⭐⭐ AJOUTEZ CETTE LIGNE ⭐⭐
        ),
      ),
    );
    if (mounted) {
      _refreshAfterNavigation();
    }
    setState(() {
      _isSpecialCollection = false;
      _specialCollectionType = null;
    });

    if (formResult != null) {
      final specialColor = _specialCollectionType == "Bac" ? Colors.purple : Colors.deepPurple;

      // ⭐⭐ AJOUTEZ DU DEBUG POUR LE TRACAGE ⭐⭐
      print('🎨 Tracing special line: ${result.points.length} points');
      print('🎨 Color: $specialColor');

      setState(() {
        _finishedPistes.add(Polyline(
          polylineId: PolylineId('special_${DateTime.now().millisecondsSinceEpoch}'),
          points: result.points,
          color: specialColor,
          width: 6, // ← Augmentez pour mieux voir
          patterns: [
            PatternItem.dash(10),
            PatternItem.gap(5)
          ], // ← Motif distinctif
        ));
      });

      final storageHelper = SimpleStorageHelper();
      await storageHelper.saveDisplayedPiste(result.points, specialColor, 4.0);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Données enregistrées avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _loadDisplayedChaussees() async {
    try {
      final storageHelper = SimpleStorageHelper();

      // ⭐⭐ SUPPRIMER CETTE LIGNE INUTILE ⭐⭐
      // final db = await storageHelper.database;

      // ⭐⭐ 2. FILTRER UNIQUEMENT LES CHAUSSÉES DE L'UTILISATEUR COURANT ⭐⭐
      final allChaussees = await storageHelper.getAllChausseesMaps();
      final userChaussees = allChaussees.where((ch) => ch['login_id'] == ApiService.userId).toList();

      print('📊 Chaussées trouvées: ${allChaussees.length}, Chaussées utilisateur: ${userChaussees.length}');

      for (final chaussee in userChaussees) {
        try {
          final pointsJson = chaussee['points_json'] as String;
          final pointsData = jsonDecode(pointsJson) as List;
          final points = pointsData.map((p) => LatLng((p['latitude'] ?? p['lat']) as double, (p['longitude'] ?? p['lng']) as double)).toList();

          // ⭐⭐ 3. UTILISER LA NOUVELLE MÉTHODE QUI NE SUPPRIME PAS ⭐⭐
          await storageHelper.saveDisplayedChaussee(points, const Color(0xFFFF9800), 4.0, chaussee['code_piste'] ?? 'Sans_code', chaussee['endroit'] ?? 'Sans_endroit');
        } catch (e) {
          print('❌ Erreur recréation chaussée ${chaussee['id']}: $e');
        }
      }

      // ⭐⭐ 4. CHARGER LES CHAUSSÉES FILTRÉES ⭐⭐
      final displayedChaussees = await storageHelper.loadDisplayedChaussees();

      setState(() {
        _finishedChaussees = displayedChaussees;
      });

      print('✅ ${displayedChaussees.length} chaussées rechargées pour user: ${ApiService.userId}');
    } catch (e) {
      print('❌ Erreur rechargement chaussées: $e');
    }
  }

  Future<String> generateCodePiste() async {
    final now = DateTime.now();

    // Format timestamp avec millisecondes
    final timestamp = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}'
        '${now.millisecond.toString().padLeft(3, '0')}';

    String communeNom;
    String prefectureNom;
    String regionNom;

    // Essayer d'abord depuis ApiService (en ligne)
    if (ApiService.communeNom != null && ApiService.prefectureNom != null && ApiService.regionNom != null) {
      communeNom = ApiService.communeNom!;
      prefectureNom = ApiService.prefectureNom!;
      regionNom = ApiService.regionNom!;

      print('📍 Localisation récupérée depuis API');
    } else {
      // Sinon, récupérer depuis la base locale (hors ligne)
      final currentUser = await DatabaseHelper().getCurrentUser();

      if (currentUser != null) {
        communeNom = currentUser['commune_nom'] ?? 'Inconnu';
        prefectureNom = currentUser['prefecture_nom'] ?? 'Inconnu';
        regionNom = currentUser['region_nom'] ?? 'Inconnu';
        print('📍 Localisation récupérée depuis base locale');
      } else {
        communeNom = 'Inconnu';
        prefectureNom = 'Inconnu';
        regionNom = 'Inconnu';
        print('⚠️ Localisation inconnue');
      }
    }

    // Nettoyer les noms
    String cleanName(String name) {
      return name.replaceAll(' ', '_').replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '').toUpperCase();
    }

    final code = 'Piste_'
        '${cleanName(communeNom)}_'
        '${cleanName(prefectureNom)}_'
        '${cleanName(regionNom)}_'
        '$timestamp';

    print('🆔 Code piste généré: $code');
    return code;
  }

// AJOUTEZ CETTE MÉTHODE DANS _HomePageState
  /*void _setupRefreshListener() {
    // Rafraîchir périodiquement toutes les 2 secondes
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _loadDisplayedPoints();
        print('🔄 Rafraîchissement automatique des points');
      }
    });
  }*/

  Future<void> _loadDisplayedPoints() async {
    // AJOUTEZ CE DEBUG pour voir QUI appelle
    print('🛑 _loadDisplayedPoints appelée par:');
    print(StackTrace.current.toString().split('\n').take(3).join('\n'));
    print('---');

    try {
      final markers = await _pointsService.getDisplayedPointsMarkers();
      // ⭐⭐ FILTRER SEULEMENT LES MARQUEURS VALIDES ⭐⭐
      final dbHelper = DatabaseHelper();
      final existingPoints = await dbHelper.loadDisplayedPoints();
      final existingIds = existingPoints.map((p) => p['id'] as int).toSet();

      final validMarkers = markers.where((marker) {
        final markerId = int.tryParse(marker.markerId.value.replaceFirst('displayed_point_', ''));
        return markerId != null && existingIds.contains(markerId);
      }).toSet();
      setState(() {
        _displayedPointsMarkers = validMarkers;
      });
      print('📍 ${validMarkers.length} points affichés valides');
    } catch (e) {
      print('❌ Erreur chargement points: $e');
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }

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

  // === GESTION DES POINTS D'INTÉRÊT ===
  Future<void> addPointOfInterest() async {
    if (_isSpecialCollection) {
      // Utiliser la nouvelle méthode
      await finishSpecialCollection(); // ← CHANGER ICI
      return;
    }

    // Vérifier si une collecte est active
    final activeType = homeController.getActiveCollectionType();
    if (activeType != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez mettre en pause la collecte de $activeType en cours'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final current = homeController.userPosition;
    final nearestPisteCode = await SimpleStorageHelper().findNearestPisteCode(current, activePisteCode: homeController.activePisteCode);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PointFormScreen(
          pointData: {
            'latitude': current.latitude,
            'longitude': current.longitude,
            'accuracy': 10.0,
            'timestamp': DateTime.now().toIso8601String(),
          },
          agentName: widget.agentName,
          nearestPisteCode: nearestPisteCode,
          onSpecialTypeSelected: (type) {
            // Utiliser la nouvelle méthode
            startSpecialCollection(type); // ← CHANGER ICI
          },
        ),
      ),
    );
    if (mounted) {
      _refreshAfterNavigation(); // Rafraîchir après être revenu
    }
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

  // === GESTION DE LA COLLECTE LIGNE/PISTE ===
  // home_page.dart - Modifiez la méthode startLigneCollection

// home_page.dart - Méthode startLigneCollection modifiée

  Future<void> startLigneCollection() async {
    if (!homeController.gpsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez activer le GPS")),
      );
      return;
    }

    if (homeController.hasActiveCollection) {
      final activeType = homeController.activeCollectionType;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez mettre en pause la collecte de $activeType en cours'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ⭐⭐ GÉNÉRER le code piste automatiquement - AJOUTER AWAIT
    final codePisteAuto = await generateCodePiste(); // ← AJOUTER AWAIT

    // ⭐⭐ Afficher le dialogue AVEC code pré-rempli et IMMODIFIABLE
    final provisionalData = await ProvisionalFormDialog.show(
      context: context,
      initialCode: codePisteAuto, // ← Maintenant ça fonctionne
    );

    // ⭐⭐ Plus besoin de vérifier si null, car le code est toujours fourni
    if (provisionalData == null) return;

    try {
      await homeController.startLigneCollection(
        provisionalData['code_piste']!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collecte de piste démarrée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void toggleLigneCollection() {
    try {
      homeController.toggleLigneCollection();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> finishLigneCollection() async {
    final result = homeController.finishLigneCollection();
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Une piste doit contenir au moins 2 points.")),
      );
      return;
    }

    // Ouvrir le formulaire principal avec les données provisoires
    final formResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormulaireLignePage(
          linePoints: result['points'],
          provisionalCode: result['codePiste'], // ✅ Nom correct du paramètre
          startTime: result['startTime'],
          endTime: result['endTime'],
          agentName: widget.agentName,
        ),
      ),
    );

    if (formResult != null) {
      setState(() {
        // ✅ AJOUTEZ LA PISTE TERMINÉE (NOUVEAU)
        _finishedPistes.add(Polyline(
          polylineId: PolylineId('piste_${DateTime.now().millisecondsSinceEpoch}'),
          points: result['points'],
          color: Colors.blue,
          width: 4,
        ));
      });
      final storageHelper = SimpleStorageHelper();
      await storageHelper.saveDisplayedPiste(result['points'], Colors.blue, 4.0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Piste enregistrée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

// Pour charger au démarrage
  // Dans la classe _HomePageState
// Remplacer l'ancienne méthode par la nouvelle
  Future<void> _loadDisplayedPistes() async {
    try {
      final storageHelper = SimpleStorageHelper();

      // ⭐⭐ SUPPRIMER CETTE LIGNE INUTILE ⭐⭐
      // final db = await storageHelper.database;

      // ⭐⭐ 2. FILTRER UNIQUEMENT LES PISTES DE L'UTILISATEUR COURANT ⭐⭐
      final allPistes = await storageHelper.getAllPistesMaps();
      final userPistes = allPistes.where((piste) => piste['login_id'] == ApiService.userId).toList();

      print('📊 Pistes trouvées: ${allPistes.length}, Pistes utilisateur: ${userPistes.length}');

      for (final piste in userPistes) {
        try {
          final pointsJson = piste['points_json'] as String;
          final pointsData = jsonDecode(pointsJson) as List;
          final points = pointsData.map((p) => LatLng((p['latitude'] ?? p['lat']) as double, (p['longitude'] ?? p['lng']) as double)).toList();

          // ⭐⭐ 3. UTILISER LA NOUVELLE MÉTHODE QUI NE SUPPRIME PAS ⭐⭐
          await storageHelper.saveDisplayedPiste(points, Colors.blue, 4.0);
        } catch (e) {
          print('❌ Erreur recréation piste ${piste['id']}: $e');
        }
      }

      // ⭐⭐ 4. CHARGER LES PISTES FILTRÉES ⭐⭐
      final displayedPistes = await storageHelper.loadDisplayedPistes();

      setState(() {
        _finishedPistes = displayedPistes;
      });

      print('✅ ${displayedPistes.length} pistes rechargées pour user: ${ApiService.userId}');
    } catch (e) {
      print('❌ Erreur rechargement pistes: $e');
    }
  }

  // === GESTION DE LA COLLECTE CHAUSSÉE ===
  Future<void> startChausseeCollection() async {
    if (!homeController.gpsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez activer le GPS")),
      );
      return;
    }

    // Vérifier si une collecte est active
    if (homeController.hasActiveCollection) {
      final activeType = homeController.activeCollectionType;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez mettre en pause la collecte de $activeType en cours'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // ⭐⭐ TROUVER LE CODE PISTE LE PLUS PROCHE ⭐⭐
      _currentNearestPisteCode = homeController.activePisteCode ?? await SimpleStorageHelper().findNearestPisteCode(homeController.userPosition);
      await homeController.startChausseeCollection(); // ✅ Aucun paramètre requis

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collecte de chaussée démarrée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void toggleChausseeCollection() {
    try {
      homeController.toggleChausseeCollection();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> finishChausseeCollection() async {
    final result = homeController.finishChausseeCollection();
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Une chaussée doit contenir au moins 2 points.")),
      );
      return;
    }

    // Ouvrir le formulaire principal avec les données provisoires
    final formResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormulaireChausseePage(
          chausseePoints: result['points'],
          provisionalId: result['id'],
          agentName: widget.agentName,
          nearestPisteCode: _currentNearestPisteCode, // ✅ Utiliser l'ID correct
        ),
      ),
    );

    if (formResult != null) {
      setState(() {
        collectedPolylines.add(Polyline(
          polylineId: PolylineId('chaussee_${collectedPolylines.length + 1}'),
          points: result['points'],
          color: const Color(0xFFFF9800),
          width: 4,
        ));
      });
      final storageHelper = SimpleStorageHelper();
      await storageHelper.saveDisplayedChaussee(
          result['points'],
          const Color(0xFFFF9800),
          4.0,
          formResult['code_piste'] ?? 'Sans_code', // ← Code piste
          formResult['endroit'] ?? 'Sans_endroit' // ← Endroit
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chaussée enregistrée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showSyncConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation de synchronisation'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir synchroniser vos données locales vers le serveur ?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performSync();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Oui', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSyncResult(SyncResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Synchronisation terminée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ ${result.successCount} succès'),
            Text('❌ ${result.failedCount} échecs'),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Détails des erreurs:'),
              const SizedBox(height: 5),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: result.errors.length,
                  itemBuilder: (ctx, i) => Text(
                    '• ${result.errors[i]}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSaveConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation de sauvegarde'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir télécharger toutes les données depuis le serveur ?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performDownload();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Oui', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDownloadResult(SyncResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sauvegarde terminée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📥 ${result.successCount} données sauvegardées'),
            if (result.failedCount > 0) Text('❌ ${result.failedCount} données non sauvegardées'),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Détails des erreurs:'),
              const SizedBox(height: 5),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: result.errors.length,
                  itemBuilder: (ctx, i) => Text(
                    '• ${result.errors[i]}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void handleSync() {
    if (isSyncing) return;

    _performSync(); // Appeler la méthode async séparément
  }

  // AJOUTEZ cette méthode
  void handleSave() {
    if (isDownloading) return;
    _performDownload(); // Appeler la méthode async séparément
  }

// AJOUTEZ cette méthode
  Future<void> _performDownload() async {
    setState(() {
      isDownloading = true;
      _progressValue = 0.0;
      _processedItems = 0;
      _totalItems = 1; // Valeur initiale
    });

    try {
      final result = await SyncService().downloadAllData(onProgress: (progress, currentOperation, processed, total) {
        setState(() {
          _progressValue = progress;
          _currentOperation = currentOperation;
          _processedItems = processed;
          _totalItems = total;
        });
      });
      setState(() => lastSyncResult = result);
      _showDownloadResult(result); // Réutilisez la même méthode d'affichage

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sauvegarde terminée: ${result.successCount} données'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur sauvegarde: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isDownloading = false);
    }
  }

  void handleMenuPress() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DataCategoriesPage()),
    ).then((_) {
      _refreshAllPoints();
      // ⭐⭐ RAFRAÎCHIR TOUJOURS À LE RETOUR ⭐⭐
      _loadDisplayedPoints();
      _loadDisplayedPistes();
      _loadDisplayedChaussees();
    });
  }

// Ajoutez cette méthode pour afficher la confirmation de déconnexion
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation de déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Fermer la boîte de dialogue
              _performLogout(); // Effectuer la déconnexion
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Oui', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

// Ajoutez cette méthode pour effectuer la déconnexion
  void _performLogout() {
    homeController.clearActivePisteCode();
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  // Méthode AVEC Future pour la logique async
  // Remplacer la méthode _performSync() par :
  Future<void> _performSync() async {
    setState(() {
      isSyncing = true;
      _syncProgressValue = 0.0;
      _syncProcessedItems = 0;
      _syncTotalItems = 1;
    });

    try {
      final result = await SyncService().syncAllDataSequential(
        onProgress: (progress, currentOperation, processed, total) {
          double safeProgress = progress.isNaN || progress.isInfinite ? 0.0 : progress.clamp(0.0, 1.0);
          int safeProcessed = processed.isNaN || processed.isInfinite ? 0 : processed;
          int safeTotal = total.isNaN || total.isInfinite ? 1 : total;

          setState(() {
            _syncProgressValue = safeProgress;
            _currentSyncOperation = currentOperation;
            _syncProcessedItems = safeProcessed;
            _syncTotalItems = safeTotal;
          });
        },
      );

      setState(() => lastSyncResult = result);
      setState(() => isSyncing = false);
      _showSyncResult(result);
    } catch (e) {
      setState(() => isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
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

  Widget _buildStepIndicator() {
    String currentStep = "Pistes";
    if (_currentSyncOperation.contains("chaussée") || _currentSyncOperation.contains("chaussee")) {
      currentStep = "Chaussées";
    } else if (_currentSyncOperation.contains("localité") || _currentSyncOperation.contains("école")) {
      currentStep = "Points d'intérêt";
    }

    return Row(
      children: [
        Icon(Icons.check_circle, color: currentStep == "Pistes" ? Colors.grey : Colors.green, size: 16),
        SizedBox(width: 4),
        Text('Pistes', style: TextStyle(color: currentStep == "Pistes" ? Colors.orange : Colors.green, fontWeight: currentStep == "Pistes" ? FontWeight.bold : FontWeight.normal)),
        SizedBox(width: 12),
        Icon(Icons.check_circle,
            color: currentStep == "Chaussées"
                ? Colors.grey
                : currentStep == "Pistes"
                    ? Colors.grey
                    : Colors.green,
            size: 16),
        SizedBox(width: 4),
        Text('Chaussées',
            style: TextStyle(
                color: currentStep == "Chaussées"
                    ? Colors.orange
                    : currentStep == "Pistes"
                        ? Colors.grey
                        : Colors.green,
                fontWeight: currentStep == "Chaussées" ? FontWeight.bold : FontWeight.normal)),
        SizedBox(width: 12),
        Icon(Icons.check_circle, color: currentStep == "Points d'intérêt" ? Colors.grey : Colors.green, size: 16),
        SizedBox(width: 4),
        Text('Points', style: TextStyle(color: currentStep == "Points d'intérêt" ? Colors.orange : Colors.grey, fontWeight: currentStep == "Points d'intérêt" ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

// Ajoutez cette méthode
  Widget _buildSyncProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[100]!),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10)
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.cloud_upload, color: Colors.orange),
            SizedBox(width: 10),
            Text('Synchronisation en cours', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          SizedBox(height: 12),
          LinearProgressIndicator(
            value: _syncProgressValue,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(_syncProgressValue * 100).toStringAsFixed(0)}%'),
              Text('$_syncProcessedItems/$_syncTotalItems'),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _currentSyncOperation,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          // Ajouter des indicateurs d'étapes
          _buildStepIndicator(),
        ],
      ),
    );
  }

// Ajoutez cette méthode pour afficher la progression
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100], // Même couleur que la boîte "Sauvegarde terminée"
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!), // Bordure bleue claire
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cloud_download, color: Colors.blue),
              SizedBox(width: 10),
              Text(
                'Sauvegarde en cours',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _progressValue,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(_progressValue * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                '$_processedItems/$_totalItems',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentOperation,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Préparer les markers
    final Set<Marker> markersSet = Set<Marker>.from(_displayedPointsMarkers);
    if (_showDownloadedPoints) {
      markersSet.addAll(_downloadedPointsMarkers); // Verts (téléchargés)
    }
    // Préparer les polylines
    final allPolylines = Set<Polyline>.from(collectedPolylines);
    allPolylines.addAll(_finishedPistes);
    allPolylines.addAll(_finishedChaussees); // ← CORRECTION SIMPLE
    allPolylines.addAll(_displayedSpecialLines);
    // Ajouter la ligne en cours si active (nouveau système)
    if (homeController.specialCollection != null) {
      final specialPoints = homeController.specialCollection!.points;
      if (specialPoints.length > 1) {
        final specialColor = _specialCollectionType == "Bac" ? Colors.purple : Colors.deepPurple;

        allPolylines.add(Polyline(
          polylineId: const PolylineId('currentSpecial'),
          points: specialPoints,
          color: specialColor,
          width: 5,
          patterns: homeController.specialCollection!.isPaused
              ? <PatternItem>[
                  PatternItem.dash(10),
                  PatternItem.gap(5)
                ]
              : <PatternItem>[],
        ));
      }
    }
    if (homeController.ligneCollection != null) {
      final lignePoints = homeController.ligneCollection!.points;
      if (lignePoints.length > 1) {
        allPolylines.add(Polyline(
          polylineId: const PolylineId('currentLigne'),
          points: lignePoints,
          color: homeController.ligneCollection!.isPaused ? Colors.orange : Colors.green,
          width: 4,
          patterns: homeController.ligneCollection!.isPaused
              ? <PatternItem>[
                  PatternItem.dash(10),
                  PatternItem.gap(5)
                ]
              : <PatternItem>[],
        ));
      }
    }

    // Ajouter la chaussée en cours si active (nouveau système)
    if (homeController.chausseeCollection != null) {
      final chausseePoints = homeController.chausseeCollection!.points;
      if (chausseePoints.length > 1) {
        allPolylines.add(Polyline(
          polylineId: const PolylineId('currentChaussee'),
          points: chausseePoints,
          color: homeController.chausseeCollection!.isPaused ? Colors.deepOrange : const Color(0xFFFF9800),
          width: 5,
          patterns: homeController.chausseeCollection!.isPaused
              ? <PatternItem>[
                  PatternItem.dash(15),
                  PatternItem.gap(5)
                ]
              : <PatternItem>[],
        ));
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: SafeArea(
        child: Column(
          children: [
            TopBarWidget(onLogout: _showLogoutConfirmation),
            Expanded(
              child: Stack(
                children: [
                  MapWidget(
                    userPosition: userPosition,
                    gpsEnabled: gpsEnabled,
                    markers: markersSet,
                    polylines: allPolylines,
                    onMapCreated: _onMapCreated,
                    formMarkers: formMarkers,
                  ),
                  if (isSyncing)
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(
                        color: Colors.black.withOpacity(0.2),
                      ),
                    ),

                  if (isDownloading)
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(
                        color: Colors.black.withOpacity(0.2),
                      ),
                    ),
// Dans le Stack de la méthode build() - Positionnez où vous voulez
                  Positioned(
                    top: 100, // Ajustez la position selon vos besoins
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _showDownloadedPoints = !_showDownloadedPoints;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_showDownloadedPoints ? 'Points téléchargés affichés (verts)' : 'Points téléchargés masqués'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: Icon(
                              _showDownloadedPoints ? Icons.visibility : Icons.visibility_off,
                              color: _showDownloadedPoints ? Colors.green : Colors.grey,
                            ),
                            tooltip: _showDownloadedPoints ? 'Masquer les points téléchargés' : 'Afficher les points téléchargés',
                          ),
                          Text(
                            'Données serveur',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                  // === AJOUTEZ ICI === //
                  Positioned(
                    bottom: 200,
                    right: 16,
                    child: Visibility(
                      visible: kDebugMode && homeController.hasActiveCollection,
                      child: FloatingActionButton(
                        onPressed: () {
                          homeController.addRealisticPisteSimulation();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Points réalistes simulés'), // ← MESSAGE MODIFIÉ
                              backgroundColor: Colors.blue,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        backgroundColor: Colors.orange,
                        child: const Icon(Icons.add_location_alt, color: Colors.white),
                        mini: true,
                        heroTag: 'dev_button',
                      ),
                    ),
                  ),
                  // Ajouter dans la section des boutons de debug
                  Positioned(
                    bottom: 120,
                    right: 16,
                    child: Visibility(
                      visible: _isSpecialCollection && kDebugMode,
                      child: FloatingActionButton(
                        onPressed: () {
                          homeController.addManualPointToSpecialCollection();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Points simulés pour $_specialCollectionType'),
                              backgroundColor: Colors.purple,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        backgroundColor: Colors.purple,
                        child: const Icon(Icons.add_road, color: Colors.white),
                        mini: true,
                        heroTag: 'simulate_special_button',
                      ),
                    ),
                  ),
                  // === FIN DE L'AJOUT === //
                  // Contrôles de carte
                  MapControlsWidget(
                    controller: homeController,
                    onAddPoint: addPointOfInterest,
                    onStartLigne: startLigneCollection,
                    onStartChaussee: startChausseeCollection,
                    onToggleLigne: toggleLigneCollection,
                    onToggleChaussee: toggleChausseeCollection,
                    onFinishLigne: finishLigneCollection,
                    onFinishChaussee: finishChausseeCollection,
                    onRefresh: _loadDisplayedPoints,
                    isSpecialCollection: _isSpecialCollection, // ← NOUVEAU
                    onStopSpecial: finishSpecialCollection,
                  ),

                  // === WIDGETS DE STATUT (NOUVEAU SYSTÈME UNIQUEMENT) ===

                  // Afficher le statut de ligne si active
                  if (homeController.ligneCollection != null)
                    LigneStatusWidget(
                      collection: homeController.ligneCollection!,
                      topOffset: 16,
                    ),

                  // Afficher le statut de chaussée si active
                  if (homeController.chausseeCollection != null)
                    ChausseeStatusWidget(
                      collection: homeController.chausseeCollection!,
                      topOffset: homeController.ligneCollection != null ? 70 : 16,
                    ),

                  DataCountWidget(count: collectedMarkers.length + collectedPolylines.length),
                  // Remplacez le Positioned actuel par ceci :
                  if (isDownloading)
                    Positioned(
                      top: 70, // Position sous la barre d'outils
                      left: 0,
                      right: 0,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        offset: isDownloading ? Offset.zero : const Offset(0, -1),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isDownloading ? 1.0 : 0.0,
                          child: _buildProgressIndicator(),
                        ),
                      ),
                    ),
                  if (isSyncing)
                    Positioned(
                      top: 70, // Position sous la top bar
                      left: 0,
                      right: 0,
                      child: AnimatedSlide(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        offset: isSyncing ? Offset.zero : Offset(0, -1),
                        child: AnimatedOpacity(
                          duration: Duration(milliseconds: 300),
                          opacity: isSyncing ? 1.0 : 0.0,
                          child: _buildSyncProgressIndicator(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            BottomStatusBarWidget(gpsEnabled: gpsEnabled),
            BottomButtonsWidget(
              onSave: isDownloading ? () {} : _showSaveConfirmationDialog,
              onSync: isSyncing ? () {} : _showSyncConfirmationDialog,
              onMenu: handleMenuPress,
            ),
          ],
        ),
      ),
    );
  }
}
// === COLLEZ CETTE CLASSE DIRECTEMENT DANS home_page.dart ===
// À la fin du fichier, avant la dernière accolade fermante

class DisplayedPointsService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Set<Marker>> getDisplayedPointsMarkers() async {
    try {
      final points = await _dbHelper.loadDisplayedPoints();
      final Set<Marker> markers = {};

      for (var point in points) {
        final pointType = point['point_type'] as String?;
        if (pointType == "Bac" || pointType == "Passage Submersible") {
          continue; // Ne pas créer de marqueur pour ces types
        }
        markers.add(Marker(
          markerId: MarkerId('displayed_point_${point['id']}'),
          position: LatLng(
            (point['latitude'] as num).toDouble(),
            (point['longitude'] as num).toDouble(),
          ),
          infoWindow: InfoWindow(
            title: '${point['point_type']}: ${point['point_name']}',
            snippet: 'Code Piste: ${point['code_piste'] ?? 'N/A'}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
      }

      print('📍 ${markers.length} points affichés chargés');
      return markers;
    } catch (e) {
      print('❌ Erreur dans getDisplayedPointsMarkers: $e');
      return {};
    }
  }

  Future<Set<Marker>> refreshDisplayedPoints() async {
    return await getDisplayedPointsMarkers();
  }
}

// Dans home_page.dart, ajoutez cette classe
class SpecialLinesService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Set<Polyline>> getDisplayedSpecialLines() async {
    try {
      final lines = await _dbHelper.loadDisplayedSpecialLines();
      final Set<Polyline> polylines = {};

      for (var line in lines) {
        final specialType = line['special_type'] as String;
        final lineColor = specialType == "Bac" ? Colors.purple : Colors.deepPurple;

        polylines.add(Polyline(
          polylineId: PolylineId('special_line_${line['id']}'),
          points: [
            LatLng(
              (line['lat_debut'] as num).toDouble(),
              (line['lng_debut'] as num).toDouble(),
            ),
            LatLng(
              (line['lat_fin'] as num).toDouble(),
              (line['lng_fin'] as num).toDouble(),
            ),
          ],
          color: lineColor,
          width: 4,
          patterns: [
            PatternItem.dash(10),
            PatternItem.gap(5)
          ],
        ));
      }

      print('📍 ${polylines.length} lignes spéciales chargées');
      return polylines;
    } catch (e) {
      print('❌ Erreur chargement lignes spéciales: $e');
      return {};
    }
  }
}

// Dans home_page.dart - Ajoutez cette classe
class DownloadedPointsService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Set<Marker>> getDownloadedPointsMarkers() async {
    try {
      // Récupérer tous les points avec downloaded = 1 (téléchargés depuis le serveur)
      final List<String> pointTables = [
        'localites',
        'ecoles',
        'marches',
        'services_santes',
        'batiments_administratifs',
        'infrastructures_hydrauliques',
        'autres_infrastructures',
        'ponts',
        'buses',
        'dalots',
        'points_critiques',
        'points_coupures'
      ];

      final Set<Marker> markers = {};

      for (var tableName in pointTables) {
        try {
          final db = await _dbHelper.database;

          // ⭐⭐ FILTRE CRITIQUE : downloaded = 1 (données téléchargées) ⭐⭐
          final points = await db.query(
            tableName,
            where: 'downloaded = ?',
            whereArgs: [
              1
            ],
          );

          for (var point in points) {
            final coordinates = _getCoordinatesFromPoint(point, tableName);
            if (coordinates['lat'] != null && coordinates['lng'] != null) {
              markers.add(Marker(
                markerId: MarkerId('downloaded_${tableName}_${point['id']}'),
                position: LatLng(
                  (coordinates['lat'] as num).toDouble(),
                  (coordinates['lng'] as num).toDouble(),
                ),
                infoWindow: InfoWindow(
                  title: '${_getEntityTypeFromTable(tableName)}: ${point['nom'] ?? 'Sans nom'}',
                  snippet: 'Code Piste: ${point['code_piste'] ?? 'N/A'}\n'
                      'Enquêteur: ${point['enqueteur'] ?? 'Autre utilisateur'}',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), // ⭐⭐ VERT ⭐⭐
              ));
            }
          }
        } catch (e) {
          print('❌ Erreur table $tableName: $e');
        }
      }

      print('📍 ${markers.length} points téléchargés (verts) chargés');
      return markers;
    } catch (e) {
      print('❌ Erreur dans getDownloadedPointsMarkers: $e');
      return {};
    }
  }

  Map<String, dynamic> _getCoordinatesFromPoint(Map<String, dynamic> point, String tableName) {
    final coordinateMappings = {
      'localites': {
        'lat': 'y_localite',
        'lng': 'x_localite'
      },
      'ecoles': {
        'lat': 'y_ecole',
        'lng': 'x_ecole'
      },
      'marches': {
        'lat': 'y_marche',
        'lng': 'x_marche'
      },
      'services_santes': {
        'lat': 'y_sante',
        'lng': 'x_sante'
      },
      'batiments_administratifs': {
        'lat': 'y_batiment_administratif',
        'lng': 'x_batiment_administratif'
      },
      'infrastructures_hydrauliques': {
        'lat': 'y_infrastructure_hydraulique',
        'lng': 'x_infrastructure_hydraulique'
      },
      'autres_infrastructures': {
        'lat': 'y_autre_infrastructure',
        'lng': 'x_autre_infrastructure'
      },
      'ponts': {
        'lat': 'y_pont',
        'lng': 'x_pont'
      },
      'buses': {
        'lat': 'y_buse',
        'lng': 'x_buse'
      },
      'dalots': {
        'lat': 'y_dalot',
        'lng': 'x_dalot'
      },
      'points_critiques': {
        'lat': 'y_point_critique',
        'lng': 'x_point_critique'
      },
      'points_coupures': {
        'lat': 'y_point_coupure',
        'lng': 'x_point_coupure'
      },
    };

    final mapping = coordinateMappings[tableName];
    if (mapping != null) {
      return {
        'lat': point[mapping['lat']],
        'lng': point[mapping['lng']],
      };
    }

    return {
      'lat': null,
      'lng': null
    };
  }

  String _getEntityTypeFromTable(String tableName) {
    const entityTypes = {
      'localites': 'Localité',
      'ecoles': 'École',
      'marches': 'Marché',
      'services_santes': 'Service de Santé',
      'batiments_administratifs': 'Bâtiment Administratif',
      'infrastructures_hydrauliques': 'Infrastructure Hydraulique',
      'autres_infrastructures': 'Autre Infrastructure',
      'ponts': 'Pont',
      'buses': 'Buse',
      'dalots': 'Dalot',
      'points_critiques': 'Point Critique',
      'points_coupures': 'Point de Coupure',
    };
    return entityTypes[tableName] ?? tableName;
  }
}
