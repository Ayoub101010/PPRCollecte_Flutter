import 'package:flutter/material.dart';
import 'config.dart';
import 'category_selector_widget.dart';
import 'type_selector_widget.dart';
import 'database_helper.dart';
import 'point_form_widget.dart';
import 'data_list_view.dart';

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
    if (selectedCategory == null || selectedType == null) return;

    final dbHelper = DatabaseHelper();
    final config = InfrastructureConfig.getEntityConfig(selectedCategory!, selectedType!);
    final tableName = config?['tableName'] ?? '';

    if (tableName.isEmpty) {
      setState(() => currentData = []);
      return;
    }

    try {
      // Récupérer toutes les données de la table
      List<Map<String, dynamic>> allData = await dbHelper.getEntities(tableName);

      // Filtrer selon le type de données
      List<Map<String, dynamic>> filteredData;
      switch (widget.dataFilter) {
        case "unsynced": // Données enregistrées
          filteredData = allData
              .where((item) => (item['synced'] == 0 || item['synced'] == null) && (item['downloaded'] == 0 || item['downloaded'] == null) // ← Non téléchargées
                  )
              .toList();
          break;
        case "synced": // Données synchronisées
          filteredData = allData
              .where((item) => item['synced'] == 1 && (item['downloaded'] == 0 || item['downloaded'] == null) // ← Créées par l'utilisateur
                  )
              .toList();
          break;
        case "saved": // Données sauvegardées
          filteredData = allData
              .where((item) => item['downloaded'] == 1 // ← Uniquement les données téléchargées
                  )
              .toList();
          break;
        default:
          filteredData = allData;
      }

      setState(() => currentData = filteredData);
    } catch (e) {
      print('Erreur lors de la récupération des données: $e');
      setState(() => currentData = []);
    }
  }

  Future<void> _editItem(Map<String, dynamic> item) async {
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

  Future<void> _deleteItem(int id) async {
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
