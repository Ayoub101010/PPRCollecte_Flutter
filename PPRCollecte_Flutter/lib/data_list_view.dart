import 'package:flutter/material.dart';

class DataListView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Aucune donnée ${_getFilterText()}',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return _buildListItem(item, context);
      },
    );
  }

  String _getFilterText() {
    switch (dataFilter) {
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
        trailing: dataFilter == "unsynced"
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => onEdit(item),
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
              onDelete(id);
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
