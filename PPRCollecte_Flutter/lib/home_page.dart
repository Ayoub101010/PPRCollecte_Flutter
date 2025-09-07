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

  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _lastCameraPosition;
  late final HomeController homeController;
  final DisplayedPointsService _pointsService = DisplayedPointsService();

  @override
  void initState() {
    super.initState();
    homeController = HomeController();
    //_cleanupDisplayedPoints();
    _loadDisplayedPistes();
    _loadDisplayedPoints();
    _loadDisplayedChaussees();

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

  Future<void> _loadDisplayedChaussees() async {
    final storageHelper = SimpleStorageHelper();
    final displayedChaussees = await storageHelper.loadDisplayedChaussees();

    setState(() {
      _finishedChaussees = displayedChaussees;
    });

    print('✅ ${_finishedChaussees.length} chaussées chargées');
  }

  Future<void> _cleanupDisplayedPoints() async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.cleanupDisplayedPoints();
    } catch (e) {
      print('❌ Erreur nettoyage points: $e');
    }
  }

  String generateCodePiste() {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    return 'Piste_$timestamp';
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
    print('POSITION ACTUELLE: ${current.latitude}, ${current.longitude}');
    // ⭐⭐ TROUVER LE CODE PISTE LE PLUS PROCHE ⭐⭐
    final storageHelper = SimpleStorageHelper();
    final nearestPisteCode = await storageHelper.findNearestPisteCode(current);

    print('📍 Code piste le plus proche pour le point: $nearestPisteCode');

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
        ),
      ),
    );

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
      // homeController.refreshFormMarkers();
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

    // ⭐⭐ GÉNÉRER le code piste automatiquement
    final codePisteAuto = generateCodePiste();

    // ⭐⭐ Afficher le dialogue AVEC code pré-rempli et IMMODIFIABLE
    final provisionalData = await ProvisionalFormDialog.show(
      context: context,
      initialCode: codePisteAuto,
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
      final displayedPistes = await storageHelper.loadDisplayedPistes();

      // Filtrer seulement les pistes valides
      final allPistes = await storageHelper.getAllPistesMaps();
      final existingIds = allPistes.map((p) => p['id'] as int).toSet();

      final validPistes = displayedPistes.where((polyline) {
        final polylineId = polyline.polylineId.value;
        final idStr = polylineId.replaceFirst('displayed_piste_', '');
        final id = int.tryParse(idStr);
        return id != null && existingIds.contains(id);
      }).toList();

      setState(() {
        _finishedPistes = validPistes;
      });

      print('✅ ${validPistes.length} pistes valides chargées');
    } catch (e) {
      print('❌ Erreur chargement pistes: $e');
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
      final storageHelper = SimpleStorageHelper();
      _currentNearestPisteCode = await storageHelper.findNearestPisteCode(homeController.userPosition);
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
    // markersSet.addAll(formMarkers);
    // markersSet.removeWhere((m) => m.markerId.value == 'user');
    /* markersSet.add(Marker(
      markerId: const MarkerId('user'),
      position: userPosition,
      infoWindow: const InfoWindow(title: 'Vous êtes ici'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ));*/

    // Préparer les polylines
    final allPolylines = Set<Polyline>.from(collectedPolylines);
    allPolylines.addAll(_finishedPistes);
    allPolylines.addAll(_finishedChaussees); // ← CORRECTION SIMPLE
    // Ajouter la ligne en cours si active (nouveau système)
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
