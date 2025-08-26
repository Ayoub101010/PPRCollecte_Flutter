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
    // Définir automatiquement la catégorie en fonction de mainCategory
    selectedCategory = widget.mainCategory;
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
    setState(() {
      selectedCategory = null;
      selectedType = null;
      currentData = [];
    });
  }

  void _onBackToTypes() {
    setState(() {
      selectedType = null;
      currentData = [];
    });
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
        case "unsynced":
          filteredData = allData.where((item) => item['synced'] == 0 || item['synced'] == null).toList();
          break;
        case "synced":
          filteredData = allData.where((item) => item['synced'] == 1).toList();
          break;
        case "saved":
          filteredData = allData; // Pour les données sauvegardées, on montre tout
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
    if (selectedCategory == null) {
      return CategorySelectorWidget(
        onCategorySelected: _onCategorySelected,
      );
    } else if (selectedType == null) {
      return TypeSelectorWidget(
        category: selectedCategory!,
        onTypeSelected: _onTypeSelected,
        onBack: _onBackToCategories,
      );
    } else {
      return _buildDataView();
    }
  }

  Widget _buildDataView() {
    return Column(
      children: [
        // En-tête avec le type sélectionné
        Container(
          padding: const EdgeInsets.all(16),
          color: _getAppBarColor().withOpacity(0.1),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _onBackToTypes,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedType!,
                  style: const TextStyle(
                    fontSize: 18,
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

  Widget _buildTypeSelector() {
    return TypeSelectorWidget(
      category: selectedCategory!,
      onTypeSelected: _onTypeSelected,
      onBack: _onBackToCategories,
    );
  }
}
