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

  Future<SyncResult> syncAllData({Function(double, String, int, int)? onProgress}) async {
    final result = SyncResult();
    int totalItems = 0;
    int processedItems = 0;

    // ⭐⭐ CODE SÉCURISÉ - DEBUT ⭐⭐
    if (onProgress != null) {
      onProgress(0.0, "Démarrage de la synchronisation...", 0, 1);
    }

    // Compter le total des items d'abord
    final tables = [
      'localites',
      'ecoles',
      'marches',
      'services_santes',
      'batiments_administratifs',
      'infrastructures_hydrauliques',
      'autres_infrastructures',
      'ponts',
      'bacs',
      'buses',
      'dalots',
      'passages_submersibles',
      'points_critiques',
      'points_coupures'
    ];

    for (var table in tables) {
      final data = await dbHelper.getUnsyncedEntities(table);
      totalItems += data.length;
    }

    // ⭐⭐ CORRECTION: Éviter division par zéro
    final safeTotalItems = totalItems > 0 ? totalItems : 1;

    if (onProgress != null) {
      onProgress(0.0, "Préparation...", 0, safeTotalItems);
    }

    // Synchroniser chaque table avec progression
    for (var i = 0; i < tables.length; i++) {
      final table = tables[i];
      final apiEndpoint = table;

      // ⭐⭐ CORRECTION: Calcul sécurisé du progrès
      double safeProgress = safeTotalItems > 0 ? processedItems / safeTotalItems : 0.0;
      safeProgress = safeProgress.isNaN || safeProgress.isInfinite ? 0.0 : safeProgress.clamp(0.0, 1.0);

      if (onProgress != null) {
        onProgress(safeProgress, "Synchronisation des ${_getFrenchTableName(table)}...", processedItems, safeTotalItems);
      }

      await _syncTable(table, apiEndpoint, result, onProgress: (processed, total) {
        if (onProgress != null) {
          // ⭐⭐ CORRECTION: Calcul sécurisé du progrès
          double safeInnerProgress = safeTotalItems > 0 ? (processedItems + processed) / safeTotalItems : 0.0;
          safeInnerProgress = safeInnerProgress.isNaN || safeInnerProgress.isInfinite ? 0.0 : safeInnerProgress.clamp(0.0, 1.0);

          onProgress(safeInnerProgress, "Synchronisation des ${_getFrenchTableName(table)}...", processedItems + processed, safeTotalItems);
        }
      });

      processedItems += (await dbHelper.getUnsyncedEntities(table)).length;
    }

    if (onProgress != null) {
      onProgress(1.0, "Synchronisation terminée!", processedItems, safeTotalItems);
    }
    // ⭐⭐ CODE SÉCURISÉ - FIN ⭐⭐

    return result;
  }

  // Méthode pour les noms français des tables
  String _getFrenchTableName(String tableName) {
    const frenchNames = {
      'localites': 'localités',
      'ecoles': 'écoles',
      'marches': 'marchés',
      'services_santes': 'services de santé',
      'batiments_administratifs': 'bâtiments administratifs',
      'infrastructures_hydrauliques': 'infrastructures hydrauliques',
      'autres_infrastructures': 'autres infrastructures',
      'ponts': 'ponts',
      'bacs': 'bacs',
      'buses': 'buses',
      'dalots': 'dalots',
      'passages_submersibles': 'passages submersibles',
      'points_critiques': 'points critiques',
      'points_coupures': 'points de coupure',
    };
    return frenchNames[tableName] ?? tableName;
  }

  Future<void> _syncTable(String tableName, String apiEndpoint, SyncResult result, {Function(int, int)? onProgress}) async {
    try {
      print('🔄 Synchronisation de $tableName...');

      // 1. Récupérer UNIQUEMENT les données non synchronisées ET non téléchargées
      final localData = await dbHelper.getUnsyncedEntities(tableName);

      if (localData.isEmpty) {
        print('ℹ️ Aucune donnée à synchroniser pour $tableName');
        return;
      }

      print('📊 ${localData.length} enregistrement(s) à synchroniser pour $tableName');

      // 2. FILTRE SUPPLÉMENTAIRE : vérifier le code_piste
      for (var i = 0; i < localData.length; i++) {
        var data = localData[i];
        // ⭐⭐ VÉRIFICATION CRITIQUE : code_piste ne doit pas être "Non spécifié"
        final codePiste = data['code_piste']?.toString().trim();
        if (codePiste == null || codePiste.isEmpty || codePiste == 'Non spécifié' || codePiste == 'Non spÃ©cifiÃ©') {
          print('⏭️ Skipping ${tableName} ID ${data['id']} - code_piste invalide: "$codePiste"');
          result.failedCount++;
          result.errors.add('$tableName ID ${data['id']}: code_piste invalide');
          continue; // Passer au suivant
        }

        // 3. Envoyer seulement si code_piste est valide
        final success = await _sendDataToApi(apiEndpoint, data);

        if (success) {
          await dbHelper.markAsSynced(tableName, data['id']);
          result.successCount++;
          print('✅ $tableName ID ${data['id']} synchronisé');
        } else {
          result.failedCount++;
          result.errors.add('Échec synchronisation $tableName ID ${data['id']}');
          print('❌ Échec synchronisation $tableName ID ${data['id']}');
        }
// ⭐⭐ FIN DE VOTRE LOGIQUE EXISTANTE ⭐⭐

        // ⭐⭐ AJOUTEZ LE CALLBACK DE PROGRESSION ICI ⭐⭐
        if (onProgress != null) {
          onProgress(i + 1, localData.length);
        }
        await Future.delayed(const Duration(milliseconds: 50));
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
  Future<SyncResult> downloadAllData({Function(double, String, int, int)? onProgress}) async {
    final result = SyncResult();
    int totalItems = 0;
    int processedItems = 0;

    try {
      if (onProgress != null) {
        onProgress(0.0, "Démarrage du téléchargement...", 0, 1);
      }
      print('⬇️ Début du téléchargement des données...');

// Compter le nombre total d'éléments à télécharger
      final operations = [
        ApiService.fetchLocalites,
        ApiService.fetchEcoles,
        ApiService.fetchMarches,
        ApiService.fetchServicesSantes,
        ApiService.fetchBatimentsAdministratifs,
        ApiService.fetchInfrastructuresHydrauliques,
        ApiService.fetchAutresInfrastructures,
        ApiService.fetchPonts,
        ApiService.fetchBacs,
        ApiService.fetchBuses,
        ApiService.fetchDalots,
        ApiService.fetchPassagesSubmersibles,
        ApiService.fetchPointsCritiques,
        ApiService.fetchPointsCoupures,
      ];

      // Calculer le nombre total d'items
      for (var op in operations) {
        final data = await op();
        totalItems += data.length;
      }

      if (onProgress != null) {
        onProgress(0.0, "Préparation...", 0, totalItems);
      }
      // ============ LOCALITES ============
      if (onProgress != null) {
        onProgress(processedItems / totalItems, "Téléchargement des localités...", processedItems, totalItems);
      }
      print('📥 Téléchargement des localités...');
      final localites = await ApiService.fetchLocalites();
      print('📍 ${localites.length} localités à traiter');
      for (var localite in localites) {
        await dbHelper.saveOrUpdateLocalite(localite);
        result.successCount++;
        processedItems++;

        if (onProgress != null) {
          onProgress(processedItems / totalItems, "Sauvegarde des localités...", processedItems, totalItems);
        }
      }

      // ============ ECOLES ============
      if (onProgress != null) {
        onProgress(processedItems / totalItems, "Téléchargement des écoles...", processedItems, totalItems);
      }
      print('📥 Téléchargement des écoles...');
      final ecoles = await ApiService.fetchEcoles();
      print('🏫 ${ecoles.length} écoles à traiter');
      for (var ecole in ecoles) {
        await dbHelper.saveOrUpdateEcole(ecole);
        result.successCount++;
        processedItems++;

        if (onProgress != null) {
          onProgress(processedItems / totalItems, "Sauvegarde des écoles...", processedItems, totalItems);
        }
      }

      // ============ MARCHES ============

      if (onProgress != null) {
        onProgress(processedItems / totalItems, "Téléchargement des marchés...", processedItems, totalItems);
      }
      print('📥 Téléchargement des marchés...');
      final marches = await ApiService.fetchMarches();
      print('🛒 ${marches.length} marchés à traiter');
      for (var marche in marches) {
        await dbHelper.saveOrUpdateMarche(marche);
        result.successCount++;
        processedItems++;

        if (onProgress != null) {
          onProgress(processedItems / totalItems, "Sauvegarde des marchés...", processedItems, totalItems);
        }
      }

      // ============ SERVICES SANTES ============
      if (onProgress != null) {
        onProgress(processedItems / totalItems, "Téléchargement des services de santé ...", processedItems, totalItems);
      }
      print('📥 Téléchargement des services de santé...');
      final servicesSantes = await ApiService.fetchServicesSantes();
      print('🏥 ${servicesSantes.length} services de santé à traiter');
      for (var service in servicesSantes) {
        await dbHelper.saveOrUpdateServiceSante(service);
        result.successCount++;
        processedItems++;

        if (onProgress != null) {
          onProgress(processedItems / totalItems, "Sauvegarde des services de santé...", processedItems, totalItems);
        }
      }

      // ============ BATIMENTS ADMINISTRATIFS ============

      if (onProgress != null) {
        onProgress(processedItems / totalItems, "Téléchargement des bâtiments administratifs...", processedItems, totalItems);
      }
      print('📥 Téléchargement des bâtiments administratifs...');
      final batiments = await ApiService.fetchBatimentsAdministratifs();
      print('🏛️ ${batiments.length} bâtiments administratifs à traiter');
      for (var batiment in batiments) {
        await dbHelper.saveOrUpdateBatimentAdministratif(batiment);
        result.successCount++;
        processedItems++;

        if (onProgress != null) {
          onProgress(processedItems / totalItems, "Sauvegarde des bâtiments administratifs...", processedItems, totalItems);
        }
      }

      // ============ INFRASTRUCTURES HYDRAULIQUES ============

      if (onProgress != null) {
        onProgress(processedItems / totalItems, "Téléchargement des infrastructures hydrauliques...", processedItems, totalItems);
      }
      print('📥 Téléchargement des infrastructures hydrauliques...');
      final infrastructures = await ApiService.fetchInfrastructuresHydrauliques();
      print('💧 ${infrastructures.length} infrastructures hydrauliques à traiter');
      for (var infrastructure in infrastructures) {
        await dbHelper.saveOrUpdateInfrastructureHydraulique(infrastructure);
        result.successCount++;
        processedItems++;

        if (onProgress != null) {
          onProgress(processedItems / totalItems, "Sauvegarde des infrastructures hydrauliques...", processedItems, totalItems);
        }
      }

      // ============ AUTRES INFRASTRUCTURES ============
      if (onProgress != null) {
        onProgress(processedItems / totalItems, "Téléchargement des autres infrastructures...", processedItems, totalItems);
      }
      print('📥 Téléchargement des autres infrastructures...');
      final autresInfrastructures = await ApiService.fetchAutresInfrastructures();
      print('🏗️ ${autresInfrastructures.length} autres infrastructures à traiter');
      for (var infrastructure in autresInfrastructures) {
        await dbHelper.saveOrUpdateAutreInfrastructure(infrastructure);
        result.successCount++;
        processedItems++;

        if (onProgress != null) {
          onProgress(processedItems / totalItems, "Sauvegarde des autres infrastructures...", processedItems, totalItems);
        }
      }

      // ============ PONTS ============

      if (onProgress != null) {
        onProgress(processedItems / totalItems, "Téléchargement des ponts...", processedItems, totalItems);
      }
      print('📥 Téléchargement des ponts...');
      final ponts = await ApiService.fetchPonts();
      print('🌉 ${ponts.length} ponts à traiter');
      for (var pont in ponts) {
        await dbHelper.saveOrUpdatePont(pont);
        result.successCount++;
        processedItems++;

        if (onProgress != null) {
          onProgress(processedItems / totalItems, "Sauvegarde des ponts...", processedItems, totalItems);
        }
      }

      // ============ BACS ============
      if (onProgress != null) {
        onProgress(processedItems / totalItems, "Téléchargement des bacs...", processedItems, totalItems);
      }
      print('📥 Téléchargement des bacs...');
      final bacs = await ApiService.fetchBacs();
      print('⛴️ ${bacs.length} bacs à traiter');
      for (var bac in bacs) {
        await dbHelper.saveOrUpdateBac(bac);
        result.successCount++;
        processedItems++;

        if (onProgress != null) {
          onProgress(processedItems / totalItems, "Sauvegarde des bacs...", processedItems, totalItems);
        }
      }

      // ============ BUSES ============
      if (onProgress != null) {
        onProgress(processedItems / totalItems, "Téléchargement des buses...", processedItems, totalItems);
      }
      print('📥 Téléchargement des buses...');
      final buses = await ApiService.fetchBuses();
      print('🕳️ ${buses.length} buses à traiter');
      for (var buse in buses) {
        await dbHelper.saveOrUpdateBuse(buse);
        result.successCount++;
        processedItems++;

        if (onProgress != null) {
          onProgress(processedItems / totalItems, "Sauvegarde des buses...", processedItems, totalItems);
        }
      }

      // ============ DALOTS ============

      if (onProgress != null) {
        onProgress(processedItems / totalItems, "Téléchargement des dalots...", processedItems, totalItems);
      }
      print('📥 Téléchargement des dalots...');
      final dalots = await ApiService.fetchDalots();
      print('🔄 ${dalots.length} dalots à traiter');
      for (var dalot in dalots) {
        await dbHelper.saveOrUpdateDalot(dalot);
        result.successCount++;
        processedItems++;

        if (onProgress != null) {
          onProgress(processedItems / totalItems, "Sauvegarde des dalots...", processedItems, totalItems);
        }
      }

      // ============ PASSAGES SUBMERSIBLES ============
      if (onProgress != null) {
        onProgress(processedItems / totalItems, "Téléchargement des passages submersibles...", processedItems, totalItems);
      }
      print('📥 Téléchargement des passages submersibles...');
      final passages = await ApiService.fetchPassagesSubmersibles();
      print('🌊 ${passages.length} passages submersibles à traiter');
      for (var passage in passages) {
        await dbHelper.saveOrUpdatePassageSubmersible(passage);
        result.successCount++;
        processedItems++;

        if (onProgress != null) {
          onProgress(processedItems / totalItems, "Sauvegarde des passages submersibles...", processedItems, totalItems);
        }
      }

      // ============ POINTS CRITIQUES ============

      if (onProgress != null) {
        onProgress(processedItems / totalItems, "Téléchargement des points critiques...", processedItems, totalItems);
      }
      print('📥 Téléchargement des points critiques...');
      final pointsCritiques = await ApiService.fetchPointsCritiques();
      print('⚠️ ${pointsCritiques.length} points critiques à traiter');
      for (var point in pointsCritiques) {
        await dbHelper.saveOrUpdatePointCritique(point);
        result.successCount++;
        processedItems++;

        if (onProgress != null) {
          onProgress(processedItems / totalItems, "Sauvegarde des points critiques...", processedItems, totalItems);
        }
      }

      // ============ POINTS COUPURES ============
      if (onProgress != null) {
        onProgress(processedItems / totalItems, "Téléchargement des points de coupure...", processedItems, totalItems);
      }
      print('📥 Téléchargement des points de coupure...');
      final pointsCoupures = await ApiService.fetchPointsCoupures();
      print('🔌 ${pointsCoupures.length} points de coupure à traiter');
      for (var point in pointsCoupures) {
        await dbHelper.saveOrUpdatePointCoupure(point);
        result.successCount++;
        processedItems++;

        if (onProgress != null) {
          onProgress(processedItems / totalItems, "Sauvegarde des points de coupure...", processedItems, totalItems);
        }
      }

      print('✅ Téléchargement terminé: ${result.successCount} données traitées');
      if (onProgress != null) {
        onProgress(1.0, "Téléchargement terminé!", processedItems, totalItems);
      }
    } catch (e) {
      result.errors.add('Erreur téléchargement: $e');
      print('❌ Erreur lors du téléchargement: $e');
      if (onProgress != null) {
        onProgress(processedItems / totalItems, "Erreur: $e", processedItems, totalItems);
      }
    }

    return result;
  }
}
