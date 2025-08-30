import 'package:flutter/material.dart';

class DataListView extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final String entityType;
  final String dataFilter;
  final Function(Map<String, dynamic>) onEdit;
  final Function(int) onDelete;

  const DataListView({
    super.key,
    required this.data,
    required this.entityType,
    required this.dataFilter,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<DataListView> createState() => _DataListViewState();
}

class _DataListViewState extends State<DataListView> {
  late List<Map<String, dynamic>> _filteredData;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredData = widget.data;
    _searchController.addListener(_filterData);
  }

  @override
  void didUpdateWidget(DataListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _filterData();
    }
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() => _filteredData = widget.data);
    } else {
      setState(() {
        _filteredData = widget.data.where((item) {
          final nom = item['nom']?.toString().toLowerCase() ?? '';
          final type = item['type']?.toString().toLowerCase() ?? '';
          final codePiste = item['code_piste']?.toString().toLowerCase() ?? '';

          return nom.contains(query) || type.contains(query) || codePiste.contains(query);
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // BARRE DE RECHERCHE
        _buildSearchBar(),

        // LISTE DES DONNÉES FILTRÉES
        Expanded(
          child: _buildDataList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher par nom, type ou code piste...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        onChanged: (_) => _filterData(),
      ),
    );
  }

  Widget _buildDataList() {
    if (_filteredData.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty ? 'Aucune donnée ${_getFilterText()}' : 'Aucun résultat pour "${_searchController.text}"',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredData.length,
      itemBuilder: (context, index) {
        final item = _filteredData[index];
        return _buildListItem(item, context);
      },
    );
  }

  // ⭐⭐ CONSERVEZ TOUTES VOS MÉTHODES EXISTANTES CI-DESSOUS ⭐⭐
  // (_getFilterText, _buildListItem, _editItem, _confirmDelete,
  //  _showDetails, _formatDate) - ELLES RESTENT IDENTIQUES !

  String _getFilterText() {
    switch (widget.dataFilter) {
      case "unsynced":
        return "enregistrée localement";
      case "synced":
        return "synchronisée";
      case "saved":
        return "sauvegardée";
      default:
        return "";
    }
  }

  Widget _buildListItem(Map<String, dynamic> item, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          item['nom'] ?? 'Sans nom',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${item['id']}'),
            if (item['type'] != null) Text('Type: ${item['type']}'),
            if (item['date_creation'] != null) Text('Créé: ${_formatDate(item['date_creation'])}'),
            if (item['synced'] == 1) Text('Synchronisé: ${_formatDate(item['date_sync'])}', style: const TextStyle(color: Colors.green)),
          ],
        ),
        trailing: widget.dataFilter == "unsynced"
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => widget.onEdit(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(item['id'], context),
                  ),
                ],
              )
            : null,
        onTap: () => _showDetails(item, context),
      ),
    );
  }

  void _confirmDelete(int id, BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet élément ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showDetails(Map<String, dynamic> item, BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Détails'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: item.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${entry.key}: ${entry.value}'),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
