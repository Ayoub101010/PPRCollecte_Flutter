import 'package:flutter/material.dart';
import 'config.dart';
import 'category_selector_widget.dart';
import 'type_selector_widget.dart';
import 'database_helper.dart';
import 'point_form_widget.dart';
import 'data_list_view.dart';
import 'piste_chaussee_db_helper.dart';
import 'dart:convert'; // Pour jsonDecode
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Pour LatLng
import 'formulaire_ligne_page.dart'; // Pour FormulaireLignePage
import 'formulaire_chaussee_page.dart';
import 'api_service.dart';
import 'home_page.dart';
import 'login_page.dart';

class DataCategoriesDisplay extends StatefulWidget {
  final String mainCategory;
  final String dataFilter; // "unsynced", "synced", "saved"
  const DataCategoriesDisplay({
    super.key,
    required this.mainCategory,
    required this.dataFilter,
  });

  @override
  State<DataCategoriesDisplay> createState() => _DataCategoriesDisplayState();
}

class _DataCategoriesDisplayState extends State<DataCategoriesDisplay> {
  String? selectedCategory;
  String? selectedType;
  List<Map<String, dynamic>> currentData = [];

  @override
  void initState() {
    super.initState();

    // POUR TOUTES LES CATÉGORIES: définir selectedCategory
    selectedCategory = widget.mainCategory;

    // UNIQUEMENT pour Pistes/Chaussées: définir aussi selectedType
    if (widget.mainCategory == "Pistes" || widget.mainCategory == "Chaussées") {
      selectedType = widget.mainCategory;
      // Charger les données après un petit délai
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchData();
        }
      });
    }
  }

  double? _toDoubleStrict(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim().replaceAll(',', '.'));
    return null;
  }

  bool _isLat(double v) => v >= -90 && v <= 90;
  bool _isLng(double v) => v >= -180 && v <= 180;

  /// Valide une paire et corrige si inversion possible
  LatLng? _validateAndFix(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    if (_isLat(lat) && _isLng(lng)) return LatLng(lat, lng);
    if (_isLat(lng) && _isLng(lat)) return LatLng(lng, lat); // x/y inversés
    return null;
  }

  /// WKT: "POINT(lon lat)"
  // parse WKT "POINT(lon lat)"
  LatLng? _parseWktPoint(String wkt) {
    final m = RegExp(r'POINT\s*\(\s*([-\d\.,]+)\s+([-\d\.,]+)\s*\)', caseSensitive: false).firstMatch(wkt);
    if (m == null) return null;
    final lon = double.tryParse(m.group(1)!.replaceAll(',', '.'));
    final lat = double.tryParse(m.group(2)!.replaceAll(',', '.'));
    if (lat == null || lon == null) return null;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
    return LatLng(lat, lon);
  }

// GeoJSON {"type":"Point","coordinates":[lon,lat]}
  LatLng? _parseGeoJsonPoint(dynamic geo) {
    try {
      final obj = (geo is String) ? jsonDecode(geo) : geo;
      if (obj is Map && obj['type']?.toString().toLowerCase() == 'point') {
        final c = obj['coordinates'];
        if (c is List && c.length >= 2) {
          final lon = (c[0] is String) ? double.tryParse(c[0].replaceAll(',', '.')) : (c[0] as num).toDouble();
          final lat = (c[1] is String) ? double.tryParse(c[1].replaceAll(',', '.')) : (c[1] as num).toDouble();
          if (lat == null || lon == null) return null;
          if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
          return LatLng(lat, lon);
        }
      }
    } catch (_) {}
    return null;
  }

