import 'api_service.dart';
import 'database_helper.dart';

class SyncResult {
  int successCount = 0;
  int failedCount = 0;
  List<String> errors = [];

  @override
  String toString() {
    return 'Synchronisation: $successCount succès, $failedCount échecs';
  }
}

class SyncService {
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<SyncResult> syncAllData() async {
    final result = SyncResult();

    // Synchroniser chaque table
    await _syncTable('localites', 'localites', result);
    await _syncTable('ecoles', 'ecoles', result);
    await _syncTable('marches', 'marches', result);
    await _syncTable('services_santes', 'services_santes', result);
    await _syncTable('batiments_administratifs', 'batiments_administratifs', result);
    await _syncTable('infrastructures_hydrauliques', 'infrastructures_hydrauliques', result);
    await _syncTable('autres_infrastructures', 'autres_infrastructures', result);
    await _syncTable('ponts', 'ponts', result);
    await _syncTable('bacs', 'bacs', result);
    await _syncTable('buses', 'buses', result);
    await _syncTable('dalots', 'dalots', result);
    await _syncTable('passages_submersibles', 'passages_submersibles', result);
    await _syncTable('points_critiques', 'points_critiques', result);
    await _syncTable('points_coupures', 'points_coupures', result);

    return result;
  }

  Future<void> _syncTable(String tableName, String apiEndpoint, SyncResult result) async {
    try {
      print('🔄 Synchronisation de $tableName...');

      // 1. Récupérer données locales non synchronisées
      final localData = await dbHelper.getUnsyncedEntities(tableName);

      if (localData.isEmpty) {
        print('ℹ️ Aucune donnée à synchroniser pour $tableName');
        return;
      }

      print('📊 ${localData.length} enregistrement(s) à synchroniser pour $tableName');

      // 2. Envoyer chaque enregistrement à l'API
      for (var data in localData) {
        final success = await _sendDataToApi(apiEndpoint, data);

        if (success) {
          // 3. Marquer comme synchronisé
          await dbHelper.markAsSynced(tableName, data['id']);
          result.successCount++;
          print('✅ $tableName ID ${data['id']} synchronisé');
        } else {
          result.failedCount++;
          result.errors.add('Échec synchronisation $tableName ID ${data['id']}');
          print('❌ Échec synchronisation $tableName ID ${data['id']}');
        }

        // Petite pause pour éviter de surcharger l'API
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      result.errors.add('$tableName: $e');
      print('❌ Erreur lors de la synchronisation de $tableName: $e');
    }
  }

  Future<bool> _sendDataToApi(String endpoint, Map<String, dynamic> data) async {
    switch (endpoint) {
      case 'localites':
        return await ApiService.syncLocalite(data);
      case 'ecoles':
        return await ApiService.syncEcole(data);
      case 'marches':
        return await ApiService.syncMarche(data);
      case 'services_santes':
        return await ApiService.syncServiceSante(data);
      case 'batiments_administratifs':
        return await ApiService.syncBatimentAdministratif(data);
      case 'infrastructures_hydrauliques':
        return await ApiService.syncInfrastructureHydraulique(data);
      case 'autres_infrastructures':
        return await ApiService.syncAutreInfrastructure(data);
      case 'ponts':
        return await ApiService.syncPont(data);
      case 'bacs':
        return await ApiService.syncBac(data);
      case 'buses':
        return await ApiService.syncBuse(data);
      case 'dalots':
        return await ApiService.syncDalot(data);
      case 'passages_submersibles':
        return await ApiService.syncPassageSubmersible(data);
      case 'points_critiques':
        return await ApiService.syncPointCritique(data);
      case 'points_coupures':
        return await ApiService.syncPointCoupure(data);
      default:
        return await ApiService.postData(endpoint, data);
    }
  }

  // AJOUTEZ cette méthode
  Future<SyncResult> downloadAllData() async {
    final result = SyncResult();

    try {
      print('⬇️ Début du téléchargement des données...');

      // ============ LOCALITES ============
      print('📥 Téléchargement des localités...');
      final localites = await ApiService.fetchLocalites();
      print('📍 ${localites.length} localités à traiter');
      for (var localite in localites) {
        await dbHelper.saveOrUpdateLocalite(localite);
        result.successCount++;
      }

      // ============ ECOLES ============
      print('📥 Téléchargement des écoles...');
      final ecoles = await ApiService.fetchEcoles();
      print('🏫 ${ecoles.length} écoles à traiter');
      for (var ecole in ecoles) {
        await dbHelper.saveOrUpdateEcole(ecole);
        result.successCount++;
      }

      // ============ MARCHES ============
      print('📥 Téléchargement des marchés...');
      final marches = await ApiService.fetchMarches();
      print('🛒 ${marches.length} marchés à traiter');
      for (var marche in marches) {
        await dbHelper.saveOrUpdateMarche(marche);
        result.successCount++;
      }

      // ============ SERVICES SANTES ============
      print('📥 Téléchargement des services de santé...');
      final servicesSantes = await ApiService.fetchServicesSantes();
      print('🏥 ${servicesSantes.length} services de santé à traiter');
      for (var service in servicesSantes) {
        await dbHelper.saveOrUpdateServiceSante(service);
        result.successCount++;
      }

      // ============ BATIMENTS ADMINISTRATIFS ============
      print('📥 Téléchargement des bâtiments administratifs...');
      final batiments = await ApiService.fetchBatimentsAdministratifs();
      print('🏛️ ${batiments.length} bâtiments administratifs à traiter');
      for (var batiment in batiments) {
        await dbHelper.saveOrUpdateBatimentAdministratif(batiment);
        result.successCount++;
      }

      // ============ INFRASTRUCTURES HYDRAULIQUES ============
      print('📥 Téléchargement des infrastructures hydrauliques...');
      final infrastructures = await ApiService.fetchInfrastructuresHydrauliques();
      print('💧 ${infrastructures.length} infrastructures hydrauliques à traiter');
      for (var infrastructure in infrastructures) {
        await dbHelper.saveOrUpdateInfrastructureHydraulique(infrastructure);
        result.successCount++;
      }

      // ============ AUTRES INFRASTRUCTURES ============
      print('📥 Téléchargement des autres infrastructures...');
      final autresInfrastructures = await ApiService.fetchAutresInfrastructures();
      print('🏗️ ${autresInfrastructures.length} autres infrastructures à traiter');
      for (var infrastructure in autresInfrastructures) {
        await dbHelper.saveOrUpdateAutreInfrastructure(infrastructure);
        result.successCount++;
      }

      // ============ PONTS ============
      print('📥 Téléchargement des ponts...');
      final ponts = await ApiService.fetchPonts();
      print('🌉 ${ponts.length} ponts à traiter');
      for (var pont in ponts) {
        await dbHelper.saveOrUpdatePont(pont);
        result.successCount++;
      }

      // ============ BACS ============
      print('📥 Téléchargement des bacs...');
      final bacs = await ApiService.fetchBacs();
      print('⛴️ ${bacs.length} bacs à traiter');
      for (var bac in bacs) {
        await dbHelper.saveOrUpdateBac(bac);
        result.successCount++;
      }

      // ============ BUSES ============
      print('📥 Téléchargement des buses...');
      final buses = await ApiService.fetchBuses();
      print('🕳️ ${buses.length} buses à traiter');
      for (var buse in buses) {
        await dbHelper.saveOrUpdateBuse(buse);
        result.successCount++;
      }

      // ============ DALOTS ============
      print('📥 Téléchargement des dalots...');
      final dalots = await ApiService.fetchDalots();
      print('🔄 ${dalots.length} dalots à traiter');
      for (var dalot in dalots) {
        await dbHelper.saveOrUpdateDalot(dalot);
        result.successCount++;
      }

      // ============ PASSAGES SUBMERSIBLES ============
      print('📥 Téléchargement des passages submersibles...');
      final passages = await ApiService.fetchPassagesSubmersibles();
      print('🌊 ${passages.length} passages submersibles à traiter');
      for (var passage in passages) {
        await dbHelper.saveOrUpdatePassageSubmersible(passage);
        result.successCount++;
      }

      // ============ POINTS CRITIQUES ============
      print('📥 Téléchargement des points critiques...');
      final pointsCritiques = await ApiService.fetchPointsCritiques();
      print('⚠️ ${pointsCritiques.length} points critiques à traiter');
      for (var point in pointsCritiques) {
        await dbHelper.saveOrUpdatePointCritique(point);
        result.successCount++;
      }

      // ============ POINTS COUPURES ============
      print('📥 Téléchargement des points de coupure...');
      final pointsCoupures = await ApiService.fetchPointsCoupures();
      print('🔌 ${pointsCoupures.length} points de coupure à traiter');
      for (var point in pointsCoupures) {
        await dbHelper.saveOrUpdatePointCoupure(point);
        result.successCount++;
      }

      print('✅ Téléchargement terminé: ${result.successCount} données traitées');
    } catch (e) {
      result.errors.add('Erreur téléchargement: $e');
      print('❌ Erreur lors du téléchargement: $e');
    }

    return result;
  }
}
