import 'api_service.dart';
import 'database_helper.dart';
import 'piste_chaussee_db_helper.dart';
import 'dart:convert';

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
    final storageHelper = SimpleStorageHelper();

    // ⭐⭐ COMPTER LES PISTES ET CHAUSSÉES NON SYNCHRONISÉES
    final pisteCount = await storageHelper.getUnsyncedPistesCount();
    final chausseeCount = await storageHelper.getUnsyncedChausseesCount(); // ← NOUVEAU
    totalItems += pisteCount;
    totalItems += chausseeCount; // ← NOUVEAU

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

    // ⭐⭐ SYNCHRONISATION DES PISTES
    if (pisteCount > 0) {
      double safeProgress = safeTotalItems > 0 ? processedItems / safeTotalItems : 0.0;
      safeProgress = safeProgress.isNaN || safeProgress.isInfinite ? 0.0 : safeProgress.clamp(0.0, 1.0);

      if (onProgress != null) {
        onProgress(safeProgress, "Synchronisation des pistes...", processedItems, safeTotalItems);
      }

      await _syncTable('pistes', 'pistes', result, onProgress: (processed, total) {
        if (onProgress != null) {
          double safeInnerProgress = safeTotalItems > 0 ? (processedItems + processed) / safeTotalItems : 0.0;
          safeInnerProgress = safeInnerProgress.isNaN || safeInnerProgress.isInfinite ? 0.0 : safeInnerProgress.clamp(0.0, 1.0);

          onProgress(safeInnerProgress, "Synchronisation des pistes...", processedItems + processed, safeTotalItems);
        }
      });

      processedItems += pisteCount;
    }

    // ⭐⭐ SYNCHRONISATION DES CHAUSSÉES (NOUVEAU)
    if (chausseeCount > 0) {
      double safeProgress = safeTotalItems > 0 ? processedItems / safeTotalItems : 0.0;
      safeProgress = safeProgress.isNaN || safeProgress.isInfinite ? 0.0 : safeProgress.clamp(0.0, 1.0);

      if (onProgress != null) {
        onProgress(safeProgress, "Synchronisation des chaussées...", processedItems, safeTotalItems);
      }

      await _syncTable('chaussees', 'chaussees_test', result, onProgress: (processed, total) {
        if (onProgress != null) {
          double safeInnerProgress = safeTotalItems > 0 ? (processedItems + processed) / safeTotalItems : 0.0;
          safeInnerProgress = safeInnerProgress.isNaN || safeInnerProgress.isInfinite ? 0.0 : safeInnerProgress.clamp(0.0, 1.0);

          onProgress(safeInnerProgress, "Synchronisation des chaussées...", processedItems + processed, safeTotalItems);
        }
      });

      processedItems += chausseeCount;
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
      'pistes': 'pistes',
    };
    return frenchNames[tableName] ?? tableName;
  }

// Dans SyncService
  Future<bool> syncChaussee(Map<String, dynamic> data) async {
    try {
      final apiData = _mapChausseeToApi(data);

      // ⭐⭐ LOG des données envoyées
      print('📤 DONNÉES CHAUSSÉE envoyées à l\'API:');
      apiData['properties'].forEach((key, value) {
        print('   $key: $value (type: ${value?.runtimeType})');
      });

      return await ApiService.postData('chaussees_test', apiData);
    } catch (e) {
      print('❌ Erreur synchronisation chaussée: $e');
      print('📋 Données problématiques: $data');
      return false;
    }
  }