// essaie d'extraire lat/lng dans *ce row seulement*
  LatLng? _extractPointFromRow(Map<String, dynamic> row) {
    final r = <String, dynamic>{};
    row.forEach((k, v) => r[k.toString().toLowerCase()] = v);

    // 1) WKT / GeoJSON
    for (final k in [
      'wkt',
      'geom_wkt',
      'geometry',
      'geom'
    ]) {
      final v = r[k];
      if (v is String && v.toUpperCase().contains('POINT')) {
        final pt = _parseWktPoint(v);
        if (pt != null) return pt;
      }
    }
    for (final k in [
      'geojson',
      'geom_geojson',
      'point_geojson'
    ]) {
      final pt = _parseGeoJsonPoint(r[k]);
      if (pt != null) return pt;
    }

    // 2) Paires évidentes, en respectant x=lon, y=lat
    final pairs = <List<String>>[
      [
        'longitude',
        'latitude'
      ],
      [
        'lng',
        'lat'
      ],
      [
        'x',
        'y'
      ],
      [
        'lng_debut',
        'lat_debut'
      ],
      [
        'x_debut',
        'y_debut'
      ],
      // variantes fréquentes par familles (sans “catégoriser” : on checke juste si les clés existent)
      [
        'lng_ecole',
        'lat_ecole'
      ],
      [
        'x_ecole',
        'y_ecole'
      ],
      [
        'lng_localite',
        'lat_localite'
      ],
      [
        'x_localite',
        'y_localite'
      ],
      [
        'lng_pont',
        'lat_pont'
      ],
      [
        'x_pont',
        'y_pont'
      ],
      [
        'lng_point',
        'lat_point'
      ],
      [
        'x_point',
        'y_point'
      ],
      [
        'lng_bat',
        'lat_bat'
      ],
      [
        'lng_sante',
        'lat_sante'
      ],
      [
        'lng_marche',
        'lat_marche'
      ],
      [
        'lng_hydro',
        'lat_hydro'
      ],
      [
        'lng_coupure',
        'lat_coupure'
      ],
    ];
    for (final p in pairs) {
      final lng = r.containsKey(p[0]) ? r[p[0]] : null;
      final lat = r.containsKey(p[1]) ? r[p[1]] : null;
      if (lng == null || lat == null) continue;
      final lon = (lng is String) ? double.tryParse(lng.replaceAll(',', '.')) : (lng is num ? lng.toDouble() : null);
      final la = (lat is String) ? double.tryParse(lat.replaceAll(',', '.')) : (lat is num ? lat.toDouble() : null);
      if (la == null || lon == null) continue;
      if (la >= -90 && la <= 90 && lon >= -180 && lon <= 180) return LatLng(la, lon);
      // inversion si on se trompe
      if (lon >= -90 && lon <= 90 && la >= -180 && la <= 180) return LatLng(lon, la);
    }

    // 3) Heuristique finale : mappage regex d’une clé lat-like et lng-like dans CE row
    String? latKey, lngKey;
    for (final k in r.keys) {
      if (latKey == null && (k.contains('latitude') || RegExp(r'(^|_)(lat|y)(_|$)').hasMatch(k))) {
        latKey = k;
      }
      if (lngKey == null && (k.contains('longitude') || k.contains('lon') || RegExp(r'(^|_)(lng|x|long)(_|$)').hasMatch(k))) {
        lngKey = k;
      }
      if (latKey != null && lngKey != null) break;
    }
    if (latKey != null && lngKey != null) {
      final lat = (r[latKey] is String) ? double.tryParse((r[latKey] as String).replaceAll(',', '.')) : (r[latKey] as num?)?.toDouble();
      final lng = (r[lngKey] is String) ? double.tryParse((r[lngKey] as String).replaceAll(',', '.')) : (r[lngKey] as num?)?.toDouble();
      if (lat != null && lng != null) {
        if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) return LatLng(lat, lng);
        if (lng >= -90 && lng <= 90 && lat >= -180 && lat <= 180) return LatLng(lng, lat);
      }
    }

    return null;
  }

  List<LatLng>? _extractPolyline(Map<String, dynamic> item) {
    // Supporte: 'points_collectes' = List<Map>{latitude, longitude}
    // ou 'points_json' (string JSON)
    if (item['points_collectes'] is List) {
      final list = (item['points_collectes'] as List).whereType<Map>().map((p) => LatLng((p['latitude'] as num).toDouble(), (p['longitude'] as num).toDouble())).toList();
      if (list.isNotEmpty) return list;
    }
    if (item['points_json'] is String) {
      try {
        final raw = jsonDecode(item['points_json']);
        if (raw is List) {
          final list = raw.whereType<Map>().map((p) => LatLng((p['latitude'] as num).toDouble(), (p['longitude'] as num).toDouble())).toList();
          if (list.isNotEmpty) return list;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> _goToMapForItem(Map<String, dynamic> item) async {
    // 1) Construire la cible
    MapFocusTarget? target;

    // Types lignes: "Pistes" / "Chaussées" / (special: bacs/passages si tu les listes ici)
    final poly = _extractPolyline(item);
    if (poly != null && poly.isNotEmpty) {
      target = MapFocusTarget.polyline(
        polyline: poly,
        label: (item['nom'] ?? item['line_name'] ?? item['name'] ?? '').toString(),
        id: item['id']?.toString(),
      );
    } else {
      // 2) Tenter le POINT *dans CE row seulement* :
      LatLng? pt = _extractPointFromRow(item);

      // 3) Si pas trouvé: RECHARGER CE ROW par id & table d’origine (si dispo)
      if (pt == null) {
        final id = item['id'] ?? item['ID'] ?? item['Id'];
        final table = item['table'] ?? item['source_table'] ?? item['original_table'];
        if (id != null && table != null) {
          final db = await DatabaseHelper().database;
          final res = await db.query(table.toString(),
              where: 'id = ?',
              whereArgs: [
                id
              ],
              limit: 1);
          if (res.isNotEmpty) {
            pt = _extractPointFromRow(res.first);
          }
        }
      }
      if (pt != null) {
        target = MapFocusTarget.point(
          point: pt,
          label: (item['nom'] ?? item['point_name'] ?? item['name'] ?? '').toString(),
          id: item['id']?.toString(),
        );
      }
    }

    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de localiser cette donnée (pas de géométrie).")),
      );
      return;
    }

    // 2) Récupérer le nom d’agent pour construire HomePage proprement
    final email = await DatabaseHelper().getCurrentUserEmail();
    final fullName = await DatabaseHelper().getAgentFullName(email ?? '') ?? 'Utilisateur';

    // 3) Aller sur la carte avec la cible
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(
          agentName: fullName,
          onLogout: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
          },
          initialFocus: target, // ⬅️ important
        ),
      ),
    );
  }

  void _onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
      selectedType = null;
      currentData = [];
    });
  }

  void _onTypeSelected(String type) {
    setState(() {
      selectedType = type;
      _fetchData();
    });
  }

  void _onBackToCategories() {
    // CAS SPÉCIAL: Pour Pistes/Chaussées, retour direct à l'écran précédent
    if (selectedCategory == "Pistes" || selectedCategory == "Chaussées") {
      Navigator.pop(context); // ← Retour direct sans refresh
    } else {
      // CAS NORMAL: Comportement existant pour autres catégories
      setState(() {
        selectedCategory = null;
        selectedType = null;
        currentData = [];
      });
    }
  }

  void _onBackToTypes() {
    // CAS SPÉCIAL: Pour Pistes/Chaussées, retour direct à l'écran précédent
    if (selectedCategory == "Pistes" || selectedCategory == "Chaussées") {
      Navigator.pop(context); // ← Retour direct sans refresh
    } else {
      // CAS NORMAL: Comportement existant pour autres catégories
      setState(() {
        selectedType = null;
        currentData = [];
      });
    }
  }

  void _showDataViewMessage(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Visualisation des données: $type'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _fetchData() async {
    if (selectedCategory == null) return;

    // ✅ Initialiser avec liste vide
    List<Map<String, dynamic>> filteredData = [];

    try {
      // CAS SPÉCIAL PISTES/CHAUSSÉES
      if (selectedCategory == "Pistes" || selectedCategory == "Chaussées") {
        final storageHelper = SimpleStorageHelper();

        if (selectedCategory == "Pistes") {
          List<Map<String, dynamic>> allPistes = await storageHelper.getAllPistesMaps();

          // FILTRAGE PISTES
          if (widget.dataFilter == "unsynced") {
            filteredData = allPistes.where((piste) => (piste['synced'] == 0 || piste['synced'] == null) && (piste['downloaded'] == 0 || piste['downloaded'] == null) && piste['login_id'] == ApiService.userId).toList();
          } else if (widget.dataFilter == "synced") {
            filteredData = allPistes.where((piste) => piste['synced'] == 1 && (piste['downloaded'] == 0 || piste['downloaded'] == null) && piste['login_id'] == ApiService.userId).toList();
          } else if (widget.dataFilter == "saved") {
            filteredData = allPistes.where((piste) => piste['downloaded'] == 1 && piste['saved_by_user_id'] == ApiService.userId).toList();
          } else {
            filteredData = allPistes;
          }

          print('📊 Pistes ${widget.dataFilter}: ${filteredData.length}');
        } else if (selectedCategory == "Chaussées") {
          List<Map<String, dynamic>> allChaussees = await storageHelper.getAllChausseesMaps();

          // FILTRAGE CHAUSSÉES
          if (widget.dataFilter == "unsynced") {
            filteredData = allChaussees.where((ch) => (ch['synced'] == 0 || ch['synced'] == null) && (ch['downloaded'] == 0 || ch['downloaded'] == null) && ch['login_id'] == ApiService.userId).toList();
          } else if (widget.dataFilter == "synced") {
            filteredData = allChaussees.where((ch) => ch['synced'] == 1 && (ch['downloaded'] == 0 || ch['downloaded'] == null) && ch['login_id'] == ApiService.userId).toList();
          } else if (widget.dataFilter == "saved") {
            filteredData = allChaussees.where((ch) => ch['downloaded'] == 1 && ch['saved_by_user_id'] == ApiService.userId).toList();
          } else {
            filteredData = allChaussees;
          }

          print('📊 Chaussées ${widget.dataFilter}: ${filteredData.length}');
        }
      }
      // ✅ CAS NORMAL - POINTS (LOGIQUE EXISTANTE)
      else {
        final dbHelper = DatabaseHelper();
        final config = InfrastructureConfig.getEntityConfig(selectedCategory!, selectedType!);
        final tableName = config?['tableName'] ?? '';

        if (tableName.isEmpty) {
          setState(() => currentData = []);
          return;
        }

        List<Map<String, dynamic>> allData = await dbHelper.getEntities(tableName);

        // FILTRAGE STANDARD POUR POINTS
        if (widget.dataFilter == "unsynced") {
          filteredData = allData.where((item) => (item['synced'] == 0 || item['synced'] == null) && (item['downloaded'] == 0 || item['downloaded'] == null) && item['login_id'] == ApiService.userId).toList();
        } else if (widget.dataFilter == "synced") {
          filteredData = allData.where((item) => item['synced'] == 1 && (item['downloaded'] == 0 || item['downloaded'] == null) && item['login_id'] == ApiService.userId).toList();
        } else if (widget.dataFilter == "saved") {
          filteredData = allData.where((item) => item['downloaded'] == 1 && item['saved_by_user_id'] == ApiService.userId).toList();
        } else {
          filteredData = allData;
        }
      }

      // ✅ METTRE À JOUR L'ÉTAT
      setState(() => currentData = filteredData);
    } catch (e) {
      print('❌ Erreur récupération ${selectedCategory}: $e');
      setState(() => currentData = []);
    }
  }

