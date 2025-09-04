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

  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _lastCameraPosition;
  late final HomeController homeController;

  @override
  void initState() {
    super.initState();
    homeController = HomeController();
    _loadDisplayedPistes();
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
    collectedMarkers.addAll([
      Marker(
        markerId: const MarkerId('poi1'),
        position: const LatLng(34.021, -6.841),
        infoWindow: const InfoWindow(title: 'Point d\'intérêt 1', snippet: 'Infrastructure - Point'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    ]);

    collectedPolylines.add(const Polyline(
      polylineId: PolylineId('piste1'),
      points: [
        LatLng(34.020, -6.840),
        LatLng(34.022, -6.842),
        LatLng(34.023, -6.843),
      ],
      color: Colors.blue,
      width: 3,
    ));
  }

  String generateCodePiste() {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    return 'Piste_$timestamp';
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
      homeController.refreshFormMarkers();
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
  Future<void> _loadDisplayedPistes() async {
    final storageHelper = SimpleStorageHelper();
    final displayedPistes = await storageHelper.loadDisplayedPistes();
    setState(() {
      _finishedPistes = displayedPistes;
    });
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
          agentName: widget.agentName, // ✅ Utiliser l'ID correct
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
    );
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
  Future<void> _performSync() async {
    setState(() {
      isSyncing = true;
      _syncProgressValue = 0.0;
      _syncProcessedItems = 0;
      _syncTotalItems = 1; // Valeur initiale
    });

    try {
      final result = await SyncService().syncAllData(
        onProgress: (progress, currentOperation, processed, total) {
          // ⭐⭐ VALIDATION DES VALEURS ⭐⭐
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
      // Cacher la progression avant de montrer le résultat
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

// Ajoutez cette méthode
  Widget _buildSyncProgressIndicator() {
    // ⭐⭐ VALIDATION DES VALEURS NUMÉRIQUES ⭐⭐
    double safeProgress = _syncProgressValue.isNaN || _syncProgressValue.isInfinite ? 0.0 : _syncProgressValue.clamp(0.0, 1.0);

    int safeProcessed = _syncProcessedItems.isNaN || _syncProcessedItems.isInfinite ? 0 : _syncProcessedItems;

    int safeTotal = _syncTotalItems.isNaN || _syncTotalItems.isInfinite ? 1 : _syncTotalItems;
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[100]!),
        boxShadow: [
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
          Row(
            children: [
              Icon(Icons.cloud_upload, color: Colors.orange),
              SizedBox(width: 10),
              Text(
                'Synchronisation en cours',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 12),
          LinearProgressIndicator(
            value: safeProgress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(safeProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                '$safeProcessed/${safeTotal == 0 ? 1 : safeTotal}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _currentSyncOperation,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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
    final Set<Marker> markersSet = Set<Marker>.from(collectedMarkers);
    markersSet.addAll(formMarkers);
    markersSet.removeWhere((m) => m.markerId.value == 'user');
    markersSet.add(Marker(
      markerId: const MarkerId('user'),
      position: userPosition,
      infoWindow: const InfoWindow(title: 'Vous êtes ici'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ));

    // Préparer les polylines
    final allPolylines = Set<Polyline>.from(collectedPolylines);
    allPolylines.addAll(_finishedPistes); // ← CORRECTION SIMPLE
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
                    bottom: 160,
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
