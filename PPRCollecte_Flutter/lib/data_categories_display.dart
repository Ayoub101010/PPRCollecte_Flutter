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
            filteredData = allPistes.where((piste) => (piste['synced'] == 0 || piste['synced'] == null) && (piste['downloaded'] == 0 || piste['downloaded'] == null)).toList();
          } else if (widget.dataFilter == "synced") {
            filteredData = allPistes.where((piste) => piste['synced'] == 1 && (piste['downloaded'] == 0 || piste['downloaded'] == null)).toList();
          } else if (widget.dataFilter == "saved") {
            filteredData = allPistes.where((piste) => piste['downloaded'] == 1).toList();
          } else {
            filteredData = allPistes;
          }

          print('📊 Pistes ${widget.dataFilter}: ${filteredData.length}');
        } else if (selectedCategory == "Chaussées") {
          List<Map<String, dynamic>> allChaussees = await storageHelper.getAllChausseesMaps();

          // FILTRAGE CHAUSSÉES
          if (widget.dataFilter == "unsynced") {
            filteredData = allChaussees.where((ch) => (ch['synced'] == 0 || ch['synced'] == null) && (ch['downloaded'] == 0 || ch['downloaded'] == null)).toList();
          } else if (widget.dataFilter == "synced") {
            filteredData = allChaussees.where((ch) => ch['synced'] == 1 && (ch['downloaded'] == 0 || ch['downloaded'] == null)).toList();
          } else if (widget.dataFilter == "saved") {
            filteredData = allChaussees.where((ch) => ch['downloaded'] == 1).toList();
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
          filteredData = allData.where((item) => (item['synced'] == 0 || item['synced'] == null) && (item['downloaded'] == 0 || item['downloaded'] == null)).toList();
        } else if (widget.dataFilter == "synced") {
          filteredData = allData.where((item) => item['synced'] == 1 && (item['downloaded'] == 0 || item['downloaded'] == null)).toList();
        } else if (widget.dataFilter == "saved") {
          filteredData = allData.where((item) => item['downloaded'] == 1).toList();
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
      // Convertir les points JSON en List<LatLng>
      final pointsJson = chaussee['points_json'];
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
        'id': chaussee['id'],
        'code_piste': chaussee['code_piste'],
        'code_gps': chaussee['code_gps'],
        'endroit': chaussee['endroit'],
        'type_chaussee': chaussee['type_chaussee'],
        'etat_piste': chaussee['etat_piste'],
        'x_debut_chaussee': chaussee['x_debut_chaussee'],
        'y_debut_chaussee': chaussee['y_debut_chaussee'],
        'x_fin_chaussee': chaussee['x_fin_chaussee'],
        'y_fin_chaussee': chaussee['y_fin_chaussee'],
        'points': points,
        'distance_totale_m': chaussee['distance_totale_m'],
        'nombre_points': chaussee['nombre_points'],
        'created_at': chaussee['created_at'],
        'updated_at': DateTime.now().toIso8601String(),
        'user_login': chaussee['user_login'],
      };

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FormulaireChausseePage(
            chausseePoints: points,
            provisionalId: chaussee['id'],
            agentName: chaussee['user_login'] ?? 'Utilisateur',
            initialData: formData,
            isEditingMode: true,
          ),
        ),
      );

      if (result != null) {
        _fetchData(); // Rafraîchir la liste
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
        await storageHelper.deletePiste(id);
        _fetchData(); // Rafraîchir la liste

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
          ),
        ),
      ],
    );
  }
}