// Dans la classe SyncService
  Map<String, dynamic> _mapChausseeToApi(Map<String, dynamic> localData) {
    // Convertir les points JSON en format GeoJSON MultiLineString
    final pointsJson = localData['points_json'];
    List<dynamic> points = [];

    try {
      points = jsonDecode(pointsJson);
    } catch (e) {
      print('❌ Erreur décodage points JSON chaussée: $e');
    }

    // Convertir en format GeoJSON coordinates
    final coordinates = points.map((point) {
      return [
        point['longitude'] ?? point['lng'] ?? 0.0,
        point['latitude'] ?? point['lat'] ?? 0.0
      ];
    }).toList();

    return {
      'type': 'Feature',
      'geometry': {
        'type': 'MultiLineString',
        'coordinates': [
          coordinates
        ]
      },
      'properties': {
        'id': localData['id'],
        'communes_rurales_id': localData['commune_rurales'],
        'x_debut_ch': localData['x_debut_chaussee'],
        'y_debut_ch': localData['y_debut_chaussee'],
        'x_fin_ch': localData['x_fin_chaussee'],
        'y_fin_chau': localData['y_fin_chaussee'],
        'type_chaus': localData['type_chaussee'],
        'etat_piste': localData['etat_piste'],
        'created_at': _formatDateTime(localData['created_at']),
        'updated_at': _formatDateTime(localData['updated_at']),
        'code_gps': localData['code_gps'],
        'endroit': localData['endroit'],
        'code_piste': localData['code_piste'],
        'login': localData['login_id'],
      }
    };
  }

  Future<void> _syncTable(String tableName, String apiEndpoint, SyncResult result, {Function(int, int)? onProgress}) async {
    try {
      print('🔄 Synchronisation de $tableName...');

      // 1. Récupérer UNIQUEMENT les données non synchronisées ET non téléchargées
      List<Map<String, dynamic>> localData;
      if (tableName == 'pistes') {
        final storageHelper = SimpleStorageHelper();
        localData = await storageHelper.getUnsyncedPistes();
      } else if (tableName == 'chaussees') {
        final storageHelper = SimpleStorageHelper();
        localData = await storageHelper.getUnsyncedChaussees();
      } else {
        localData = await dbHelper.getUnsyncedEntities(tableName);
      }

      if (localData.isEmpty) {
        print('ℹ️ Aucune donnée à synchroniser pour $tableName');
        return;
      }

      print('📊 ${localData.length} enregistrement(s) à synchroniser pour $tableName');

      // 2. FILTRE SUPPLÉMENTAIRE : vérifier le code_piste
      for (var i = 0; i < localData.length; i++) {
        var data = localData[i];

        Map<String, dynamic> dataToSend;
        if (tableName == 'pistes') {
          dataToSend = _mapPisteToApi(data);
        } else if (tableName == 'chaussees') {
          // ⭐⭐ NOUVEAU
          dataToSend = _mapChausseeToApi(data);
        } else {
          dataToSend = data; // Ancienne logique pour les autres tables
        }

        // ⭐⭐ VÉRIFICATION CRITIQUE : code_piste ne doit pas être "Non spécifié"
        final codePiste = dataToSend['code_piste']?.toString().trim() ?? dataToSend['properties']?['code_piste']?.toString().trim();

        if (codePiste == null || codePiste.isEmpty || codePiste == 'Non spécifié' || codePiste == 'Non spÃ©cifiÃ©') {
          print('⏭️ Skipping ${tableName} ID ${data['id']} - code_piste invalide: "$codePiste"');
          result.failedCount++;
          result.errors.add('$tableName ID ${data['id']}: code_piste invalide');
          continue;
        }

        // 3. Envoyer seulement si code_piste est valide
        final success = await _sendDataToApi(apiEndpoint, dataToSend);

        if (success) {
          if (tableName == 'pistes') {
            final storageHelper = SimpleStorageHelper();
            await storageHelper.markPisteAsSynced(data['id']);
          } else if (tableName == 'chaussees') {
            final storageHelper = SimpleStorageHelper();

            await storageHelper.markChausseeAsSynced(data['id']);
          } else {
            await dbHelper.markAsSynced(tableName, data['id']);
          }
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

  Map<String, dynamic> _mapPisteToApi(Map<String, dynamic> localData) {
    print('🔄 Début mapping piste - Données reçues:');
    localData.forEach((key, value) {
      if (key != 'points_json') {
        print('   $key: $value (type: ${value?.runtimeType})');
      }
    });

    // ⭐⭐ CORRECTION: Vérifier que les données ne sont pas null
    if (localData['code_piste'] == null) {
      print('❌ ERREUR CRITIQUE: code_piste est null! Abandon du mapping.');
      return {
        'type': 'Feature',
        'geometry': {
          'type': 'MultiLineString',
          'coordinates': []
        },
        'properties': {}
      };
    }

    // Convertir les points JSON
    List<dynamic> points = [];
    try {
      final pointsJson = localData['points_json'];
      if (pointsJson is String) {
        points = jsonDecode(pointsJson);
        print('✅ Points JSON décodés: ${points.length} points');
      } else {
        print('❌ points_json n\'est pas une String: ${pointsJson.runtimeType}');
      }
    } catch (e) {
      print('❌ Erreur décodage points JSON: $e');
    }

    // Convertir en format GeoJSON coordinates
    final coordinates = points.map((point) {
      return [
        point['longitude'] ?? point['lng'] ?? 0.0,
        point['latitude'] ?? point['lat'] ?? 0.0
      ];
    }).toList();

    // ⭐⭐ CORRECTION: Utiliser des valeurs par défaut pour éviter les null
    return {
      'type': 'Feature',
      'geometry': {
        'type': 'MultiLineString',
        'coordinates': [
          coordinates
        ]
      },
      'properties': {
        'sqlite_id': localData['id'],
        'code_piste': localData['code_piste'] ?? 'INCONNU_${DateTime.now().millisecondsSinceEpoch}',
        'communes_rurales_id': localData['commune_rurales'],
        'heure_debut': localData['heure_debut'] ?? '',
        'heure_fin': localData['heure_fin'] ?? '',
        'nom_origine_piste': localData['nom_origine_piste'] ?? '',
        'x_origine': _parseDouble(localData['x_origine']) ?? 0.0,
        'y_origine': _parseDouble(localData['y_origine']) ?? 0.0,
        'nom_destination_piste': localData['nom_destination_piste'] ?? '',
        'x_destination': _parseDouble(localData['x_destination']) ?? 0.0,
        'y_destination': _parseDouble(localData['y_destination']) ?? 0.0,
        'existence_intersection': _parseInt(localData['existence_intersection']) ?? 0,
        'x_intersection': _parseDouble(localData['x_intersection']),
        'y_intersection': _parseDouble(localData['y_intersection']),
        'intersection_piste_code': localData['intersection_piste_code'],
        'type_occupation': localData['type_occupation'],
        'debut_occupation': _formatDateTime(localData['debut_occupation']),
        'fin_occupation': _formatDateTime(localData['fin_occupation']),
        'largeur_emprise': _parseDouble(localData['largeur_emprise']),
        'frequence_trafic': localData['frequence_trafic'],
        'type_trafic': localData['type_trafic'],
        'travaux_realises': localData['travaux_realises'],
        'date_travaux': localData['date_travaux'],
        'entreprise': localData['entreprise'],
        'created_at': _formatDateTime(localData['created_at']) ?? _formatDateTime(DateTime.now()),
        'updated_at': _formatDateTime(localData['updated_at']),
        'login_id': _parseInt(localData['login_id']) ?? _parseInt(localData['login']),
      }
    };
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.tryParse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.tryParse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  String? _formatDateTime(dynamic dateValue) {
    if (dateValue == null) return null;

    try {
      DateTime date;

      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return null;
      }

      // ⭐⭐ NOUVEAU FORMAT POUR POSTGRESQL ⭐⭐
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    } catch (e) {
      print('❌ Erreur formatage date: $e');
      return null;
    }
  }

  Future<bool> syncPiste(Map<String, dynamic> rawData) async {
    try {
      // ⭐⭐ SIMPLE ET PROPRE COMME syncChaussee
      print('🔄 Synchronisation piste ID: ${rawData['id']}');

      // Vérification minimale
      if (rawData['code_piste'] == null) {
        print('⏭️ Piste ignorée: code_piste manquant');
        return false;
      }

      // Mapping vers format API
      final apiData = _mapPisteToApi(rawData);

      // Envoi à l'API
      return await ApiService.postData('pistes', apiData);
    } catch (e) {
      print('❌ Erreur syncPiste: $e');
      return false;
    }
  }

  // Ajoutez cette méthode pour la synchronisation séquentielle
  Future<SyncResult> syncAllDataSequential({Function(double, String, int, int)? onProgress}) async {
    final result = SyncResult();
    int totalItems = 0;
    int processedItems = 0;
    int safeTotalItems = 1; // ← DÉCLARER ICI en dehors du try/catch

    try {
      // === ÉTAPE 1: COMPTER LE TOTAL ===
      final storageHelper = SimpleStorageHelper();
      final pisteCount = await storageHelper.getUnsyncedPistesCount();
      final chausseeCount = await storageHelper.getUnsyncedChausseesCount();

      // Compter les autres tables
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

      totalItems += pisteCount + chausseeCount;
      safeTotalItems = totalItems > 0 ? totalItems : 1; // ← MODIFIER ICI (pas de déclaration)

      // === ÉTAPE 2: SYNCHRONISATION DES PISTES (PREMIÈRE) ===
      if (onProgress != null) {
        onProgress(0.0, "🚀 Démarrage synchronisation des PISTES...", 0, safeTotalItems);
      }

      if (pisteCount > 0) {
        await _syncTableSequential('pistes', 'pistes', result, onProgress: (current, total) {
          double progress = safeTotalItems > 0 ? (current / total * pisteCount / safeTotalItems) : 0;
          progress = progress.clamp(0.0, 1.0);
          if (onProgress != null) {
            onProgress(progress, "📤 Envoi des pistes... ($current/$total)", current, total);
          }
        }, onComplete: (successCount) {
          processedItems += successCount;
          if (onProgress != null) {
            onProgress(processedItems / safeTotalItems, "✅ Pistes synchronisées!", processedItems, safeTotalItems);
          }
        });
      } else {
        if (onProgress != null) {
          onProgress(0.0, "✅ Aucune piste à synchroniser", 0, safeTotalItems);
        }
        await Future.delayed(Duration(seconds: 1));
      }

      // === ÉTAPE 3: CONFIRMATION PISTES TERMINÉES ===
      if (onProgress != null) {
        onProgress(processedItems / safeTotalItems, "🎯 Pistes synchronisées! Début chaussées...", processedItems, safeTotalItems);
      }
      await Future.delayed(Duration(seconds: 2));

      // === ÉTAPE 4: SYNCHRONISATION DES CHAUSSÉES (DEUXIÈME) ===
      if (chausseeCount > 0) {
        await _syncTableSequential('chaussees', 'chaussees_test', result, onProgress: (current, total) {
          double progress = safeTotalItems > 0 ? (processedItems + (current / total * chausseeCount)) / safeTotalItems : 0;
          progress = progress.clamp(0.0, 1.0);
          if (onProgress != null) {
            onProgress(progress, "📤 Envoi des chaussées... ($current/$total)", processedItems + current, safeTotalItems);
          }
        }, onComplete: (successCount) {
          processedItems += successCount;
          if (onProgress != null) {
            onProgress(processedItems / safeTotalItems, "✅ Chaussées synchronisées!", processedItems, safeTotalItems);
          }
        });
      } else {
        if (onProgress != null) {
          onProgress(processedItems / safeTotalItems, "✅ Aucune chaussée à synchroniser", processedItems, safeTotalItems);
        }
        await Future.delayed(Duration(seconds: 1));
      }

      // === ÉTAPE 5: CONFIRMATION CHAUSSÉES TERMINÉES ===
      if (onProgress != null) {
        onProgress(processedItems / safeTotalItems, "🎯 Chaussées synchronisées! Début autres données...", processedItems, safeTotalItems);
      }
      await Future.delayed(Duration(seconds: 2));

      // === ÉTAPE 6: SYNCHRONISATION DES AUTRES DONNÉES (TROISIÈME) ===
      for (var i = 0; i < tables.length; i++) {
        final table = tables[i];
        final tableData = await dbHelper.getUnsyncedEntities(table);
        final tableCount = tableData.length;

        if (tableCount > 0) {
          await _syncTableSequential(table, table, result, onProgress: (current, total) {
            double progress = safeTotalItems > 0 ? (processedItems + (current / total * tableCount)) / safeTotalItems : 0;
            progress = progress.clamp(0.0, 1.0);
            if (onProgress != null) {
              onProgress(progress, "📤 Envoi des ${_getFrenchTableName(table)}... ($current/$total)", processedItems + current, safeTotalItems);
            }
          }, onComplete: (successCount) {
            processedItems += successCount;
            if (onProgress != null) {
              onProgress(processedItems / safeTotalItems, "✅ ${_getFrenchTableName(table)} synchronisés!", processedItems, safeTotalItems);
            }
          });
        }
      }

      // === SYNCHRONISATION TERMINÉE ===
      if (onProgress != null) {
        onProgress(1.0, "🎉 Synchronisation terminée avec succès!", processedItems, safeTotalItems);
      }
    } catch (e) {
      result.errors.add('Erreur synchronisation séquentielle: $e');
      print('❌ Erreur synchronisation séquentielle: $e');
      if (onProgress != null) {
        onProgress(1.0, "❌ Erreur lors de la synchronisation", processedItems, safeTotalItems);
      }
    }

    return result;
  }

// Nouvelle méthode pour la synchronisation séquentielle
  Future<void> _syncTableSequential(String tableName, String apiEndpoint, SyncResult result, {Function(int, int)? onProgress, Function(int)? onComplete}) async {
    try {
      List<Map<String, dynamic>> localData;

      if (tableName == 'pistes') {
        final storageHelper = SimpleStorageHelper();
        localData = await storageHelper.getUnsyncedPistes();
      } else if (tableName == 'chaussees') {
        final storageHelper = SimpleStorageHelper();
        localData = await storageHelper.getUnsyncedChaussees();
      } else {
        localData = await dbHelper.getUnsyncedEntities(tableName);
      }

      if (localData.isEmpty) {
        if (onComplete != null) onComplete(0);
        return;
      }

      int successCount = 0;

      for (var i = 0; i < localData.length; i++) {
        var data = localData[i];

        bool success;

        // ⭐⭐ UTILISER LA MÊME MÉTHODE QUE POUR LES CHAUSSÉES
        if (tableName == 'pistes') {
          success = await syncPiste(data); // Comme pour syncChaussee(data)
        } else if (tableName == 'chaussees') {
          success = await syncChaussee(data);
        } else {
          success = await _sendDataToApi(apiEndpoint, data);
        }

        if (success) {
          if (tableName == 'pistes') {
            final storageHelper = SimpleStorageHelper();
            await storageHelper.markPisteAsSynced(data['id']);
          } else if (tableName == 'chaussees') {
            final storageHelper = SimpleStorageHelper();
            await storageHelper.markChausseeAsSynced(data['id']);
          } else {
            await dbHelper.markAsSynced(tableName, data['id']);
          }
          successCount++;
          result.successCount++;
          print('✅ $tableName ID ${data['id']} synchronisé');
        } else {
          result.failedCount++;
          result.errors.add('Échec synchronisation $tableName ID ${data['id']}');
          print('❌ Échec synchronisation $tableName ID ${data['id']}');
        }

        if (onProgress != null) {
          onProgress(i + 1, localData.length);
        }

        await Future.delayed(Duration(milliseconds: 100));
      }

      if (onComplete != null) onComplete(successCount);
    } catch (e) {
      result.errors.add('$tableName: $e');
      print('❌ Erreur synchronisation $tableName: $e');
      if (onComplete != null) onComplete(0);
    }
  }

  Future<bool> _sendDataToApi(String endpoint, Map<String, dynamic> data) async {
    switch (endpoint) {
      case 'pistes':
        return await syncPiste(data);
      case 'chaussees':
        return await syncChaussee(data);
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
      print('📍 Téléchargement pour commune_id: ${ApiService.communeId}');

      if (ApiService.communeId == null) {
        throw Exception('Commune ID non défini - impossible de télécharger les données');
      }

      if (onProgress != null) {
        onProgress(0.0, "Démarrage du téléchargement...", 0, 1);
      }
      print('⬇️ Début du téléchargement des données...');

      // Compter le nombre total d'éléments à télécharger
      final operations = [
        ApiService.fetchPistes,
        ApiService.fetchChausseesTest,
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

      //================ CHAUSSÉES ======================
      if (onProgress != null) {
        onProgress(processedItems / totalItems, "Téléchargement des chaussées...", processedItems, totalItems);
      }

      print('📥 Téléchargement des chaussées...');
      final chaussees = await ApiService.fetchChausseesTest();
      print('🛣️ ${chaussees.length} chaussées à traiter');

      for (var chaussee in chaussees) {
        // Vérifier que la chaussée appartient à la bonne commune
        final properties = chaussee['properties'];
        if (properties['communes_rurales_id'] == ApiService.communeId) {
          final storageHelper = SimpleStorageHelper();
          await storageHelper.saveOrUpdateChausseeTest(chaussee);
          result.successCount++;
          processedItems++;
          print('✅ Chaussée sauvegardée: ${properties['code_piste']}');
        } else {
          print('⏭️ Chaussée ignorée - commune_id différent: ${properties['commune_id']} vs ${ApiService.communeId}');
        }

        if (onProgress != null) {
          onProgress(processedItems / totalItems, "Sauvegarde des chaussées...", processedItems, totalItems);
        }
      }

      // ============ LOCALITES ============
      if (onProgress != null) {
        onProgress(processedItems / totalItems, "Téléchargement des localités...", processedItems, totalItems);
      }
      print('📥 Téléchargement des localités...');
      final localites = await ApiService.fetchLocalites();
      print('📍 ${localites.length} localités à traiter');
      for (var localite in localites) {
        final properties = localite['properties'];
        if (properties['commune_id'] == ApiService.communeId) {
          await dbHelper.saveOrUpdateLocalite(localite);
          result.successCount++;
          processedItems++;
          print('✅ Localité sauvegardée: ${properties['nom']}');
        } else {
          print('⏭️ Localité ignorée - commune_id différent: ${properties['commune_id']} vs ${ApiService.communeId}');
        }

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
        final properties = ecole['properties'];
        if (properties['commune_id'] == ApiService.communeId) {
          await dbHelper.saveOrUpdateEcole(ecole);
          result.successCount++;
          processedItems++;
          print('✅ École sauvegardée: ${properties['nom']}');
        } else {
          print('⏭️ École ignorée - commune_id différent: ${properties['commune_id']} vs ${ApiService.communeId}');
        }

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
        final properties = marche['properties'];
        if (properties['commune_id'] == ApiService.communeId) {
          await dbHelper.saveOrUpdateMarche(marche);
          result.successCount++;
          processedItems++;
          print('✅ Marché sauvegardé: ${properties['nom']}');
        } else {
          print('⏭️ Marché ignoré - commune_id différent: ${properties['commune_id']} vs ${ApiService.communeId}');
        }

        if (onProgress != null) {
          onProgress(processedItems / totalItems, "Sauvegarde des marchés...", processedItems, totalItems);
        }
      }

      // ============ SERVICES SANTES ============
      if (onProgress != null) {
        onProgress(processedItems / totalItems, "Téléchargement des services de santé...", processedItems, totalItems);
      }
      print('📥 Téléchargement des services de santé...');
      final servicesSantes = await ApiService.fetchServicesSantes();
      print('🏥 ${servicesSantes.length} services de santé à traiter');
      for (var service in servicesSantes) {
        final properties = service['properties'];
        if (properties['commune_id'] == ApiService.communeId) {
          await dbHelper.saveOrUpdateServiceSante(service);
          result.successCount++;
          processedItems++;
          print('✅ Service de santé sauvegardé: ${properties['nom']}');
        } else {
          print('⏭️ Service de santé ignoré - commune_id différent: ${properties['commune_id']} vs ${ApiService.communeId}');
        }

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
        final properties = batiment['properties'];
        if (properties['commune_id'] == ApiService.communeId) {
          await dbHelper.saveOrUpdateBatimentAdministratif(batiment);
          result.successCount++;
          processedItems++;
          print('✅ Bâtiment administratif sauvegardé: ${properties['nom']}');
        } else {
          print('⏭️ Bâtiment administratif ignoré - commune_id différent: ${properties['commune_id']} vs ${ApiService.communeId}');
        }

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
        final properties = infrastructure['properties'];
        if (properties['commune_id'] == ApiService.communeId) {
          await dbHelper.saveOrUpdateInfrastructureHydraulique(infrastructure);
          result.successCount++;
          processedItems++;
          print('✅ Infrastructure hydraulique sauvegardée: ${properties['nom']}');
        } else {
          print('⏭️ Infrastructure hydraulique ignorée - commune_id différent: ${properties['commune_id']} vs ${ApiService.communeId}');
        }

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
        final properties = infrastructure['properties'];
        if (properties['commune_id'] == ApiService.communeId) {
          await dbHelper.saveOrUpdateAutreInfrastructure(infrastructure);
          result.successCount++;
          processedItems++;
          print('✅ Autre infrastructure sauvegardée: ${properties['nom']}');
        } else {
          print('⏭️ Autre infrastructure ignorée - commune_id différent: ${properties['commune_id']} vs ${ApiService.communeId}');
        }

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
        final properties = pont['properties'];
        if (properties['commune_id'] == ApiService.communeId) {
          await dbHelper.saveOrUpdatePont(pont);
          result.successCount++;
          processedItems++;
          print('✅ Pont sauvegardé: ${properties['nom']}');
        } else {
          print('⏭️ Pont ignoré - commune_id différent: ${properties['commune_id']} vs ${ApiService.communeId}');
        }

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
        final properties = bac['properties'];
        if (properties['commune_id'] == ApiService.communeId) {
          await dbHelper.saveOrUpdateBac(bac);
          result.successCount++;
          processedItems++;
          print('✅ Bac sauvegardé: ${properties['nom']}');
        } else {
          print('⏭️ Bac ignoré - commune_id différent: ${properties['commune_id']} vs ${ApiService.communeId}');
        }

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
        final properties = buse['properties'];
        if (properties['commune_id'] == ApiService.communeId) {
          await dbHelper.saveOrUpdateBuse(buse);
          result.successCount++;
          processedItems++;
          print('✅ Buse sauvegardée: ${properties['nom']}');
        } else {
          print('⏭️ Buse ignorée - commune_id différent: ${properties['commune_id']} vs ${ApiService.communeId}');
        }

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
        final properties = dalot['properties'];
        if (properties['commune_id'] == ApiService.communeId) {
          await dbHelper.saveOrUpdateDalot(dalot);
          result.successCount++;
          processedItems++;
          print('✅ Dalot sauvegardé: ${properties['nom']}');
        } else {
          print('⏭️ Dalot ignoré - commune_id différent: ${properties['commune_id']} vs ${ApiService.communeId}');
        }

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
        final properties = passage['properties'];
        if (properties['commune_id'] == ApiService.communeId) {
          await dbHelper.saveOrUpdatePassageSubmersible(passage);
          result.successCount++;
          processedItems++;
          print('✅ Passage submersible sauvegardé: ${properties['nom']}');
        } else {
          print('⏭️ Passage submersible ignoré - commune_id différent: ${properties['commune_id']} vs ${ApiService.communeId}');
        }

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
        final properties = point['properties'];
        if (properties['commune_id'] == ApiService.communeId) {
          await dbHelper.saveOrUpdatePointCritique(point);
          result.successCount++;
          processedItems++;
          print('✅ Point critique sauvegardé');
        } else {
          print('⏭️ Point critique ignoré - commune_id différent: ${properties['commune_id']} vs ${ApiService.communeId}');
        }

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
        final properties = point['properties'];
        if (properties['commune_id'] == ApiService.communeId) {
          await dbHelper.saveOrUpdatePointCoupure(point);
          result.successCount++;
          processedItems++;
          print('✅ Point de coupure sauvegardé');
        } else {
          print('⏭️ Point de coupure ignoré - commune_id différent: ${properties['commune_id']} vs ${ApiService.communeId}');
        }

        if (onProgress != null) {
          onProgress(processedItems / totalItems, "Sauvegarde des points de coupure...", processedItems, totalItems);
        }
      }

      // ============ PISTES ============
      if (onProgress != null) {
        onProgress(processedItems / totalItems, "Téléchargement des pistes...", processedItems, totalItems);
      }
      print('📥 Téléchargement des pistes...');
      final pistes = await ApiService.fetchPistes();
      print('🛤️ ${pistes.length} pistes à traiter');
      for (var piste in pistes) {
        final properties = piste['properties'];
        if (properties['communes_rurales_id'] == ApiService.communeId) {
          final storageHelper = SimpleStorageHelper();
          await storageHelper.saveOrUpdatePiste(piste);
          result.successCount++;
          processedItems++;
          print('✅ Piste sauvegardée: ${properties['code_piste']}');
        } else {
          print('⏭️ Piste ignorée - commune_id différent: ${properties['communes_rurales_id']} vs ${ApiService.communeId}');
        }

        if (onProgress != null) {
          onProgress(processedItems / totalItems, "Sauvegarde des pistes...", processedItems, totalItems);
        }
      }

      print('✅ Téléchargement terminé: ${result.successCount} données traitées sur $totalItems disponibles');
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
