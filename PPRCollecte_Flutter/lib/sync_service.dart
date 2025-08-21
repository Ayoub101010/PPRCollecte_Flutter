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
          print('✅ ${tableName} ID ${data['id']} synchronisé');
        } else {
          result.failedCount++;
          result.errors.add('Échec synchronisation ${tableName} ID ${data['id']}');
          print('❌ Échec synchronisation ${tableName} ID ${data['id']}');
        }

        // Petite pause pour éviter de surcharger l'API
        await Future.delayed(Duration(milliseconds: 100));
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
}