// Dans data_categories_display.dart
  Future<void> _editChaussee(Map<String, dynamic> chaussee) async {
    try {
      // Convertir les données SQLite vers format formulaire
      final formData = {
        'id': chaussee['id'], // ← IMPORTANT: Inclure l'ID
        'code_piste': chaussee['code_piste'],
        'code_gps': chaussee['code_gps'],
        'endroit': chaussee['endroit'],
        'type_chaussee': chaussee['type_chaussee'],
        'etat_piste': chaussee['etat_piste'],
        'user_login': chaussee['user_login'], // ← Utiliser user_login
        'x_debut_chaussee': chaussee['x_debut_chaussee'],
        'y_debut_chaussee': chaussee['y_debut_chaussee'],
        'x_fin_chaussee': chaussee['x_fin_chaussee'],
        'y_fin_chaussee': chaussee['y_fin_chaussee'],
        'points_collectes': jsonDecode(chaussee['points_json']),
        'distance_totale_m': chaussee['distance_totale_m'],
        'nombre_points': chaussee['nombre_points'],
        'created_at': chaussee['created_at'],
        'updated_at': chaussee['updated_at'],
        'is_editing': true, // ← Flag pour mode édition
      };

      // Convertir les points JSON en List<LatLng>
      final pointsList = (formData['points_collectes'] as List).map((p) => LatLng(p['latitude'], p['longitude'])).toList();

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FormulaireChausseePage(
            chausseePoints: pointsList,
            provisionalId: formData['id'],
            agentName: formData['user_login'], // ← Utiliser user_login
            initialData: formData,
            isEditingMode: true,
          ),
        ),
      );

      if (result != null) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chaussée modifiée avec succès')),
        );
      }
    } catch (e) {
      print('❌ Erreur édition chaussée: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la modification: $e')),
      );
    }
  }

  Future<void> _deleteChaussee(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette chaussée ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final storageHelper = SimpleStorageHelper();
        await storageHelper.deleteDisplayedChaussee(id);
        await storageHelper.deleteChaussee(id);
        _fetchData(); // Rafraîchir la liste

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chaussée supprimée avec succès')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }

  Future<void> _editItem(Map<String, dynamic> item) async {
    if (selectedCategory == "Pistes") {
      await _editPiste(item);
    } else if (selectedCategory == "Chaussées") {
      await _editChaussee(item);
    } else {
      final config = InfrastructureConfig.getEntityConfig(selectedCategory!, selectedType!);
      final tableName = config?['tableName'] ?? '';

      if (tableName.isEmpty) return;
      final String agentName = item['enqueteur'] ?? 'Agent';
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            // ✅ Ajout du Scaffold ici
            body: PointFormWidget(
              category: selectedCategory!,
              type: selectedType!,
              pointData: item, // ✅ Données à modifier
              onBack: () => Navigator.pop(context),
              onSaved: () {
                _fetchData();
                Navigator.pop(context);
              },
              agentName: agentName,
            ),
          ),
        ),
      );

      if (result != null) {
        _fetchData();
      }
    }
  }

  Future<void> _editPiste(Map<String, dynamic> piste) async {
    try {
      // Convertir les points JSON en List<LatLng>
      final pointsJson = piste['points_json'];
      List<LatLng> points = [];

      if (pointsJson != null && pointsJson is String) {
        try {
          final pointsData = jsonDecode(pointsJson) as List;
          points = pointsData.map((p) => LatLng(p['latitude'] ?? p['lat'] ?? 0.0, p['longitude'] ?? p['lng'] ?? 0.0)).toList();
        } catch (e) {
          print('❌ Erreur décodage points: $e');
        }
      }

      // Préparer les données pour le formulaire
      final formData = {
        'id': piste['id'],
        'code_piste': piste['code_piste'],
        'commune_rurale_id': piste['commune_rurale_id'],
        'user_login': piste['user_login'],
        'heure_debut': piste['heure_debut'],
        'heure_fin': piste['heure_fin'],
        'nom_origine_piste': piste['nom_origine_piste'],
        'x_origine': piste['x_origine'],
        'y_origine': piste['y_origine'],
        'nom_destination_piste': piste['nom_destination_piste'],
        'x_destination': piste['x_destination'],
        'y_destination': piste['y_destination'],
        'existence_intersection': piste['existence_intersection'],
        'x_intersection': piste['x_intersection'],
        'y_intersection': piste['y_intersection'],
        'intersection_piste_code': piste['intersection_piste_code'],
        'type_occupation': piste['type_occupation'],
        'debut_occupation': piste['debut_occupation'],
        'fin_occupation': piste['fin_occupation'],
        'largeur_emprise': piste['largeur_emprise'],
        'frequence_trafic': piste['frequence_trafic'],
        'type_trafic': piste['type_trafic'],
        'travaux_realises': piste['travaux_realises'],
        'date_travaux': piste['date_travaux'],
        'entreprise': piste['entreprise'],
        'points': points,
        'created_at': piste['created_at'],
        'updated_at': DateTime.now().toIso8601String(),
      };

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FormulaireLignePage(
            linePoints: points,
            provisionalCode: piste['code_piste'],
            startTime: piste['created_at'] != null ? DateTime.parse(piste['created_at']) : DateTime.now(),
            endTime: DateTime.now(),
            agentName: piste['user_login'] ?? 'Utilisateur',
            initialData: formData,
            isEditingMode: true,
          ),
        ),
      );

      if (result != null) {
        _fetchData(); // Rafraîchir la liste
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Piste modifiée avec succès')),
        );
      }
    } catch (e) {
      print('❌ Erreur édition piste: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la modification: $e')),
      );
    }
  }

  Future<void> _deletePiste(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette piste ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final storageHelper = SimpleStorageHelper();

        // 1. SUPPRIMER LA PISTE AFFICHÉE
        await storageHelper.deleteDisplayedPiste(id);

        // 2. SUPPRIMER LA PISTE PRINCIPALE
        await storageHelper.deletePiste(id);

        // 3. ⭐⭐ SIMPLEMENT RAFRAÎCHIR LES DONNÉES ⭐⭐
        _fetchData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Piste supprimée avec succès')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }

  Future<void> _deleteItem(int id) async {
    if (selectedCategory == "Pistes") {
      await _deletePiste(id);
    } else if (selectedCategory == "Chaussées") {
      await _deleteChaussee(id); // ← APPELER LA NOUVELLE MÉTHODE
    } else {
      final config = InfrastructureConfig.getEntityConfig(selectedCategory!, selectedType!);
      final tableName = config?['tableName'] ?? '';

      if (tableName.isEmpty) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text('Êtes-vous sûr de vouloir supprimer cet élément ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          final dbHelper = DatabaseHelper();
          await dbHelper.deleteDisplayedPoint(id, tableName);
          await dbHelper.deleteEntity(tableName, id);
          _fetchData(); // Rafraîchir la liste

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Élément supprimé avec succès')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: Text(
          '📊 ${widget.mainCategory}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: _getAppBarColor(),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildContent(),
    );
  }

  Color _getAppBarColor() {
    switch (widget.mainCategory) {
      case "Infrastructures Rurales":
        return const Color(0xFFFF9800);
      case "Ouvrages":
        return const Color(0xFF9C27B0);
      case "Points Critiques":
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF1976D2);
    }
  }

  Widget _buildContent() {
    // POUR TOUTES LES CATÉGORIES: même logique
    if (selectedType == null) {
      // Afficher le sélecteur de type
      return _buildTypeSelector();
    } else {
      // Afficher la liste des données
      return _buildDataView();
    }
  }

  Widget _buildTypeSelector() {
    // CAS SPÉCIAL: Pistes/Chaussées - afficher directement
    if (selectedCategory == "Pistes" || selectedCategory == "Chaussées") {
      return _buildDirectTypeView();
    }

    // CAS NORMAL: autres catégories - sélecteur normal
    return TypeSelectorWidget(
      category: selectedCategory!,
      onTypeSelected: _onTypeSelected,
      onBack: _onBackToCategories,
    );
  }

  Widget _buildDirectTypeView() {
    return Column(
      children: [
        // EN-TÊTE UNIFORME pour toutes les catégories
        Container(
          padding: const EdgeInsets.all(16),
          color: _getAppBarColor().withOpacity(0.1),
          child: Row(
            children: [
              // FLÈCHE DE RETOUR UNIFIÉE
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _onBackToCategories, // ← Même comportement partout
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedCategory!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // CONTENU SPÉCIFIQUE
        const Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Chargement des données...',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataView() {
    return Column(
      children: [
        // EN-TÊTE UNIFORME avec chemin de navigation
        Container(
          padding: const EdgeInsets.all(16),
          color: _getAppBarColor().withOpacity(0.1),
          child: Row(
            children: [
              // FLÈCHE DE RETOUR - COMPORTEMENT DIFFÉRENTIÉ
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // COMPORTEMENT DIFFÉRENTIÉ
                  if (selectedCategory == "Pistes" || selectedCategory == "Chaussées") {
                    Navigator.pop(context); // ← Retour direct pour pistes/chaussées
                  } else {
                    _onBackToTypes(); // ← Comportement normal pour autres
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedCategory == "Pistes" || selectedCategory == "Chaussées"
                      ? selectedCategory! // ← Juste le nom pour pistes/chaussées
                      : '$selectedCategory > $selectedType', // ← Chemin complet pour autres
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchData,
              ),
            ],
          ),
        ),

        // LISTE DES DONNÉES
        Expanded(
          child: DataListView(
            data: currentData,
            entityType: selectedType!,
            dataFilter: widget.dataFilter,
            onEdit: _editItem,
            onDelete: _deleteItem,
            onView: (item) => _goToMapForItem(item),
          ),
        ),
      ],
    );
  }
}
